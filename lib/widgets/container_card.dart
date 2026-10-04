import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/container_info.dart';
import '../providers/docker_provider.dart';
import 'container_logs_dialog.dart';

class ContainerCard extends StatelessWidget {
  final ContainerInfo container;

  const ContainerCard({super.key, required this.container});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DockerProvider>();
    final isLoading = provider.isActionLoading(container.id);
    final actionType = provider.getActionType(container.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: container.isRunning
              ? const Color(0xFF00E676).withOpacity(0.2)
              : Colors.white.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status Dot Indicator
          _buildStatusDot(container.state),
          const SizedBox(width: 16),

          // Container Details (Name, Image, ID, Status, Ports)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        container.cleanName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Short ID Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        container.shortId,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Image Name & Uptime Status
                Row(
                  children: [
                    Icon(
                      Icons.layers_outlined,
                      size: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        container.image,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      container.status,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                // Ports Mapping if available
                if (container.ports.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.input_rounded,
                        size: 14,
                        color: const Color(0xFF00B4DB).withOpacity(0.8),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          container.ports,
                          style: const TextStyle(
                            color: Color(0xFF00B4DB),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Control Action Buttons Row
          Row(
            children: [
              // Start Button (Active if not running)
              _buildActionButton(
                context,
                tooltip: 'Start Container',
                icon: Icons.play_arrow_rounded,
                color: const Color(0xFF00E676),
                enabled: !container.isRunning && !isLoading,
                isSpinning: isLoading && actionType == 'starting',
                onPressed: () => provider.startContainer(container.id),
              ),
              const SizedBox(width: 8),

              // Stop Button (Active if running)
              _buildActionButton(
                context,
                tooltip: 'Stop Container',
                icon: Icons.stop_rounded,
                color: const Color(0xFFFF5252),
                enabled: container.isRunning && !isLoading,
                isSpinning: isLoading && actionType == 'stopping',
                onPressed: () => provider.stopContainer(container.id),
              ),
              const SizedBox(width: 8),

              // Restart Button (Active if running)
              _buildActionButton(
                context,
                tooltip: 'Restart Container',
                icon: Icons.restart_alt_rounded,
                color: const Color(0xFFFFAB40),
                enabled: container.isRunning && !isLoading,
                isSpinning: isLoading && actionType == 'restarting',
                onPressed: () => provider.restartContainer(container.id),
              ),
              const SizedBox(width: 8),

              // Open Interactive Terminal Shell (Active if running)
              _buildActionButton(
                context,
                tooltip: 'Open Interactive Terminal Window (docker exec -it)',
                icon: Icons.computer_rounded,
                color: const Color(0xFF00B4DB),
                enabled: container.isRunning,
                isSpinning: false,
                onPressed: () => provider.openContainerShell(container.id),
              ),
              const SizedBox(width: 8),

              // Logs & Inspect Button
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => ContainerLogsDialog(container: container),
                  );
                },
                icon: const Icon(Icons.terminal_rounded, size: 20, color: Colors.white70),
                tooltip: 'View Logs & Inspect JSON',
                hoverColor: Colors.white.withOpacity(0.1),
              ),
              const SizedBox(width: 4),

              // Delete Container Button (Trash 🗑️)
              _buildActionButton(
                context,
                tooltip: container.isRunning ? 'Stop container before removing or force remove' : 'Remove Container',
                icon: Icons.delete_outline_rounded,
                color: const Color(0xFFFF5252),
                enabled: !isLoading,
                isSpinning: isLoading && actionType == 'removing',
                onPressed: () => _confirmDeleteContainer(context, provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteContainer(BuildContext context, DockerProvider provider) {
    final isRunning = container.isRunning;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E222D),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 24),
            const SizedBox(width: 10),
            Text(
              'Remove Container?',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          isRunning
              ? 'Container "${container.cleanName}" is currently running. Removing it will FORCE stop it (-f).\n\nDo you want to proceed?'
              : 'Are you sure you want to permanently remove container "${container.cleanName}" (${container.shortId})?',
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.removeContainer(container.id, force: isRunning);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
            ),
            child: Text(isRunning ? 'Force Remove' : 'Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDot(ContainerState state) {
    Color color;
    switch (state) {
      case ContainerState.running:
        color = const Color(0xFF00E676);
        break;
      case ContainerState.exited:
      case ContainerState.created:
        color = const Color(0xFFFF5252);
        break;
      case ContainerState.paused:
        color = const Color(0xFFFFAB40);
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String tooltip,
    required IconData icon,
    required Color color,
    required bool enabled,
    required bool isSpinning,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: enabled ? color.withOpacity(0.12) : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: enabled ? color.withOpacity(0.4) : Colors.transparent,
              ),
            ),
            child: isSpinning
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Icon(
                    icon,
                    size: 18,
                    color: enabled ? color : Colors.white.withOpacity(0.25),
                  ),
          ),
        ),
      ),
    );
  }
}
