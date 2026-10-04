import 'dart:convert';
import 'dart:io';
import 'package:process_run/shell.dart';
import '../models/container_info.dart';
import '../models/container_profile.dart';

enum DockerHealthState {
  ok,
  permissionDenied,
  daemonNotRunning,
  dockerNotInstalled,
}

class DockerHealthResult {
  final DockerHealthState state;
  final String message;

  DockerHealthResult(this.state, this.message);
}

class DockerService {
  final Shell _shell = Shell(verbose: false);

  /// Check if Docker is installed, daemon is running, and user has socket permissions.
  Future<DockerHealthResult> checkHealth() async {
    // Check if docker executable exists
    try {
      final whichResult = await _shell.run('which docker');
      if (whichResult.isEmpty || whichResult.first.exitCode != 0) {
        return DockerHealthResult(
          DockerHealthState.dockerNotInstalled,
          'Docker executable not found on system PATH.',
        );
      }
    } catch (_) {
      return DockerHealthResult(
        DockerHealthState.dockerNotInstalled,
        'Docker command check failed.',
      );
    }

    // Try executing docker ps to verify daemon connection and permissions
    try {
      final result = await _shell.run('docker ps -n 1 --format "{{.ID}}"');
      if (result.isNotEmpty && result.first.exitCode == 0) {
        return DockerHealthResult(DockerHealthState.ok, 'Connected to Docker daemon.');
      }
    } on ShellException catch (e) {
      final err = e.result?.stderr.toString().toLowerCase() ?? e.message.toLowerCase();
      if (err.contains('permission denied') || err.contains('docker.sock')) {
        return DockerHealthResult(
          DockerHealthState.permissionDenied,
          'Permission denied connecting to /var/run/docker.sock.',
        );
      } else if (err.contains('is the docker daemon running') || err.contains('cannot connect')) {
        return DockerHealthResult(
          DockerHealthState.daemonNotRunning,
          'Docker daemon service is not running.',
        );
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('permission denied')) {
        return DockerHealthResult(
          DockerHealthState.permissionDenied,
          'Permission denied connecting to Docker socket.',
        );
      }
    }

    // Direct check on socket file permission if present
    final socketFile = File('/var/run/docker.sock');
    if (socketFile.existsSync()) {
      try {
        final canRead = await socketFile.exists();
        if (!canRead) {
          return DockerHealthResult(
            DockerHealthState.permissionDenied,
            'Socket file /var/run/docker.sock exists but is not readable.',
          );
        }
      } catch (_) {}
    }

    return DockerHealthResult(DockerHealthState.ok, 'Docker service is ready.');
  }

  /// List all containers (running and stopped)
  Future<List<ContainerInfo>> getContainers() async {
    const formatString = '{"ID":"{{.ID}}","Names":"{{.Names}}","Image":"{{.Image}}","State":"{{.State}}","Status":"{{.Status}}","CreatedAt":"{{.CreatedAt}}","Ports":"{{.Ports}}"}';
    try {
      final results = await _shell.run('docker ps -a --format \'$formatString\'');
      if (results.isEmpty) return [];

      final output = results.first.stdout.toString().trim();
      if (output.isEmpty) return [];

      final List<ContainerInfo> containers = [];
      final lines = LineSplitter.split(output);
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final jsonMap = jsonDecode(line.trim()) as Map<String, dynamic>;
          containers.add(ContainerInfo.fromDockerJson(jsonMap));
        } catch (_) {
          // If parsing fails for a single line, continue parsing remaining
        }
      }
      return containers;
    } catch (e) {
      rethrow;
    }
  }

  /// Start a container by ID or Name
  Future<void> startContainer(String id) async {
    final results = await _shell.run('docker start $id');
    if (results.isEmpty || results.first.exitCode != 0) {
      final stderr = results.first.stderr.toString();
      throw Exception(stderr.isNotEmpty ? stderr : 'Failed to start container $id');
    }
  }

  /// Stop a container by ID or Name
  Future<void> stopContainer(String id) async {
    final results = await _shell.run('docker stop $id');
    if (results.isEmpty || results.first.exitCode != 0) {
      final stderr = results.first.stderr.toString();
      throw Exception(stderr.isNotEmpty ? stderr : 'Failed to stop container $id');
    }
  }

  /// Restart a container by ID or Name
  Future<void> restartContainer(String id) async {
    final results = await _shell.run('docker restart $id');
    if (results.isEmpty || results.first.exitCode != 0) {
      final stderr = results.first.stderr.toString();
      throw Exception(stderr.isNotEmpty ? stderr : 'Failed to restart container $id');
    }
  }

  /// Fetch recent container logs
  Future<String> getLogs(String id, {int lines = 300}) async {
    try {
      final results = await _shell.run('docker logs --tail $lines $id');
      if (results.isEmpty) return 'No logs available.';      final stdout = results.first.stdout.toString();
      final stderr = results.first.stderr.toString();
      final combined = '$stdout\n$stderr'.trim();
      return combined.isEmpty ? 'No logs emitted yet.' : combined;
    } catch (e) {
      return 'Error fetching logs: $e';
    }
  }

  /// Inspect container metadata
  Future<String> inspectContainer(String id) async {
    try {
      final results = await _shell.run('docker inspect $id');
      if (results.isEmpty) return '{}';
      return results.first.stdout.toString();
    } catch (e) {
      return 'Error inspecting container: $e';
    }
  }

  /// Launch a new container using profile settings
  Future<void> runContainer(ContainerProfile profile, {String? customName}) async {
    final List<String> args = ['run', '-d'];

    if (customName != null && customName.trim().isNotEmpty) {
      args.addAll(['--name', customName.trim()]);
    }

    if (profile.ports.trim().isNotEmpty) {
      args.addAll(['-p', profile.ports.trim()]);
    }

    if (profile.envVars.trim().isNotEmpty) {
      final envLines = profile.envVars.split(RegExp(r'[\n,]'));
      for (final env in envLines) {
        if (env.trim().isNotEmpty) {
          args.addAll(['-e', env.trim()]);
        }
      }
    }

    if (profile.restartPolicy != 'no' && profile.restartPolicy.isNotEmpty) {
      args.addAll(['--restart', profile.restartPolicy]);
    }

    args.add(profile.image.trim());

    String cmd = profile.command.trim();
    if (profile.keepAlive && cmd.isEmpty) {
      cmd = 'sh -c "while true; do sleep 3600; done"';
    }

    if (cmd.isNotEmpty) {
      args.add(cmd);
    }

    final cmdStr = 'docker ${args.join(" ")}';
    final results = await _shell.run(cmdStr);
    if (results.isEmpty || results.first.exitCode != 0) {
      final stderr = results.first.stderr.toString();
      throw Exception(stderr.isNotEmpty ? stderr : 'Failed to run container with image ${profile.image}');
    }
  }

  /// Detect available terminal emulator on Linux
  Future<String?> _getTerminalEmulator() async {
    final emulators = ['x-terminal-emulator', 'gnome-terminal', 'xterm', 'konsole', 'xfce4-terminal'];
    for (final term in emulators) {
      try {
        final res = await _shell.run('which $term');
        if (res.isNotEmpty && res.first.exitCode == 0) {
          return term;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Open an interactive shell inside a running container in a separate window
  Future<void> openContainerShell(String id, {String shell = 'sh'}) async {
    final term = await _getTerminalEmulator();
    if (term == null) {
      throw Exception('No terminal emulator (x-terminal-emulator/xterm) found on system.');
    }

    final innerCmd = 'docker exec -it $id sh || docker exec -it $id bash || docker exec -it $id ash';
    final script = '$innerCmd; echo; echo "[DockerMon] Container shell session finished."; read -p "Press Enter to close window..."';

    String launchCmd;
    if (term == 'gnome-terminal') {
      launchCmd = '$term -- title "DockerMon Shell - $id" -- sh -c \'$script\'';
    } else {
      launchCmd = '$term -e "sh -c \'$script\'"';
    }

    await Process.start('sh', ['-c', launchCmd], runInShell: true);
  }

  /// Run a new container interactively in a separate terminal window
  Future<void> runInteractiveShell({
    required String image,
    String? customName,
    String command = 'sh',
  }) async {
    final term = await _getTerminalEmulator();
    if (term == null) {
      throw Exception('No terminal emulator (x-terminal-emulator/xterm) found on system.');
    }

    final nameFlag = (customName != null && customName.trim().isNotEmpty)
        ? '--name ${customName.trim()}'
        : '';
    final cmd = command.trim().isEmpty ? 'sh' : command.trim();

    final innerCmd = 'docker run -it --rm $nameFlag $image $cmd';
    final script = '$innerCmd; echo; echo "[DockerMon] Interactive container exited."; read -p "Press Enter to close window..."';

    String launchCmd;
    if (term == 'gnome-terminal') {
      launchCmd = '$term -- title "DockerMon Interactive - $image" -- sh -c \'$script\'';
    } else {
      launchCmd = '$term -e "sh -c \'$script\'"';
    }

    await Process.start('sh', ['-c', launchCmd], runInShell: true);
  }

  /// Execute a non-interactive command inside a container (In-App Exec Console)
  Future<String> execCommand(String id, String command) async {
    try {
      final results = await _shell.run('docker exec $id $command');
      if (results.isEmpty) return 'No output returned.';
      final stdout = results.first.stdout.toString();
      final stderr = results.first.stderr.toString();
      final combined = '$stdout\n$stderr'.trim();
      return combined.isEmpty ? 'Command executed cleanly.' : combined;
    } catch (e) {
      return 'Error executing command: $e';
    }
  }

  /// Remove a container by ID or Name
  Future<void> removeContainer(String id, {bool force = false}) async {
    final flag = force ? '-f' : '';
    final results = await _shell.run('docker rm $flag $id');
    if (results.isEmpty || results.first.exitCode != 0) {
      final stderr = results.first.stderr.toString();
      throw Exception(stderr.isNotEmpty ? stderr : 'Failed to remove container $id');
    }
  }

  /// Remove all stopped containers
  Future<void> pruneContainers() async {
    final results = await _shell.run('docker container prune -f');
    if (results.isEmpty || results.first.exitCode != 0) {
      final stderr = results.first.stderr.toString();
      throw Exception(stderr.isNotEmpty ? stderr : 'Failed to prune stopped containers.');
    }
  }
}
