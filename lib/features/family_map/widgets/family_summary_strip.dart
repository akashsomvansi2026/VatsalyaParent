import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class FamilySummaryStrip extends StatelessWidget {
  const FamilySummaryStrip({
    super.key,
    required this.onlineCount,
    required this.totalCount,
    required this.hasParentLocation,
    this.cachedAtUtc,
    this.synchronized = true,
  });
  final bool synchronized, hasParentLocation;
  final int onlineCount, totalCount;
  final DateTime? cachedAtUtc;
  @override
  Widget build(BuildContext context) {
    final cached = cachedAtUtc != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 18,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
                final columns = constraints.maxWidth >= 3 * (42 + 60 * scale)
                    ? 3
                    : 1;
                final width = constraints.maxWidth / columns;
                return Wrap(
                  runSpacing: 4,
                  children: [
                    _StatusCard(
                      width: width,
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFFFF5722),
                      value: '$onlineCount/$totalCount',
                      subtitle: 'Online',
                    ),
                    _StatusCard(
                      width: width,
                      icon: Icons.my_location_rounded,
                      color: const Color(0xFF00A66B),
                      value: hasParentLocation ? 'Active' : 'Unavailable',
                      subtitle: 'Your GPS',
                    ),
                    _StatusCard(
                      width: width,
                      icon: cached
                          ? Icons.cloud_off_rounded
                          : Icons.cloud_done_rounded,
                      color: cached
                          ? AppColors.warning
                          : const Color(0xFF0D9488),
                      value: cached
                          ? 'Cached'
                          : synchronized
                          ? 'Synced'
                          : 'Last sync',
                      subtitle: cached
                          ? 'Offline copy'
                          : synchronized
                          ? 'Data updated'
                          : 'Awaiting data',
                    ),
                  ],
                );
              },
            ),
            if (cached)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Showing offline copy from ${Formatters.relativeTime(cachedAtUtc)}. Locations are not live.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.width,
    required this.icon,
    required this.color,
    required this.value,
    required this.subtitle,
  });
  final double width;
  final IconData icon;
  final Color color;
  final String value, subtitle;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
