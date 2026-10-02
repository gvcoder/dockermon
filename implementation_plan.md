# Implementation Plan - Container Launch & Parameter Profiling System

DockerMon is expanding to include a **Container Launch & Parameter Profiling System**. This enables users to spin up new containers, configure launch parameters (Ports, Env Vars, Override Commands, Keep-Alive flags), and save re-usable Launch Profiles (such as Alpine Keep-Alive, Web Server, Database Presets).

---

## User Review Required

> [!IMPORTANT]
> - **Keep-Alive Strategy for Base Images**: Base images like `alpine` or `ubuntu` exit immediately when started without a TTY/interactive shell. The new launcher includes a **Keep-Alive Toggle** that automatically appends `tail -f /dev/null` or `sh -c "while true; do sleep 3600; done"` to keep shell base images running continuously.
> - **Built-in Presets**: Included out of the box are 4 built-in profiles (*Alpine Keep-Alive*, *Ubuntu Keep-Alive*, *Nginx Web Server*, *Redis Cache*), plus full support for custom user profiles.

---

## Proposed Changes

### [NEW] `lib/models/container_profile.dart`
- Data model representing launch configurations: `id`, `name`, `image`, `command`, `ports`, `envVars`, `restartPolicy`, `isKeepAliveEnabled`, `isBuiltIn`.
- Factory presets for Alpine, Ubuntu, Nginx, Redis.

### [MODIFY] `lib/services/docker_service.dart`
- Add `runContainer({required ContainerProfile profile})` executing:
  `docker run -d [--name ...] [-p ...] [-e ...] [--restart ...] <image> <command>`

### [MODIFY] `lib/providers/docker_provider.dart`
- Manage built-in and custom launch profiles.
- Add `launchContainer(ContainerProfile profile)` state action.

### [NEW] `lib/widgets/launch_container_dialog.dart`
- Modal dialog featuring:
  - Preset Profile Selector Dropdown.
  - Form fields for Container Name, Image, Override Command, Port Mappings, Env Vars.
  - Keep-Alive Toggle switch for shell base images.
  - "Save as Custom Profile" button.
  - "Launch Container" execution button.

### [MODIFY] `lib/widgets/status_header.dart`
- Add prominent **"Launch Container" (+)** button to header bar.

---

## Verification Plan

1. **Static Analysis**: `flutter analyze` ensuring zero warnings/errors.
2. **Automated Unit Tests**: Update test suite to verify `ContainerProfile` and `runContainer` parameter formatting.
3. **Executable Compilation**: Recompile Linux desktop application bundle `flutter build linux`.
4. **Manual & System Verification**:
   - Launch application `./build/linux/x64/release/bundle/dockermon`.
   - Test launching an `alpine` container with "Keep-Alive" enabled and verify it stays in `Running (Up)` state without exiting.
   - Test launching `nginx` with port mapping `8080:80`.
