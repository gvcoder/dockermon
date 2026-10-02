import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/docker_provider.dart';

class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DockerProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Search Input Field
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF141721),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                onChanged: provider.setSearchQuery,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search containers by name, image, status, ID...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.white54),
                  suffixIcon: provider.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16, color: Colors.white54),
                          onPressed: () => provider.setSearchQuery(''),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Status Filter Selector Chips
          Row(
            children: [
              _buildFilterChip(
                context,
                label: 'All (${provider.totalCount})',
                filter: StatusFilter.all,
                isSelected: provider.selectedFilter == StatusFilter.all,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context,
                label: 'Running (${provider.runningCount})',
                filter: StatusFilter.running,
                isSelected: provider.selectedFilter == StatusFilter.running,
                badgeColor: const Color(0xFF00E676),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context,
                label: 'Stopped (${provider.stoppedCount})',
                filter: StatusFilter.stopped,
                isSelected: provider.selectedFilter == StatusFilter.stopped,
                badgeColor: const Color(0xFFFF5252),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context,
                label: 'Paused (${provider.pausedCount})',
                filter: StatusFilter.paused,
                isSelected: provider.selectedFilter == StatusFilter.paused,
                badgeColor: const Color(0xFFFFAB40),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required StatusFilter filter,
    required bool isSelected,
    Color? badgeColor,
  }) {
    return InkWell(
      onTap: () => context.read<DockerProvider>().setStatusFilter(filter),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF007ACC).withOpacity(0.25)
              : const Color(0xFF141721),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF007ACC)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
