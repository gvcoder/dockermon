import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/image_info.dart';
import '../providers/docker_provider.dart';
import 'launch_container_dialog.dart';
import 'pull_image_dialog.dart';

class ImagesTabView extends StatelessWidget {
  const ImagesTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DockerProvider>();
    final images = provider.filteredImages;

    return Column(
      children: [
        // Image Filter & Control Bar
        _buildControlBar(context, provider),
        const SizedBox(height: 16),

        // Images Grid/List View
        Expanded(
          child: images.isEmpty
              ? _buildEmptyState(context, provider)
              : ListView.builder(
                  itemCount: images.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final image = images[index];
                    return _ImageCard(image: image);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildControlBar(BuildContext context, DockerProvider provider) {
    final unusedCount = provider.images.where((img) => img.isDangling).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Search Input
          Expanded(
            child: TextField(
              onChanged: (val) => provider.setImageSearchQuery(val),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search images by repository, tag, or ID...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Prune Unused Images Button (visible if dangling images exist)
          if (unusedCount > 0) ...[
            OutlinedButton.icon(
              onPressed: () => _confirmPruneImages(context, provider),
              icon: const Icon(Icons.cleaning_services_rounded, size: 16),
              label: Text('Prune Unused ($unusedCount)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFAB40),
                side: BorderSide(color: const Color(0xFFFFAB40).withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Pull New Image Button
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const PullImageDialog(),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Pull Image'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B4DB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, DockerProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            provider.imageSearchQuery.isNotEmpty
                ? Icons.search_off_rounded
                : Icons.layers_clear_rounded,
            size: 56,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 14),
          Text(
            provider.imageSearchQuery.isNotEmpty
                ? 'No images matching "${provider.imageSearchQuery}"'
                : 'No local Docker images found',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            provider.imageSearchQuery.isNotEmpty
                ? 'Try clearing your search term.'
                : 'Click "Pull Image" to download images from Docker Hub.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          if (provider.imageSearchQuery.isEmpty)
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => const PullImageDialog(),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Pull First Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B4DB),
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  void _confirmPruneImages(BuildContext context, DockerProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E222D),
        title: const Row(
          children: [
            Icon(Icons.cleaning_services_rounded, color: Color(0xFFFFAB40), size: 24),
            SizedBox(width: 10),
            Text(
              'Prune Unused Images?',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'This will permanently delete all dangling and unused Docker images (docker image prune -a -f).\n\nImages currently used by containers will not be affected. Proceed?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.pruneImages();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFAB40),
              foregroundColor: Colors.black,
            ),
            child: const Text('Prune Unused Images'),
          ),
        ],
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final DockerImageInfo image;

  const _ImageCard({required this.image});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DockerProvider>();
    final isLoading = provider.isActionLoading(image.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: image.isDangling
              ? Colors.orange.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // Icon Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00B4DB).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.layers_rounded, color: Color(0xFF00B4DB), size: 24),
          ),
          const SizedBox(width: 16),

          // Main Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        image.repository,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Tag Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        image.tag,
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    if (image.isDangling) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Dangling',
                          style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),

                // Details Row: Size, Created, ID
                Row(
                  children: [
                    Icon(Icons.sd_storage_rounded, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(
                      image.size,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.schedule_rounded, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(
                      image.createdSince,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.fingerprint_rounded, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(
                      image.shortId,
                      style: const TextStyle(color: Colors.white38, fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Actions
          Row(
            children: [
              // Run Container from Image
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => LaunchContainerDialog(initialImage: image.fullName),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Run'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),

              // Interactive Shell (docker run -it)
              IconButton(
                onPressed: () {
                  provider.runInteractiveShell(image: image.fullName);
                },
                icon: const Icon(Icons.terminal_rounded, size: 20, color: Color(0xFF00B4DB)),
                tooltip: 'Launch Interactive Shell (docker run -it)',
                hoverColor: const Color(0xFF00B4DB).withValues(alpha: 0.1),
              ),
              const SizedBox(width: 4),

              // Delete Image Button
              IconButton(
                onPressed: isLoading ? null : () => _confirmRemoveImage(context, provider),
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF5252)),
                      )
                    : const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFFF5252)),
                tooltip: 'Remove Image (rmi)',
                hoverColor: const Color(0xFFFF5252).withValues(alpha: 0.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmRemoveImage(BuildContext context, DockerProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E222D),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Remove Image "${image.fullName}"?',
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete local Docker image "${image.fullName}" (${image.shortId})?\n\nIf containers depend on this image, you will need to force removal.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.removeImage(image.id, force: true);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF5252),
              side: const BorderSide(color: Color(0xFFFF5252)),
            ),
            child: const Text('Force Remove (-f)'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.removeImage(image.id, force: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove Image'),
          ),
        ],
      ),
    );
  }
}
