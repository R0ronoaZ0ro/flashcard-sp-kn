from __future__ import annotations

import hashlib
import json
import os
import queue
import re
import subprocess
import sys
import threading
import time
import tkinter as tk
from tkinter import messagebox, ttk
from pathlib import Path

# RUTAS DE LOS PROYECTOS

# ==========================================
# RUTAS DEL REPOSITORIO
# ==========================================

PANEL_DIR = (
    Path(sys.executable).resolve().parent
    if getattr(sys, "frozen", False)
    else Path(__file__).resolve().parent
)

# Permite indicar una raíz personalizada mediante variable de entorno.
repo_override = os.environ.get("FLASHCARD_REPO_DIR")

if repo_override:
    REPO_ROOT = Path(repo_override).expanduser().resolve()
else:
    # Busca la carpeta raíz desde la ubicación del panel.
    REPO_ROOT = next(
        (
            parent
            for parent in (PANEL_DIR, *PANEL_DIR.parents)
            if (parent / "flashcard_sp_kn").is_dir()
            and (parent / "flashcard-update-server").is_dir()
        ),
        PANEL_DIR.parent
    )

PROJECT_DIR = Path(os.environ.get(
    "FLASHCARD_PROJECT_DIR",
    str(REPO_ROOT / "flashcard_sp_kn")
)).expanduser().resolve()

SERVER_DIR = Path(os.environ.get(
    "FLASHCARD_SERVER_DIR",
    str(REPO_ROOT / "flashcard-update-server")
)).expanduser().resolve()

RELEASES_DIR = SERVER_DIR / "releases"
MANIFEST_PATH = RELEASES_DIR / "manifest.json"
APK_PATH = RELEASES_DIR / "flashcard-sp-kn.apk"

PUBLISH_SCRIPT = Path(os.environ.get(
    "FLASHCARD_PUBLISH_SCRIPT",
    str(PROJECT_DIR / "publicar_actualizacion.ps1")
)).expanduser().resolve()

PUBSPEC_PATH = Path(os.environ.get(
    "FLASHCARD_PUBSPEC_PATH",
    str(PROJECT_DIR / "pubspec.yaml")
)).expanduser().resolve()


class FlashCardPanel(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("FlashCard SP-KN | Administrador local")
        self.geometry("1050x760")
        self.minsize(850, 620)
        self.configure(bg="#0b1020")
        self.events = queue.Queue()
        self.busy = False
        self.version_var = tk.StringVar(value="")
        self._setup_style()
        self._build_ui()
        self.refresh_status()
        self.after(250, self.process_events)
        self.after(3000, self.periodic_refresh)

    def _setup_style(self):
        style = ttk.Style(self)
        try:
            style.theme_use("clam")
        except tk.TclError:
            pass
        style.configure(".", font=("Segoe UI", 10))
        style.configure("TFrame", background="#0b1020")
        style.configure("Card.TFrame", background="#121a2c")
        style.configure("TLabel", background="#0b1020", foreground="#e8eef8")
        style.configure("Card.TLabel", background="#121a2c", foreground="#e8eef8")
        style.configure("Muted.TLabel", background="#121a2c", foreground="#9baac2")
        style.configure("Title.TLabel", font=("Segoe UI", 21, "bold"), foreground="#38bdf8", background="#0b1020")
        style.configure("TButton", padding=(10, 7))
        style.configure("Primary.TButton", background="#075985", foreground="white")
        style.configure("Danger.TButton", background="#7f1d1d", foreground="white")
        style.configure("TNotebook", background="#0b1020", borderwidth=0)
        style.configure("TNotebook.Tab", padding=(12, 8))

    def _build_ui(self):
        root = ttk.Frame(self, padding=18)
        root.pack(fill="both", expand=True)
        header = ttk.Frame(root)
        header.pack(fill="x", pady=(0, 14))
        ttk.Label(header, text="FlashCard SP-KN", style="Title.TLabel").pack(side="left")
        self.status_label = ttk.Label(header, text="Preparando...", foreground="#9baac2")
        self.status_label.pack(side="right", anchor="e")

        path_card = ttk.Frame(root, style="Card.TFrame", padding=12)
        path_card.pack(fill="x", pady=(0, 12))
        ttk.Label(path_card, text="Carpeta del servidor", style="Muted.TLabel").pack(anchor="w")
        ttk.Label(path_card, text=str(SERVER_DIR), style="Card.TLabel").pack(anchor="w", pady=(3, 0))
        ttk.Label(path_card, text=f"Script: {PUBLISH_SCRIPT}", style="Muted.TLabel").pack(anchor="w", pady=(3, 0))
        ttk.Label(path_card, text=f"Flutter: {PUBSPEC_PATH}", style="Muted.TLabel").pack(anchor="w", pady=(3, 0))

        version_card = ttk.Frame(root, style="Card.TFrame", padding=12)
        version_card.pack(fill="x", pady=(0, 12))
        ttk.Label(
            version_card,
            text="Version de la aplicacion (pubspec.yaml)",
            style="Card.TLabel",
            font=("Segoe UI", 11, "bold")
        ).pack(anchor="w")
        version_row = ttk.Frame(version_card, style="Card.TFrame")
        version_row.pack(fill="x", pady=(7, 0))
        self.version_entry = ttk.Entry(
            version_row,
            textvariable=self.version_var,
            width=22,
            font=("Consolas", 11)
        )
        self.version_entry.pack(side="left", padx=(0, 8))
        ttk.Button(
            version_row,
            text="Guardar version",
            command=self.save_pubspec_version
        ).pack(side="left", padx=(0, 8))
        ttk.Button(
            version_row,
            text="Recargar",
            command=self.load_pubspec_version
        ).pack(side="left")
        ttk.Label(
            version_card,
            text="Formato: X.Y.Z+NUMERO  |  Ejemplo: 1.0.2+9",
            style="Muted.TLabel"
        ).pack(anchor="w", pady=(5, 0))
        self.load_pubspec_version()

        actions = ttk.Frame(root, style="Card.TFrame", padding=12)
        actions.pack(fill="x", pady=(0, 12))
        ttk.Label(actions, text="Acciones", style="Card.TLabel", font=("Segoe UI", 12, "bold")).pack(anchor="w", pady=(0, 8))
        row = ttk.Frame(actions, style="Card.TFrame")
        row.pack(fill="x")
        self.start_btn = ttk.Button(row, text="▶ Iniciar Docker", command=lambda: self.docker_action("start"))
        self.start_btn.pack(side="left", padx=(0, 8))
        self.stop_btn = ttk.Button(row, text="■ Detener Docker", command=lambda: self.docker_action("stop"))
        self.stop_btn.pack(side="left", padx=(0, 8))
        ttk.Button(row, text="Ver registros Docker", command=lambda: self.docker_action("logs")).pack(side="left", padx=(0, 8))
        self.publish_btn = ttk.Button(row, text="🚀 Publicar APK (PowerShell)", style="Primary.TButton", command=self.publish)
        self.publish_btn.pack(side="left", padx=(0, 8))
        ttk.Button(row, text="↻ Actualizar", command=self.refresh_status).pack(side="left")

        cards = ttk.Frame(root)
        cards.pack(fill="x", pady=(0, 12))
        cards.columnconfigure(0, weight=1)
        cards.columnconfigure(1, weight=1)
        self.docker_card = self._info_card(cards, 0, "DOCKER COMPOSE", "Consultando...")
        self.apk_card = self._info_card(cards, 1, "APK PUBLICADO", "Consultando...")

        notebook = ttk.Notebook(root)
        notebook.pack(fill="both", expand=True)
        manifest_tab = ttk.Frame(notebook, padding=8)
        logs_tab = ttk.Frame(notebook, padding=8)
        docker_tab = ttk.Frame(notebook, padding=8)
        notebook.add(manifest_tab, text="Manifest JSON")
        notebook.add(logs_tab, text="Publicación")
        notebook.add(docker_tab, text="Registros Docker")
        self.manifest_text = self._text_area(manifest_tab)
        self.publish_text = self._text_area(logs_tab)
        self.docker_text = self._text_area(docker_tab)
        self._append(self.publish_text, "Listo. Al publicar, aquí aparecerá la salida del script en tiempo real.\n")
        self._append(self.docker_text, "Pulsa «Ver registros Docker» para consultar las últimas líneas.\n")

        footer = ttk.Label(root, text="Aplicación local: solo controla los archivos y servicios de este equipo.", foreground="#9baac2")
        footer.pack(anchor="w", pady=(10, 0))

    def load_pubspec_version(self):
        try:
            if not PUBSPEC_PATH.exists():
                self.version_var.set("")
                self.status_label.configure(text="No se encontro pubspec.yaml")
                return
            content = PUBSPEC_PATH.read_text(encoding="utf-8-sig")
            match = re.search(
                r"(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+\+[0-9]+)\s*$",
                content
            )
            if match:
                self.version_var.set(match.group(1))
            else:
                self.version_var.set("")
                messagebox.showwarning(
                    "Version no encontrada",
                    "No se encontro una linea version con el formato X.Y.Z+NUMERO."
                )
        except Exception as exc:
            messagebox.showerror("Error", f"No se pudo leer pubspec.yaml:\\n{exc}")

    def save_pubspec_version(self):
        value = self.version_var.get().strip()
        if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+", value):
            messagebox.showerror(
                "Formato incorrecto",
                "Usa el formato X.Y.Z+NUMERO. Ejemplo: 1.0.2+9"
            )
            return

        if not PUBSPEC_PATH.exists():
            messagebox.showerror("Archivo no encontrado", f"No existe:\\n{PUBSPEC_PATH}")
            return

        try:
            original = PUBSPEC_PATH.read_text(encoding="utf-8-sig")
            pattern = r"(?m)^version:\s*[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+\s*$"
            if not re.search(pattern, original):
                messagebox.showerror(
                    "No se pudo actualizar",
                    "No se encontro una linea version valida en pubspec.yaml."
                )
                return

            new_content, replacements = re.subn(
                pattern,
                f"version: {value}",
                original,
                count=1
            )
            if replacements != 1:
                raise RuntimeError("No se pudo reemplazar la version.")

            # Crear una copia de seguridad antes de modificar el archivo.
            backup_path = PUBSPEC_PATH.with_suffix(PUBSPEC_PATH.suffix + ".bak")
            if not backup_path.exists():
                backup_path.write_text(original, encoding="utf-8")

            PUBSPEC_PATH.write_text(new_content, encoding="utf-8")
            self.version_var.set(value)
            messagebox.showinfo(
                "Version guardada",
                f"Se actualizo pubspec.yaml:\\n\\nversion: {value}\\n\\n"
                f"Copia de seguridad: {backup_path.name}"
            )
        except Exception as exc:
            messagebox.showerror("Error", f"No se pudo guardar la version:\\n{exc}")

    def _hidden_subprocess_kwargs(self):
        """Evita que Windows muestre una consola por cada proceso secundario."""
        if os.name != "nt":
            return {}
        startupinfo = subprocess.STARTUPINFO()
        startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startupinfo.wShowWindow = subprocess.SW_HIDE
        return {
            "startupinfo": startupinfo,
            "creationflags": getattr(subprocess, "CREATE_NO_WINDOW", 0)
        }

    def _info_card(self, parent, col, title, value):
        frame = ttk.Frame(parent, style="Card.TFrame", padding=12)
        frame.grid(row=0, column=col, sticky="nsew", padx=(0, 6) if col == 0 else (6, 0))
        ttk.Label(frame, text=title, style="Muted.TLabel").pack(anchor="w")
        label = ttk.Label(frame, text=value, style="Card.TLabel", font=("Segoe UI", 16, "bold"))
        label.pack(anchor="w", pady=(5, 0))
        return label

    def _text_area(self, parent):
        frame = ttk.Frame(parent)
        frame.pack(fill="both", expand=True)
        txt = tk.Text(frame, wrap="word", bg="#080d18", fg="#d9e7fa", insertbackground="white",
                      selectbackground="#075985", relief="flat", font=("Consolas", 10), padx=10, pady=10)
        scrollbar = ttk.Scrollbar(frame, command=txt.yview)
        txt.configure(yscrollcommand=scrollbar.set)
        txt.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")
        return txt

    def _append(self, widget, text):
        widget.insert("end", text)
        widget.see("end")

    def _run(self, args, timeout=40):
        try:
            p = subprocess.run(args, cwd=str(SERVER_DIR), capture_output=True, text=True,
                               encoding="utf-8", errors="replace", timeout=timeout, shell=False,
                               **self._hidden_subprocess_kwargs())
            return {"ok": p.returncode == 0, "code": p.returncode, "out": p.stdout, "err": p.stderr}
        except Exception as e:
            return {"ok": False, "code": None, "out": "", "err": str(e)}

    def refresh_status(self):
        def worker():
            docker = self._run(["docker", "compose", "ps", "--format", "json"], 20)
            manifest = None
            try:
                if MANIFEST_PATH.exists():
                    raw = MANIFEST_PATH.read_text(encoding="utf-8-sig")
                    manifest = (raw, json.loads(raw))
                else:
                    manifest = (None, None)
            except Exception as e:
                manifest = (None, {"_error": str(e)})
            apk = APK_PATH.exists()
            size = f"{APK_PATH.stat().st_size / 1048576:.2f} MB" if apk else "No encontrado"
            self.events.put(("status", docker, manifest, apk, size))
        threading.Thread(target=worker, daemon=True).start()

    def periodic_refresh(self):
        if not self.busy:
            self.refresh_status()
        self.after(5000, self.periodic_refresh)

    def process_events(self):
        try:
            while True:
                item = self.events.get_nowait()
                kind = item[0]
                if kind == "status":
                    _, docker, manifest, apk, size = item
                    if docker["ok"]:
                        states = []
                        running = False
                        for line in docker["out"].splitlines():
                            try:
                                d = json.loads(line)
                                state = str(d.get("State", d.get("state", ""))).lower()
                                states.append(f'{d.get("Name", d.get("name", "contenedor"))}: {state}')
                                running |= state == "running"
                            except Exception:
                                pass
                        summary = "En ejecución" if running else ("Detenido" if not states else "Contenedor detenido")
                        self.docker_card.configure(text=summary + ("\n" + "\n".join(states) if states else ""))
                        self.status_label.configure(text="Estado actualizado")
                        self.start_btn.configure(state="disabled" if running else "normal")
                        self.stop_btn.configure(state="normal" if running else "disabled")
                    else:
                        self.docker_card.configure(text="No disponible\n" + (docker["err"] or docker["out"] or "Comprueba Docker Desktop."))
                        self.status_label.configure(text="Docker no disponible")
                    self.apk_card.configure(text=size + ("\n" + str(APK_PATH) if apk else "\n" + str(APK_PATH)))
                    if manifest and manifest[0] is not None:
                        raw, data = manifest
                        pretty = json.dumps(data, ensure_ascii=False, indent=2)
                        version = data.get("version", data.get("versionName", data.get("appVersion", "Versión detectada")))
                        build = data.get("buildNumber", data.get("build_number", data.get("build", data.get("versionCode"))))
                        self.status_label.configure(text=f"Manifest: {version}" + (f" (+{build})" if build is not None else ""))
                        self.manifest_text.delete("1.0", "end")
                        self.manifest_text.insert("1.0", pretty)
                    else:
                        self.manifest_text.delete("1.0", "end")
                        error = manifest[1].get("_error") if manifest and manifest[1] else None
                        self.manifest_text.insert("1.0", error or f"No se encontró: {MANIFEST_PATH}")
                elif kind == "output":
                    _, target, line = item
                    self._append(target, line + "\n")
                elif kind == "done":
                    _, target, code = item
                    self.busy = False
                    self.publish_btn.configure(state="normal")
                    self.start_btn.configure(state="normal")
                    self.stop_btn.configure(state="normal")
                    self.status_label.configure(text=f"Operación finalizada (código {code})")
                    if target == "publish":
                        messagebox.showinfo("Publicación finalizada", f"El script terminó con código {code}.\nRevisa la pestaña Publicación.")
                    self.refresh_status()
        except queue.Empty:
            pass
        self.after(200, self.process_events)

    def docker_action(self, action):
        if self.busy:
            messagebox.showwarning("Operación en curso", "Espera a que termine la operación actual.")
            return
        if action in ("start", "stop"):
            verb = "iniciar" if action == "start" else "detener"
            if not messagebox.askyesno("Confirmar", f"¿Quieres {verb} los servicios Docker Compose?"):
                return
        args = {
            "start": ["docker", "compose", "up", "-d"],
            "stop": ["docker", "compose", "down"],
            "logs": ["docker", "compose", "logs", "--tail=100", "--no-color"],
        }[action]
        target = "docker"
        widget = self.docker_text
        if action == "logs":
            widget.delete("1.0", "end")
        self.busy = True
        self.start_btn.configure(state="disabled")
        self.stop_btn.configure(state="disabled")
        threading.Thread(target=self._stream_command, args=(args, 120, target, widget), daemon=True).start()

    def _stream_command(self, args, timeout, target, widget):
        self.events.put(("output", widget, f"> {' '.join(args)}"))
        result = self._run(args, timeout)
        if result["out"]:
            for line in result["out"].splitlines():
                self.events.put(("output", widget, line))
        if result["err"]:
            for line in result["err"].splitlines():
                self.events.put(("output", widget, "ERROR: " + line))
        self.events.put(("done", target, result["code"] if result["code"] is not None else 1))

    def publish(self):
        if self.busy:
            messagebox.showwarning("Operación en curso", "Espera a que termine la operación actual.")
            return
        if not PUBLISH_SCRIPT.exists():
            messagebox.showerror("Script no encontrado", f"No existe este archivo:\n{PUBLISH_SCRIPT}")
            return
        if not messagebox.askyesno("Confirmar publicación",
            "Se ejecutará publicar_actualizacion.ps1. Puede compilar y reemplazar el APK y el manifest publicados.\n\n¿Continuar?"):
            return
        self.publish_text.delete("1.0", "end")
        self.busy = True
        self.publish_btn.configure(state="disabled")
        self.start_btn.configure(state="disabled")
        self.stop_btn.configure(state="disabled")
        args = ["powershell.exe", "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(PUBLISH_SCRIPT)]
        threading.Thread(target=self._stream_popen, args=(args,), daemon=True).start()

    def _stream_popen(self, args):
        code = 1
        self.events.put(("output", self.publish_text, f"> {' '.join(args)}"))
        try:
            child_env = os.environ.copy()
            child_env["FLASHCARD_SERVER_DIR"] = str(SERVER_DIR)
            process = subprocess.Popen(args, cwd=str(SERVER_DIR), stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace",
                shell=False, bufsize=1, env=child_env, **self._hidden_subprocess_kwargs())
            for line in process.stdout:
                self.events.put(("output", self.publish_text, line.rstrip()))
            code = process.wait()
        except Exception as e:
            self.events.put(("output", self.publish_text, "ERROR: " + str(e)))
        self.events.put(("done", "publish", code))


if __name__ == "__main__":
    if os.name != "nt":
        print("Esta aplicación está diseñada para Windows.")
    app = FlashCardPanel()
    app.mainloop()
