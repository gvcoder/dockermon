import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/docker_provider.dart';
import '../services/docker_service.dart';
import 'launch_container_dialog.dart';

class StatusHeader extends StatelessWidget {
  const StatusHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DockerProvider>();
    final healthState = provider.health.state;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222D),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // Row 1: App title & Connection status pill + Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF007ACC), Color(0xFF00B4DB)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.view_in_ar_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DockerMon',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Linux Docker Engine Monitor',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Status Pill & Action Buttons
              Row(
                children: [
                  _buildStatusPill(healthState, provider.health.message),
                  const SizedBox(width: 16),
                  
                  // Auto Refresh Toggle
                  Tooltip(
                    message: provider.autoRefreshEnabled
                        ? 'Auto-refresh active (3s polling)'
                        : 'Auto-refresh paused',
                    child: InkWell(
                      onTap: provider.toggleAutoRefresh,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: provider.autoRefreshEnabled
                              ? const Color(0xFF007ACC).withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: provider.autoRefreshEnabled
                                ? const Color(0xFF007ACC)
                                : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.sync_rounded,
                              size: 16,
                              color: provider.autoRefreshEnabled
                                  ? const Color(0xFF00B4DB)
                                  : Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              provider.autoRefreshEnabled ? 'Live Sync' : 'Paused',
                              style: TextStyle(
                                color: provider.autoRefreshEnabled
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Manual Refresh Button
                  IconButton(
                    onPressed: provider.isRefreshing ? null : provider.checkHealthAndRefresh,
                    icon: provider.isRefreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF00B4DB),
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, color: Colors.white70),
                    tooltip: 'Refresh Containers',
                  ),
                  const SizedBox(width: 8),

                  // Launch Container Button
                  ElevatedButton.icon(
                    onPressed: healthState == DockerHealthState.ok
                        ? () {
                            showDialog(
                              context: context,
                              builder: (ctx) => const LaunchContainerDialog(),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Launch Container'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Row 2: Metric Stat Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Containers',
                  count: provider.totalCount,
                  icon: Icons.inventory_2_rounded,
                  accentColor: const Color(0xFF00B4DB),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricCard(
                  title: 'Running',
                  count: provider.runningCount,
                  icon: Icons.play_circle_fill_rounded,
                  accentColor: const Color(0xFF00E676),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricCard(
                  title: 'Stopped',
                  count: provider.stoppedCount,
                  icon: Icons.stop_circle_rounded,
                  accentColor: const Color(0xFFFF5252),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricCard(
                  title: 'Paused',
                  count: provider.pausedCount,
                  icon: Icons.pause_circle_filled_rounded,
                  accentColor: const Color(0xFFFFAB40),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(DockerHealthState state, String message) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (state) {
      case DockerHealthState.ok:
        bg = const Color(0xFF00E676).withOpacity(0.15);
        fg = const Color(0xFF00E676);
        label = 'Connected';
        icon = Icons.check_circle_rounded;
        break;
      case DockerHealthState.permissionDenied:
        bg = const Color(0xFFFFAB40).withOpacity(0.15);
        fg = const Color(0xFFFFAB40);
        label = 'Permission Error';
        icon = Icons.lock_rounded;
        break;
      case DockerHealthState.daemonNotRunning:
        bg = const Color(0xFFFF5252).withOpacity(0.15);
        fg = const Color(0xFFFF5252);
        label = 'Daemon Offline';
        icon = Icons.error_rounded;
        break;
      case DockerHealthState.dockerNotInstalled:
        bg = const Color(0xFFFF5252).withOpacity(0.15);
        fg = const Color(0xFFFF5252);
        label = 'Docker Missing';
        icon = Icons.warning_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required int count,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141721),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
