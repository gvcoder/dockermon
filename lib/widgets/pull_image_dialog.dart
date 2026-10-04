import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/docker_provider.dart';

class PullImageDialog extends StatefulWidget {
  const PullImageDialog({super.key});

  @override
  State<PullImageDialog> createState() => _PullImageDialogState();
}

class _PullImageDialogState extends State<PullImageDialog> {
  final TextEditingController _imageController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _popularPresets = [
    'alpine:latest',
    'ubuntu:latest',
    'nginx:alpine',
    'redis:alpine',
    'postgres:latest',
    'python:3.11-slim',
    'node:20-alpine',
  ];

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _handlePull() async {
    final imageName = _imageController.text.trim();
    if (imageName.isEmpty) {
      setState(() => _errorMessage = 'Please enter a valid Docker image name');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final provider = context.read<DockerProvider>();
    try {
      await provider.pullImage(imageName);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676)),
                const SizedBox(width: 10),
                Expanded(child: Text('Successfully pulled image "$imageName"')),
              ],
            ),
            backgroundColor: const Color(0xFF1E222D),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF181B26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B4DB).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.cloud_download_rounded, color: Color(0xFF00B4DB), size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pull Docker Image',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Download image from Docker Hub or private registry',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Image Input Field
            TextField(
              controller: _imageController,
              enabled: !_isLoading,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. alpine:latest, redis:7-alpine, myrepo/app:v1',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                prefixIcon: const Icon(Icons.inventory_2_outlined, color: Colors.white54, size: 20),
                suffixIcon: _imageController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white38, size: 18),
                        onPressed: () => setState(() => _imageController.clear()),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF141721),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00B4DB)),
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _handlePull(),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFFF5252), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFFF5252), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            // Preset Badges
            const Text(
              'Popular Presets',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _popularPresets.map((preset) {
                final isSelected = _imageController.text == preset;
                return ActionChip(
                  label: Text(preset),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: isSelected ? const Color(0xFF00B4DB) : const Color(0xFF141721),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF00B4DB) : Colors.white.withValues(alpha: 0.1),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _imageController.text = preset;
                          });
                        },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handlePull,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.download_rounded, size: 18),
                  label: Text(_isLoading ? 'Pulling Image...' : 'Pull Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B4DB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
