# FlashCard SP-KN

Aplicación móvil para el aprendizaje de vocabulario coreano mediante flashcards e inteligencia artificial.

![License](https://img.shields.io/badge/License-MIT-green.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.47.5-blue.svg)
![Python](https://img.shields.io/badge/Python-3.x-yellow.svg)
![Platform](https://img.shields.io/badge/Platform-Android-brightgreen.svg)


FlashCard SP-KN es un proyecto desarrollado con Flutter y Dart que permite crear, organizar y estudiar vocabulario coreano, incorporando herramientas de asistencia mediante Google Gemini para completar información lingüística.

El proyecto también incluye un backend basado en Python y Flask, un sistema de distribución de actualizaciones y un panel administrativo para Windows.

---

## Características principales

### 📚 Gestión de flashcards

- Crear, editar y eliminar tarjetas de vocabulario.
- Organizar tarjetas mediante grupos.
- Consultar y estudiar vocabulario coreano.
- Almacenar información localmente mediante SQLite.
- Importar y exportar información de las tarjetas.

### 🤖 Inteligencia artificial

Integración con Google Gemini para asistir en la creación de información lingüística.

La generación contempla seis campos:

- Traducción al español.
- Romanización.
- Ejemplo en coreano.
- Traducción del ejemplo al español.
- Contexto de uso.
- Nota o descripción adicional.

La aplicación incorpora dos formas de conexión:

1. **Backend propio:** utiliza un servidor Flask para procesar las solicitudes mediante Gemini.
2. **Gemini directo:** permite realizar consultas desde el teléfono cuando el servidor principal no está disponible.

La aplicación contempla una lista de modelos Flash-Lite para intentar continuar cuando un modelo no está disponible.

### 🔐 Seguridad

- Almacenamiento seguro de credenciales mediante `flutter_secure_storage`.
- Autenticación biométrica para proteger las operaciones relacionadas con la API Key de Gemini.
- Autenticación del backend mediante token Bearer.
- Separación entre las credenciales del servidor y las del cliente.

### 🔄 Actualizaciones

- Detección de nuevas versiones de la aplicación.
- Distribución de APK mediante un servidor propio.
- Infraestructura basada en Docker y Nginx.
- Conservación de los datos locales durante las actualizaciones.

### 💾 Respaldos

- Creación y administración de respaldos.
- Almacenamiento de respaldos en el servidor.
- Integración con la infraestructura Docker.

### 🖥️ Panel administrativo

Herramienta de escritorio para Windows que facilita:

- Administración del servidor Docker.
- Consulta del estado de los servicios.
- Gestión de la publicación de actualizaciones.
- Administración de la versión de la aplicación.

---

## Arquitectura del proyecto

El sistema está organizado en tres componentes principales:

```text
FlashCard-SP-KN/
│
├── flashcard_sp_kn/
│   └── Aplicación móvil Flutter
│
├── flashcard-update-server/
│   └── Backend Flask + Docker + Nginx
│
├── flashcard_panel_windows/
│   └── Panel administrativo Windows
│
├── docs/
│   └── Documentación adicional
│
├── .gitignore
├── LICENSE
└── README.md
```

### 1. Aplicación móvil

Desarrollada con Flutter y Dart. Gestiona las tarjetas, los grupos, el almacenamiento local, la integración con Gemini y la comunicación con el servidor.

### 2. Backend

Desarrollado con Python y Flask. Procesa solicitudes de inteligencia artificial y administra los respaldos. Docker Compose coordina los servicios y Nginx distribuye las actualizaciones.

### 3. Panel administrativo

Desarrollado con Python y Tkinter. Facilita la administración de los servicios y la publicación de nuevas versiones de la aplicación.

---

## Tecnologías utilizadas

| Tecnología | Uso |
|---|---|
| Flutter | Desarrollo de la aplicación móvil |
| Dart | Lenguaje principal de la aplicación |
| SQLite | Base de datos local |
| Provider | Administración del estado |
| Google Gemini | Asistencia mediante inteligencia artificial |
| Dio | Comunicación HTTP |
| Flutter Secure Storage | Almacenamiento seguro |
| Local Auth | Autenticación biométrica |
| Python | Backend y panel administrativo |
| Flask | API del servidor |
| Docker | Contenedorización |
| Docker Compose | Administración de servicios |
| Nginx | Distribución de actualizaciones |
| Tkinter | Interfaz del panel Windows |
| PyInstaller | Generación del ejecutable |

---

## Requisitos

### Aplicación móvil

- Flutter compatible con Dart SDK `3.13.4` o superior.
- Android Studio.
- Android SDK.
- Dispositivo Android o emulador compatible.

### Backend

- Python.
- Docker Desktop o Docker Engine.
- Docker Compose.
- API Key de Google AI Studio.

### Panel administrativo

- Windows.
- Python 3.10 o superior.
- Docker Desktop.
- PowerShell.
- Flutter y Android SDK configurados.

---

## Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/R0ronoaZ0ro/flashcard-sp-kn.git
cd flashcard-sp-kn
```

### 2. Preparar la aplicación Flutter

```bash
cd flashcard_sp_kn
flutter pub get
flutter analyze
```

Para ejecutar la aplicación en un dispositivo conectado:

```bash
flutter run
```

Para generar un APK de publicación:

```bash
flutter build apk --release
```

### 3. Configurar el backend

Desde la raíz del repositorio:

```bash
cd flashcard-update-server
```

Crear el archivo de configuración:

**Windows PowerShell**

```powershell
Copy-Item .env.example .env
```

**Linux / macOS**

```bash
cp .env.example .env
```

Editar `.env` y configurar las credenciales propias:

```dotenv
BACKUP_TOKEN=TU_TOKEN_PRIVADO
GEMINI_API_KEY=TU_API_KEY
```

No publicar este archivo.

Preparar el manifiesto de actualizaciones:

```bash
cp releases/manifest.example.json releases/manifest.json
```

Configurar la dirección HTTPS correspondiente a la instalación.

Iniciar los servicios:

```bash
docker compose up -d --build
```

Consultar el estado:

```bash
docker compose ps
```

### 4. Conectar la aplicación con el servidor

En la aplicación, acceder a:

**Menú → Conexión y seguridad**

Configurar la URL del backend y el token correspondiente a `BACKUP_TOKEN`.

La aplicación también puede utilizar Gemini directamente desde el teléfono si se configura su propia API Key, sin depender de que el servidor esté encendido.

### 5. Preparar el panel Windows

Desde la carpeta:

```powershell
cd flashcard_panel_windows
```

Ejecutar el script de compilación:

```powershell
.\build_exe.bat
```

El ejecutable se genera en:

```text
dist/FlashCardSPKNPanel.exe
```

Consultar el README de cada componente para obtener instrucciones específicas.

---

## Configuración de servicios externos

### Google Gemini

Se requiere una API Key obtenida desde Google AI Studio.

El proyecto permite utilizar Gemini desde el backend o directamente desde la aplicación móvil. Cada instalación debe configurar sus propias credenciales.

### Servidor de actualizaciones

Para distribuir APK fuera de una red local se necesita configurar una dirección accesible desde Internet mediante HTTPS.

La infraestructura de Docker y Nginx proporciona la distribución, pero el alojamiento y la publicación externa deben configurarse para cada instalación.

---

## Seguridad y privacidad

Antes de ejecutar el proyecto:

- Generar credenciales propias.
- No publicar archivos `.env`.
- No subir API Keys ni tokens.
- No compartir respaldos personales.
- No publicar APK ni manifiestos con direcciones privadas.
- Utilizar HTTPS para conexiones a través de Internet.

Las claves y configuraciones privadas no forman parte de este repositorio.

---

## Documentación

Cada componente contiene instrucciones específicas:

- [`flashcard_sp_kn/`](flashcard_sp_kn/README.md): aplicación Flutter.
- [`flashcard-update-server/`](flashcard-update-server/README.md): backend y servidor.
- [`flashcard_panel_windows/`](flashcard_panel_windows/README.md): panel administrativo.

---

## Estado del proyecto

Proyecto personal en desarrollo, con funcionalidades de gestión de vocabulario, almacenamiento local, asistencia mediante inteligencia artificial, respaldos y actualización de la aplicación.

---

## Licencia

Este proyecto se distribuye bajo la licencia **MIT**.

Puedes utilizarlo, copiarlo, modificarlo y distribuirlo respetando las condiciones establecidas en el archivo [`LICENSE`](LICENSE).

---

**Desarrollado por Johann Osses.**