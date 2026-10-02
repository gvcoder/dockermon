import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/docker_provider.dart';
import '../services/docker_service.dart';

class PermissionErrorView extends StatelessWidget {
  const PermissionErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DockerProvider>();
    final healthState = provider.health.state;

    String title;
    String description;
    IconData icon;
    Color iconColor;

    if (healthState == DockerHealthState.permissionDenied) {
      title = 'Docker Socket Permission Required';
      description =
          'Your Linux user account lacks permission to read/write to /var/run/docker.sock.';
      icon = Icons.lock_person_rounded;
      iconColor = const Color(0xFFFFAB40);
    } else if (healthState == DockerHealthState.daemonNotRunning) {
      title = 'Docker Daemon Service is Offline';
      description =
          'The Docker background service is not running on your machine.';
      icon = Icons.power_settings_new_rounded;
      iconColor = const Color(0xFFFF5252);
    } else {
      title = 'Docker Not Found';
      description =
          'The docker executable could not be detected in your system PATH.';
      icon = Icons.warning_amber_rounded;
      iconColor = const Color(0xFFFF5252);
    }

    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E222D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: iconColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            if (healthState == DockerHealthState.permissionDenied) ...[
              _buildResolutionBox(
                context,
                cmd: 'sudo usermod -aG docker \$USER',
                steps: const [
                  'Add your user account to the docker group:',
                  'Apply group updates: run "newgrp docker" or log out & back in.',
                  'Click "Re-check Connection" below.',
                ],
              ),
            ] else if (healthState == DockerHealthState.daemonNotRunning) ...[
              _buildResolutionBox(
                context,
                cmd: 'sudo systemctl start docker',
                steps: const [
                  'Start the Docker daemon service in your terminal:',
                  'Verify service status: "systemctl status docker".',
                  'Click "Re-check Connection" below.',
                ],
              ),
            ] else ...[
              _buildResolutionBox(
                context,
                cmd: 'sudo apt install docker.io',
                steps: const [
                  'Install Docker Engine on Ubuntu/Debian:',
                  'Ensure docker daemon is started.',
                  'Click "Re-check Connection" below.',
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Re-check Connection Button
            ElevatedButton.icon(
              onPressed: provider.isRefreshing ? null : provider.checkHealthAndRefresh,
              icon: provider.isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Re-check Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007ACC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildResolutionBox(BuildContext context, {required String cmd, required List<String> steps}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141721),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended Resolution Steps:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // Command Box with Copy Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00B4DB).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    cmd,
                    style: const TextStyle(
                      color: Color(0xFF00B4DB),
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white70),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: cmd.replaceAll(r'$USER', '')));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Command copied to clipboard!'),
                        backgroundColor: Color(0xFF007ACC),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Copy Command',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          for (int i = 0; i < steps.length; i++) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}. ',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
