# Software Architecture & Design Specification - DockerMon

## 1. System Overview

**DockerMon** is a lightweight, cross-platform ready native Linux desktop GUI client for monitoring and managing Docker containers and images. Built using Flutter Desktop (GTK+ engine) and Dart, it provides real-time visibility into container states, container control actions (start, stop, restart, delete, inspect, exec console, interactive terminal), image management (list, pull, remove), and automated diagnostics.

---

## 2. Architectural Principles & Layers

DockerMon follows a **Clean Layered Architecture** with strict separation of concerns, reactivity, and strict security boundary enforcement:

```
┌────────────────────────────────────────────────────────┐
│                   UI Presentation Layer                │
│    (ContainersView, ImagesView, Dialogs, Cards)        │
└───────────────────────────┬────────────────────────────┘
                            │ (Listens to state changes)
┌───────────────────────────▼────────────────────────────┐
│                    State Management                    │
│             (DockerProvider / ChangeNotifier)          │
└───────────────────────────┬────────────────────────────┘
                            │ (Executes async commands)
┌───────────────────────────▼────────────────────────────┐
│                   Service & Domain Layer               │
│         (DockerService / Container & Image Models)     │
└───────────────────────────┬────────────────────────────┘
                            │ (Communicates via CLI/Socket)
┌───────────────────────────▼────────────────────────────┐
│                 OS & Docker Engine Layer               │
│       (/var/run/docker.sock / Unix IPC / docker CLI)   │
└────────────────────────────────────────────────────────┘
```

---

## 3. Component Specification

### 3.1 Domain Models
- `ContainerInfo`: Immutable representation of a Docker container instance.
- `ContainerProfile`: Re-usable launch parameter presets (ports, env vars, commands, keep-alive).
- `ImageInfo`: Data entity representing local Docker images (Repository, Tag, ID, Size, CreatedAt).

### 3.2 Service Layer (`DockerService`)
Abstracts communication with Docker:
1. `getContainers()` / `getImages()`
2. `startContainer(id)`, `stopContainer(id)`, `restartContainer(id)`, `removeContainer(id)`
3. `pullImage(name)`, `removeImage(id)`
4. `openContainerShell(id)` / `runInteractiveShell(image)` (External Terminal Launcher)
5. `execCommand(id, cmd)` (GUI Exec Console)

### 3.3 State Provider Layer (`DockerProvider`)
Maintains session state:
- `containers`: List of parsed `ContainerInfo`.
- `images`: List of parsed `ImageInfo`.
- `customProfiles`: Saved launch preset profiles.
- `autoRefreshEnabled`: 3-second polling loop.

---

## 4. Phase 2 Features Roadmap

1. **Images View & Manager**:
   - Tabbed navigation: **Containers Dashboard** | **Image Library**.
   - Table/Grid view displaying repository, tag, size, and ID.
2. **Docker Hub Image Puller**:
   - Modal dialog with progress logs for pulling new images (`docker pull <image:tag>`).
3. **Container & Image Lifecycle Cleanup**:
   - Single item delete buttons (🗑️) with confirmation modals.
   - One-click bulk prune for stopped containers (`docker container prune -f`).
