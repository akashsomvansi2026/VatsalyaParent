import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/status_views.dart';
import '../../../../../data/models/usage_record.dart';
import '../../../providers/child_detail_provider.dart';

/// Screen-time usage with day grouping, per-day totals and top-app bars
/// (mirrors the portal's Usage tab).
class UsageTab extends ConsumerWidget {
  const UsageTab({super.key, required this.childId});

  final int childId;

  static const List<(int, String)> _ranges = [
    (1, 'Today'),
    (3, '3 days'),
    (7, '7 days'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(childDetailProvider(childId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<int>(
            segments: _ranges
                .map(
                  (range) =>
                      ButtonSegment(value: range.$1, label: Text(range.$2)),
                )
                .toList(),
            selected: {state.usageDays},
            onSelectionChanged: (selection) {
              final days = selection.first;
              if (days != state.usageDays) {
                ref
                    .read(childDetailProvider(childId).notifier)
                    .loadUsage(days: days);
              }
            },
          ),
        ),
        const SizedBox(height: 14),
        if (state.usageLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: LoadingView(),
          )
        else if (state.usage.isEmpty)
          const AppCard(
            padding: EdgeInsets.all(20),
            child: EmptyState(
              icon: Icons.timelapse_outlined,
              title: 'No usage data yet',
              subtitle:
                  'Screen-time statistics will appear here once the child device syncs its usage.',
            ),
          )
        else
          ..._groupedDailySections(state.usage),
      ],
    );
  }

  List<Widget> _groupedDailySections(List<UsageRecord> usage) {
    final byDate = <DateTime, List<UsageRecord>>{};
    for (final record in usage) {
      final date = DateTime.utc(
        record.usageDate.year,
        record.usageDate.month,
        record.usageDate.day,
      );
      byDate.putIfAbsent(date, () => []).add(record);
    }

    final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return dates.map((date) {
      final records = byDate[date]!
        ..sort((a, b) => b.usedMillis.compareTo(a.usedMillis));
      final total = records.fold<int>(0, (sum, r) => sum + r.usedMillis);
      final top = records.take(8).toList();
      final maxMillis = top.fold<int>(
        1,
        (m, r) => r.usedMillis > m ? r.usedMillis : m,
      );

      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('EEEE, d MMM').format(date.toLocal()),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  Text(
                    'Total ${Formatters.duration(total)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...top.map(
                (record) => _UsageBar(
                  appName: record.appName.isEmpty
                      ? record.packageName
                      : record.appName,
                  durationText: Formatters.duration(record.usedMillis),
                  fraction: (record.usedMillis / maxMillis).clamp(0.03, 1.0),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _UsageBar extends StatelessWidget {
  const _UsageBar({
    required this.appName,
    required this.durationText,
    required this.fraction,
  });

  final String appName;
  final String durationText;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  durationText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
