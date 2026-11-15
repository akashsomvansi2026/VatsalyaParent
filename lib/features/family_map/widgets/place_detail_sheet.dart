import 'package:flutter/material.dart';
import '../services/directions_service.dart';

class PlaceDetailSheet extends StatelessWidget {
  const PlaceDetailSheet({
    super.key,
    required this.title,
    required this.route,
    required this.onSteps,
    this.address,
  });
  final String title;
  final String? address;
  final RouteResult route;
  final VoidCallback onSteps;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          if (address != null) Text(address!),
          Text(
            '${(route.metres / 1000).toStringAsFixed(1)} km - ${(route.seconds / 60).ceil()} min drive',
          ),
          FilledButton.icon(
            onPressed: onSteps,
            icon: const Icon(Icons.route),
            label: const Text('Turn-by-turn directions'),
          ),
          Text(route.copyright),
        ],
      ),
    ),
  );
}
