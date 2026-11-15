import 'package:flutter/material.dart';

import '../../data/models/child.dart';
import '../services/nearby_address.dart';
import '../theme/app_colors.dart';
import '../utils/child_location_status.dart';
import '../utils/formatters.dart';

class ChildLocationOverview extends StatelessWidget {
  const ChildLocationOverview({
    super.key,
    required this.child,
    this.compact = false,
  });

  final Child child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final status = ChildLocationStatus.fromChild(child);
    final point = child.latestLocation;
    final canShow = status.hasLocation && point != null;
    final color = status.isRecent ? AppColors.onlineDark : AppColors.warning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(status.isRecent ? Icons.location_on : Icons.history,
              size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(status.label,
              style: TextStyle(fontWeight: FontWeight.w700, color: color))),
        ]),
        const SizedBox(height: 4),
        Text(status.detail, style: const TextStyle(color: AppColors.muted)),
        if (canShow) ...[
          const SizedBox(height: 6),
          FutureBuilder<NearbyAddress?>(
            future: NearbyAddressService.resolve(point),
            builder: (context, snapshot) {
              final address = snapshot.data;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address?.shortLabel ?? 'Address unavailable · see map',
                      maxLines: compact ? 2 : null,
                      overflow: compact ? TextOverflow.ellipsis : null,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (!compact && address?.details != null)
                    Text(address!.details!,
                        style: const TextStyle(color: AppColors.muted)),
                ],
              );
            },
          ),
          if (!compact) ...[
            if (point.accuracy != null && point.accuracy!.isFinite)
              Text('Accuracy: approximately ${point.accuracy!.round()} m',
                  style: const TextStyle(color: AppColors.muted)),
            if (point.speed != null && point.speed! >= 1.5)
              const Text('Movement reported at last update',
                  style: TextStyle(color: AppColors.muted)),
            Text('Battery: ${Formatters.batteryLabel(child.batteryLevel ?? point.batteryLevel)}',
                style: const TextStyle(color: AppColors.muted)),
            TextButton.icon(
              onPressed: () async {
                final opened = await NearbyAddressService.openInMaps(point);
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('No maps app is available on this device.'),
                  ));
                }
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open in Maps'),
            ),
          ],
        ],
      ],
    );
  }
}
