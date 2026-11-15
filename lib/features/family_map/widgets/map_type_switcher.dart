import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapTypeSwitcher extends StatelessWidget {
  const MapTypeSwitcher({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final MapType value;
  final ValueChanged<MapType> onChanged;
  @override
  Widget build(BuildContext context) => PopupMenuButton<MapType>(
    tooltip: 'Map type',
    initialValue: value,
    onSelected: onChanged,
    icon: const Icon(Icons.layers),
    itemBuilder: (_) => [
      for (final type in [
        MapType.normal,
        MapType.satellite,
        MapType.terrain,
        MapType.hybrid,
      ])
        CheckedPopupMenuItem(
          value: type,
          checked: type == value,
          child: Text(type.name),
        ),
    ],
  );
}
