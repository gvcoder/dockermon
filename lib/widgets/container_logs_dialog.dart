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
  final TextEditingController _execCmdController = TextEditingController(text: 'ls -la');

  String _logsText = 'Loading logs...';
  String _inspectText = 'Loading inspect metadata...';
  String _execResultText = 'Enter a command above and click "Run Exec" (e.g., ls -la, ps aux, env, cat /etc/os-release)';

  bool _isLoadingLogs = true;
  bool _isLoadingInspect = true;
  bool _isExecutingCmd = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

  Future<void> _runExecCommand([String? overrideCmd]) async {
    final cmd = overrideCmd ?? _execCmdController.text.trim();
    if (cmd.isEmpty) return;

    if (overrideCmd != null) {
      _execCmdController.text = overrideCmd;
    }

    setState(() {
      _isExecutingCmd = true;
      _execResultText = 'Running "docker exec ${widget.container.shortId} $cmd"...';
    });

    final provider = context.read<DockerProvider>();
    final result = await provider.execCommand(widget.container.id, cmd);

    if (mounted) {
      setState(() {
        _execResultText = result;
        _isExecutingCmd = false;
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
    _execCmdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF181B26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 850,
        height: 620,
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
                          'ID: ${widget.container.shortId} | Image: ${widget.container.image} | State: ${widget.container.stateRaw}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Open External Terminal Window Button
                    if (widget.container.isRunning) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<DockerProvider>().openContainerShell(widget.container.id);
                        },
                        icon: const Icon(Icons.computer_rounded, size: 16),
                        label: const Text('Open External Terminal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B4DB),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    ),
                  ],
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
                  Tab(text: 'Exec Console / Command Runner'),
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

                  // Tab 3: Exec Console / Command Runner
                  _buildExecConsoleTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecConsoleTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Presets Row & Run Bar
        Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0E14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _execCmdController,
                  onSubmitted: (_) => _runExecCommand(),
                  enabled: widget.container.isRunning,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: widget.container.isRunning
                        ? 'Enter command to run (e.g. ls -la, ps aux, env)...'
                        : 'Container is stopped. Start container to run exec commands.',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                    prefixIcon: const Icon(Icons.code_rounded, size: 16, color: Color(0xFF00B4DB)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: (widget.container.isRunning && !_isExecutingCmd) ? () => _runExecCommand() : null,
              icon: _isExecutingCmd
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Run Exec'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Quick Exec Preset Chips
        Row(
          children: [
            Text('Quick Commands: ', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
            const SizedBox(width: 6),
            _buildPresetChip('ls -la'),
            const SizedBox(width: 6),
            _buildPresetChip('ps aux'),
            const SizedBox(width: 6),
            _buildPresetChip('env'),
            const SizedBox(width: 6),
            _buildPresetChip('cat /etc/os-release'),
            const SizedBox(width: 6),
            _buildPresetChip('df -h'),
          ],
        ),
        const SizedBox(height: 10),

        // Console Output View
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0E14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: _isExecutingCmd
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00B4DB)),
                  )
                : SingleChildScrollView(
                    child: SelectableText(
                      _execResultText,
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

  Widget _buildPresetChip(String cmd) {
    return InkWell(
      onTap: widget.container.isRunning ? () => _runExecCommand(cmd) : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          cmd,
          style: const TextStyle(
            color: Color(0xFF00B4DB),
            fontSize: 11,
            fontFamily: 'monospace',
          ),
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
