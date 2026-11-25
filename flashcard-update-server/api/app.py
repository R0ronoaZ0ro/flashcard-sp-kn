
import json
import os
import uuid
import hmac
import urllib.parse
import urllib.request
import urllib.error
from datetime import datetime, timezone
from pathlib import Path
from functools import wraps

from flask import Flask, jsonify, request, send_file


app = Flask(__name__)

# ---------------------------------------------------------
# CONFIGURACIÓN
# ---------------------------------------------------------

BACKUP_DIR = Path(
    os.environ.get("BACKUP_DIR", "/app/backups")
)

BACKUP_DIR.mkdir(parents=True, exist_ok=True)

BACKUP_TOKEN = os.environ.get("BACKUP_TOKEN", "")
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
GEMINI_MODELS = (
    "gemini-3.5-flash-lite",
    "gemini-3.1-flash-lite",
    "gemini-2.5-flash-lite",
)

MAX_BACKUPS = 10

app.config["MAX_CONTENT_LENGTH"] = 50 * 1024 * 1024


# ---------------------------------------------------------
# AUTENTICACIÓN
# ---------------------------------------------------------

def require_token(func):
    @wraps(func)
    def wrapper(*args, **kwargs):

        if len(BACKUP_TOKEN) < 32:
            return jsonify({
                "error": "El servidor debe configurar BACKUP_TOKEN con al menos 32 caracteres."
            }), 500

        authorization = request.headers.get("Authorization", "")

        supplied = authorization[7:] if authorization.startswith("Bearer ") else ""
        if not supplied or not hmac.compare_digest(supplied, BACKUP_TOKEN):
            return jsonify({
                "error": "Token no válido o ausente"
            }), 401

        return func(*args, **kwargs)

    return wrapper


# ---------------------------------------------------------
# UTILIDADES
# ---------------------------------------------------------

def get_backup_path(backup_id):
    """
    Solo permite identificadores UUID.
    Evita que una petición pueda acceder a otros archivos.
    """

    try:
        normalized_id = str(uuid.UUID(backup_id))
    except (ValueError, TypeError, AttributeError):
        return None

    return BACKUP_DIR / f"{normalized_id}.json"



def get_backup_metadata(path):
    with open(path, "r", encoding="utf-8") as file:
        backup = json.load(file)

    data = backup.get("data", {})
    groups = data.get("groups", [])

    if not isinstance(groups, list):
        groups = []

    flashcard_count = sum(
        len(group.get("flashcards", []))
        for group in groups
        if isinstance(group, dict)
        and isinstance(group.get("flashcards", []), list)
    )

    return {
        "id": backup.get("id"),
        "created_at": backup.get("created_at"),
        "group_count": len(groups),
        "flashcard_count": flashcard_count
    }



def prune_backups():
    """
    Conserva las 10 copias más recientes.
    """

    backups = sorted(
        BACKUP_DIR.glob("*.json"),
        key=lambda path: path.stat().st_mtime,
        reverse=True
    )

    for old_backup in backups[MAX_BACKUPS:]:
        old_backup.unlink(missing_ok=True)



def build_gemini_prompt(korean_text):
    # JSON quoting keeps the supplied text clearly delimited inside the prompt.
    quoted_text = json.dumps(korean_text, ensure_ascii=False)
    return f"""Eres un profesor de coreano para estudiantes hispanohablantes.
Analiza esta palabra o expresión coreana: {quoted_text}

Completa TODOS los campos del JSON.

REGLAS OBLIGATORIAS:
- translation: traducción breve y natural al español. Máximo dos equivalencias. No incluyas explicaciones aquí.
- romanization: romanización revisada del texto original.
- example.korean: una oración corta, natural y correcta que utilice la expresión estudiada.
- example.spanish: traducción natural de esa oración.
- context: máximo 2 frases. Indica el nivel de formalidad y con quién o cuándo se utiliza.
- note: máximo 2 frases con información lingüística útil, como gramática, omisión de sujeto/objeto o algún matiz importante. No repitas el contexto.
- Evita datos históricos, curiosidades, relleno y referencias a K-pop o medios de comunicación, salvo que sean relevantes para comprender el significado.
- No inventes significados ni fuerces explicaciones culturales.
- No coloques información de un campo dentro de otro.
- Todos los campos deben contener texto breve y útil.
- Devuelve únicamente el JSON definido por el esquema.
"""


def request_gemini(model_name, prompt):
    schema = {
        "type": "OBJECT",
        "required": ["translation", "romanization", "example", "context", "note"],
        "properties": {
            "translation": {"type": "STRING", "description": "Equivalencia breve en español. Máximo dos opciones."},
            "romanization": {"type": "STRING", "description": "Romanización revisada del texto coreano original."},
            "example": {
                "type": "OBJECT",
                "required": ["korean", "spanish"],
                "properties": {
                    "korean": {"type": "STRING", "description": "Oración breve en coreano."},
                    "spanish": {"type": "STRING", "description": "Traducción natural de esa oración."},
                },
            },
            "context": {"type": "STRING", "description": "Una o dos frases sobre formalidad y situación de uso."},
            "note": {"type": "STRING", "description": "Nota lingüística breve y útil para aprender."},
        },
    }
    query = urllib.parse.urlencode({"key": GEMINI_API_KEY})
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent?{query}"
    body = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "responseMimeType": "application/json",
            "responseSchema": schema,
            "temperature": 0.2,
        },
    }
    request = urllib.request.Request(
        url,
        data=json.dumps(body, ensure_ascii=False).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=45) as response:
            result = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        # Do not return upstream bodies: they may contain operational details.
        raise RuntimeError(f"Gemini HTTP {error.code}") from None
    except (urllib.error.URLError, TimeoutError):
        raise RuntimeError("Gemini no está disponible temporalmente") from None

    candidates = result.get("candidates") or []
    if not candidates:
        raise RuntimeError("Gemini no devolvió candidatos")
    parts = candidates[0].get("content", {}).get("parts", [])
    response_text = "".join(part.get("text", "") for part in parts if isinstance(part, dict))
    if not response_text.strip():
        raise RuntimeError("Gemini devolvió una respuesta vacía")
    try:
        data = json.loads(response_text)
    except json.JSONDecodeError:
        raise RuntimeError("Gemini devolvió un JSON no válido") from None

    if not isinstance(data, dict) or not isinstance(data.get("example"), dict):
        raise RuntimeError("La estructura devuelta por Gemini no es válida")
    required_text = ("translation", "romanization", "context", "note")
    if any(not isinstance(data.get(key), str) or not data[key].strip() for key in required_text):
        raise RuntimeError("Gemini no completó todos los campos requeridos")
    example = data["example"]
    if any(not isinstance(example.get(key), str) or not example[key].strip() for key in ("korean", "spanish")):
        raise RuntimeError("Gemini no completó los ejemplos requeridos")
    return data


# ---------------------------------------------------------
# RUTAS
# ---------------------------------------------------------

@app.get("/api/health")
def health():
    return jsonify({
        "status": "ok",
        "service": "flashcard-backup-api"
    })


@app.get("/api/auth/check")
@require_token
def auth_check():
    return jsonify({"status": "ok", "authenticated": True})


@app.post("/api/ai/complete")
@require_token
def complete_with_ai():
    if not GEMINI_API_KEY:
        return jsonify({"error": "El servidor no tiene configurada la clave de Gemini."}), 503
    if request.content_length is not None and request.content_length > 16 * 1024:
        return jsonify({"error": "La solicitud supera el tamaño permitido."}), 413
    if not request.is_json:
        return jsonify({"error": "Se esperaba un cuerpo JSON."}), 400
    payload = request.get_json(silent=True)
    if not isinstance(payload, dict):
        return jsonify({"error": "La solicitud debe ser un objeto JSON."}), 400
    korean_text = payload.get("text")
    if not isinstance(korean_text, str) or not korean_text.strip():
        return jsonify({"error": "Debes enviar un texto coreano válido."}), 400
    korean_text = korean_text.strip()
    if len(korean_text) > 300:
        return jsonify({"error": "El texto no puede superar los 300 caracteres."}), 400

    prompt = build_gemini_prompt(korean_text)
    last_error = None
    for model_name in GEMINI_MODELS:
        try:
            return jsonify(request_gemini(model_name, prompt)), 200
        except RuntimeError as error:
            last_error = str(error)
            # Match the former client behavior: try the next model for transient,
            # availability, and response-format failures; stop on auth failures.
            if "HTTP 401" in last_error or "HTTP 403" in last_error or "API key" in last_error:
                break

    app.logger.warning("Gemini completion failed: %s", last_error or "unknown error")
    if last_error and "HTTP 429" in last_error:
        return jsonify({"error": "Se alcanzó el límite de solicitudes de Gemini. Inténtalo más tarde."}), 429
    return jsonify({"error": "No fue posible completar la flashcard con Gemini. Inténtalo nuevamente."}), 502


@app.post("/api/backups")
@require_token
def create_backup():

    if not request.is_json:
        return jsonify({
            "error": "Se esperaba un cuerpo JSON"
        }), 400

    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        return jsonify({
            "error": "El respaldo debe ser un objeto JSON"
        }), 400

    if not isinstance(data.get("groups", []), list):
        return jsonify({
            "error": "groups debe ser una lista"
        }), 400

    if not isinstance(data.get("flashcards", []), list):
        return jsonify({
            "error": "flashcards debe ser una lista"
        }), 400

    backup_id = str(uuid.uuid4())

    created_at = datetime.now(timezone.utc).isoformat()

    backup = {
        "id": backup_id,
        "created_at": created_at,
        "data": data
    }

    backup_path = BACKUP_DIR / f"{backup_id}.json"

    temporary_path = BACKUP_DIR / f"{backup_id}.tmp"

    try:
        with temporary_path.open("w", encoding="utf-8") as file:
            json.dump(
                backup,
                file,
                ensure_ascii=False,
                indent=2
            )

        temporary_path.replace(backup_path)

        prune_backups()

        metadata = get_backup_metadata(backup_path)

        return jsonify({
            "message": "Respaldo creado correctamente",
            "backup": metadata
        }), 201

    except OSError:
        temporary_path.unlink(missing_ok=True)

        return jsonify({
            "error": "No se pudo guardar el respaldo"
        }), 500


@app.get("/api/backups")
@require_token
def list_backups():

    backups = sorted(
        BACKUP_DIR.glob("*.json"),
        key=lambda path: path.stat().st_mtime,
        reverse=True
    )

    result = []

    for path in backups:
        metadata = get_backup_metadata(path)

        if metadata:
            result.append(metadata)

    return jsonify({
        "backups": result,
        "count": len(result)
    })


@app.get("/api/backups/<backup_id>")
@require_token
def download_backup(backup_id):

    backup_path = get_backup_path(backup_id)

    if backup_path is None:
        return jsonify({
            "error": "Identificador de respaldo no válido"
        }), 400

    if not backup_path.is_file():
        return jsonify({
            "error": "El respaldo no existe"
        }), 404

    return send_file(
        backup_path,
        mimetype="application/json",
        as_attachment=True,
        download_name=f"flashcard-backup-{backup_id}.json"
    )


@app.delete("/api/backups/<backup_id>")
@require_token
def delete_backup(backup_id):

    backup_path = get_backup_path(backup_id)

    if backup_path is None:
        return jsonify({
            "error": "Identificador de respaldo no válido"
        }), 400

    if not backup_path.is_file():
        return jsonify({
            "error": "El respaldo no existe"
        }), 404

    backup_path.unlink()

    return jsonify({
        "message": "Respaldo eliminado correctamente",
        "id": backup_id
    })


# ---------------------------------------------------------
# INICIO
# ---------------------------------------------------------

if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=False
    )
