# DockerMon 🐳

A modern, native Linux desktop application built with Flutter & Dart for monitoring, running, controlling, and managing Docker containers and local images with a sleek dark glassmorphism interface.

---

## 🌟 Key Features

### 📦 1. Container Management & Diagnostics
- **Real-Time Monitoring**: Live 3-second polling sync with the local Docker daemon.
- **Full Lifecycle Control**: Start, Stop, Restart, and Force Remove (`docker rm -f`) containers.
- **Bulk Cleanup**: One-click **"Prune Stopped"** action button to clean up all inactive containers (`docker container prune -f`).
- **Live Search & Filters**: Search containers across names, image tags, IDs, or states (`All`, `Running`, `Stopped`, `Paused`).
- **Container Logs & Inspect**: Built-in modal dialog to view recent stdout/stderr logs and raw JSON metadata (`docker inspect`).

### 💻 2. Interactive Terminal Shell & In-App Exec Console
- **External Terminal Shell Window**: Open a native Linux terminal window connected to any running container (`docker exec -it <id> sh` / `bash`) with automatic terminal emulator detection (`x-terminal-emulator`, `gnome-terminal`, `xterm`, `konsole`, etc.).
- **Interactive Run Window**: Launch containers directly in interactive mode (`docker run -it --rm <image> sh`).
- **In-App Exec Console**: Execute non-interactive commands within a container directly from the GUI and stream command output in real time.

### 🖼️ 3. Image Library & Docker Hub Pulling
- **Image Library View**: Dedicated tab listing all local Docker images with repository tags, sizes, creation age, short IDs, and dangling status alerts.
- **Pull Image Dialog**: Download images from Docker Hub or private registries with quick popular preset chips (`alpine:latest`, `ubuntu:latest`, `nginx:alpine`, `redis:alpine`, `postgres:latest`, `python:3.11-slim`, `node:20-alpine`).
- **Quick Launch from Image**: 1-click **Run** action on any image card to open the launch dialog with that image pre-filled.
- **Image Removal & Pruning**: Safe deletion with optional force flag (`docker rmi [-f]`) and dangling image pruning.

### 🚀 4. Launch Container Profiles & Keep-Alive Daemon
- **Built-in Presets**: Pre-configured launch profiles for common workloads (*Alpine Keep-Alive*, *Ubuntu Keep-Alive*, *Nginx Web Server*, *Redis Cache*).
- **Keep-Alive Daemon Switch**: Prevents base OS containers (like `alpine` or `ubuntu`) from exiting immediately by keeping them active in the background.
- **Custom Presets**: Customize port mappings (`-p`), environment variables (`-e`), commands, and restart policies, and save custom profiles for instant re-launch.

---

## 🧪 Automated System Acceptance Testing

DockerMon includes an automated test harness validating end-to-end functionality against the live Docker engine:

```bash
./test/run_acceptance_tests.sh
```

### Acceptance Criteria Covered

| Test ID | Acceptance Criteria | Description |
|---|---|---|
| **AC-01** | **Docker Engine Connectivity** | Verifies socket `/var/run/docker.sock` communication without requiring root password. |
| **AC-02** | **Container Lifecycle** | Validates state transitions (`create` ➔ `running` ➔ `exited` ➔ `running`). |
| **AC-03** | **Interactive Terminal Contract** | Auto-detects Linux terminal emulator and validates subshell wrapper syntax. |
| **AC-04** | **In-App Exec Console** | Validates command execution (`docker exec`) and exact stdout string capture. |
| **AC-05** | **Logs & JSON Inspect** | Validates log streaming and JSON container metadata schema. |
| **AC-06** | **Container Deletion & Pruning** | Validates force container removal (`docker rm -f`) and bulk stopped container pruning. |
| **AC-07** | **Image Listing & JSON Parsing** | Validates local image listing and model schema compatibility. |
| **AC-08** | **Image Pulling & Removal** | Tests downloading images from Docker Hub and local removal (`docker rmi`). |

---

## 🛠️ Build & Run Instructions

### Prerequisites
- **Linux** (Ubuntu 20.04+, Debian 11+, Fedora, or equivalent desktop distro).
- **Docker Engine** installed and configured for non-root execution:
  ```bash
  sudo usermod -aG docker $USER
  ```
  *(Log out and back in for group changes to take effect)*
- **Flutter SDK** (v3.11+) with Linux desktop enabled.

### Run in Development Mode
```bash
flutter run -d linux
```

### Build Release Binary
On systems requiring explicit GCC/Clang C++ library paths:
```bash
LIBRARY_PATH=/usr/lib/gcc/x86_64-linux-gnu/11 CPLUS_INCLUDE_PATH=/usr/include/c++/11:/usr/include/x86_64-linux-gnu/c++/11 flutter build linux
```

The compiled standalone executable bundle will be located at:
```bash
./build/linux/x64/release/bundle/dockermon
```

---

## 🔒 Security Architecture
- DockerMon interacts with the Docker engine exclusively through the standard UNIX socket (`/var/run/docker.sock`) and standard Docker CLI tools.
- **No plaintext passwords or root credentials** are stored or written to disk. Permission access relies solely on standard Linux Docker group authorization.

---

## 📄 License
MIT License.
