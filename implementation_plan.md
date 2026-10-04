# Implementation Plan - Phase 2: Image Management & Container Lifecycle Cleanup

DockerMon is expanding to include full **Image Management** (listing, pulling new images from Docker Hub, deleting images) and **Container Lifecycle Cleanup** (deleting stopped containers, force removal, and bulk pruning).

---

## Proposed Features & Roadmap for Phase 2

### 1. Image Management Dashboard Tab
- **Image Listing**: Display all local Docker images with Repository, Tag, Image ID, Size, and Creation Date (`docker images --format json`).
- **Pull New Image**: Dialog with live layer download logs to pull images from Docker Hub or private registries (`docker pull <image:tag>`).
- **Remove Image**: Trash action button to delete unused images (`docker rmi <image_id>`).
- **Quick Launch from Image**: 1-click launch button on any image card to open the **Launch Container** modal with that image pre-filled.

### 2. Container Deletion & Cleanup
- **Single Container Delete**: Add a **Remove Container (🗑️)** action button to container cards (active when stopped or with force prompt).
- **Confirmation Modal**: Prevent accidental deletion with container ID/name verification.
- **Bulk Cleanup / Prune**: One-click action to remove all stopped containers (`docker container prune -f`).

---

## Proposed Changes

### [MODIFY] `lib/models/image_info.dart` [NEW]
- Data model representing local Docker images: `id`, `repository`, `tag`, `size`, `created`.

### [MODIFY] `lib/services/docker_service.dart`
- Add `getImages()`: Query `docker images --format '{"ID":"{{.ID}}","Repository":"{{.Repository}}","Tag":"{{.Tag}}","Size":"{{.Size}}","CreatedAt":"{{.CreatedAt}}"}'`.
- Add `pullImage(String imageName)`: Live process execution for pulling images.
- Add `removeImage(String imageId, {bool force = false})`: Exec `docker rmi`.
- Add `removeContainer(String containerId, {bool force = false})`: Exec `docker rm`.
- Add `pruneContainers()`: Exec `docker container prune -f`.

### [MODIFY] `lib/providers/docker_provider.dart`
- State management for images list, pulling status, container deletion, and bulk prune.

### [NEW] `lib/widgets/images_tab_view.dart` & `lib/widgets/pull_image_dialog.dart`
- Dedicated Navigation Bar / Tabs (Containers View vs. Images View).
- Image cards with Quick Launch, Delete, and Pull Image modals.

---

## Verification Plan

1. **Static Analysis**: `flutter analyze` ensuring zero warnings/errors.
2. **Compilation**: Compile Linux desktop application bundle `flutter build linux`.
3. **Functional Verification**:
   - Pull a test image (e.g., `busybox:latest`).
   - Verify image appears in Images Tab list.
   - Launch container from image, stop container, and test deleting container (`docker rm`).
   - Verify image deletion (`docker rmi`).
