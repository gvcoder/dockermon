import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/container_info.dart';
import '../providers/docker_provider.dart';

class ContainerLogsDialog extends StatefulWidget {
  final ContainerInfo container;

  const ContainerLogsDialog({super.key, required this.container});

  @override
  State<ContainerLogsDialog> createState() => _ContainerLogsDialogState();
}

class _ContainerLogsDialogState extends State<ContainerLogsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _logsText = 'Loading logs...';
  String _inspectText = 'Loading inspect metadata...';
  bool _isLoadingLogs = true;
  bool _isLoadingInspect = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLogs();
    _loadInspect();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoadingLogs = true);
    final provider = context.read<DockerProvider>();
    final result = await provider.fetchLogs(widget.container.id);
    if (mounted) {
      setState(() {
        _logsText = result;
        _isLoadingLogs = false;
      });
    }
  }

  Future<void> _loadInspect() async {
    setState(() => _isLoadingInspect = true);
    final provider = context.read<DockerProvider>();
    final result = await provider.fetchInspect(widget.container.id);
    if (mounted) {
      setState(() {
        _inspectText = result;
        _isLoadingInspect = false;
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: const Color(0xFF007ACC),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF181B26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Title & Tab Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.terminal_rounded, color: Color(0xFF00B4DB), size: 24),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.container.cleanName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: ${widget.container.shortId} | Image: ${widget.container.image}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tabs Header
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF10121A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF00B4DB),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                tabs: const [
                  Tab(text: 'Stdout / Stderr Logs'),
                  Tab(text: 'Inspect JSON'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tab Views Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Terminal Logs
                  _buildCodeViewer(
                    content: _logsText,
                    isLoading: _isLoadingLogs,
                    label: 'Logs',
                    onRefresh: _loadLogs,
                  ),

                  // Tab 2: Inspect Metadata
                  _buildCodeViewer(
                    content: _inspectText,
                    isLoading: _isLoadingInspect,
                    label: 'Inspect Data',
                    onRefresh: _loadInspect,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeViewer({
    required String content,
    required bool isLoading,
    required String label,
    required VoidCallback onRefresh,
  }) {
    return Column(
      children: [
        // Action buttons bar
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white70),
              tooltip: 'Refresh $label',
            ),
            IconButton(
              onPressed: () => _copyToClipboard(content, label),
              icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.white70),
              tooltip: 'Copy $label',
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Terminal box
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0E14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00B4DB)),
                  )
                : SingleChildScrollView(
                    child: SelectableText(
                      content,
                      style: const TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
