# FlashCard SP-KN — Backend

Backend desarrollado en Python y Flask que conecta la aplicación móvil FlashCard SP-KN con los servicios de inteligencia artificial y administración de respaldos.

## Características

- Completar información lingüística de flashcards mediante Gemini.
- Autenticación mediante token Bearer.
- Crear, consultar, descargar y eliminar respaldos.
- Integración con Docker Compose.
- Servidor Nginx para distribuir actualizaciones de la aplicación.
- Almacenamiento persistente de respaldos.

## Tecnologías

- Python
- Flask
- Google Gemini API
- Docker
- Docker Compose
- Nginx

## Requisitos

- Windows, Linux o macOS.
- Docker Desktop o Docker Engine.
- Docker Compose.
- Una API Key de Google AI Studio.

## Instalación

### 1. Obtener el código

Desde la raíz del repositorio:

```bash
cd flashcard-update-server
```

### 2. Configurar variables de entorno

Copia el archivo de ejemplo:

En PowerShell:

```powershell
Copy-Item .env.example .env
```

En Linux o macOS:

```bash
cp .env.example .env
```

Edita `.env` y configura:

- `BACKUP_TOKEN`: token privado y aleatorio de al menos 32 caracteres.
- `GEMINI_API_KEY`: clave de Google AI Studio.

No compartas ni publiques este archivo.

### 3. Configurar el manifiesto de actualizaciones

Copia el manifiesto de ejemplo:

```bash
cp releases/manifest.example.json releases/manifest.json
```

Configura la URL HTTPS donde estará disponible el APK.

El servidor necesita un manifiesto válido para distribuir actualizaciones.

### 4. Iniciar los servicios

```bash
docker compose up -d --build
```

Comprobar el estado:

```bash
docker compose ps
```

Consultar los registros:

```bash
docker compose logs -f
```

Detener los servicios:

```bash
docker compose down
```

## Integración con Flutter

En FlashCard SP-KN, abre:

**Menú → Conexión y seguridad**

Configura:

- URL base del servidor.
- Token de acceso correspondiente a `BACKUP_TOKEN`.

Guarda la configuración y prueba la conexión.

## Endpoints

| Método | Endpoint | Descripción |
|---|---|---|
| GET | `/api/health` | Estado del servicio |
| GET | `/api/auth/check` | Verificación del token |
| POST | `/api/ai/complete` | Completar información lingüística |
| Varios | `/api/backups` | Administración de respaldos |

Los endpoints protegidos requieren:

```http
Authorization: Bearer TU_BACKUP_TOKEN
```

## Seguridad

- No publiques `.env`.
- No compartas respaldos personales.
- No publiques manifiestos con direcciones privadas.
- Utiliza HTTPS cuando el servidor sea accesible desde Internet.
- No reutilices el token de acceso en otros servicios.
- La API Key de Gemini debe permanecer exclusivamente en el servidor.

Este backend está diseñado como infraestructura personal o para instalaciones controladas. No constituye por sí solo una plataforma multiusuario.

## Estructura

```text
flashcard-update-server/
├── api/
├── nginx/
├── backups/
├── releases/
│   └── manifest.example.json
├── .env.example
├── .gitignore
└── compose.yaml
```

## Licencia

Este componente forma parte de FlashCard SP-KN y se distribuye bajo la licencia MIT. Consulta el archivo `LICENSE` de la raíz del repositorio.