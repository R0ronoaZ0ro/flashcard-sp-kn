# FlashCard SP-KN — Panel Windows

Panel administrativo de escritorio desarrollado en Python con Tkinter para facilitar la administración del servidor y la publicación de actualizaciones de FlashCard SP-KN.

## Funcionalidades

- Consultar el estado del servidor Docker.
- Iniciar y detener los servicios.
- Consultar el manifiesto de actualizaciones.
- Verificar la presencia del APK publicado.
- Ejecutar el script de publicación.
- Administrar la versión de la aplicación desde `pubspec.yaml`.

## Tecnologías

- Python 3
- Tkinter
- Docker Compose
- PowerShell
- Flutter
- PyInstaller

## Requisitos

- Windows 10 o superior.
- Python 3.10 o superior.
- Docker Desktop.
- PowerShell.
- Flutter y Dart disponibles en PATH.
- Android SDK configurado para compilar APK.

## Instalación desde el código fuente

Desde la carpeta:

```powershell
cd flashcard_panel_windows
```

Ejecuta:

```powershell
.\build_exe.bat
```

El ejecutable se genera en:

```text
dist/FlashCardSPKNPanel.exe
```

## Organización del proyecto

El panel está diseñado para trabajar con las siguientes carpetas:

```text
FlashCard-SP-KN/
├── flashcard_sp_kn/
├── flashcard-update-server/
└── flashcard_panel_windows/
```

Las rutas se detectan desde la estructura del repositorio. También pueden personalizarse mediante variables de entorno:

| Variable | Función |
|---|---|
| `FLASHCARD_REPO_DIR` | Raíz del repositorio |
| `FLASHCARD_PROJECT_DIR` | Proyecto Flutter |
| `FLASHCARD_SERVER_DIR` | Servidor Docker |
| `FLASHCARD_PUBLISH_SCRIPT` | Script PowerShell de publicación |
| `FLASHCARD_PUBSPEC_PATH` | Archivo `pubspec.yaml` |

## Seguridad

El panel no debe contener credenciales de Gemini ni tokens de acceso.

No publiques:
- Archivos `.env`.
- Respaldos JSON.
- APK compilados.
- Manifiestos con URLs privadas.
- Archivos generados por PyInstaller.

## Licencia

Este componente forma parte de FlashCard SP-KN y se distribuye bajo la licencia MIT. Consulta el archivo `LICENSE` de la raíz del repositorio.