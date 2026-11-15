import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/places_service.dart';

class NearbyPlacesSheet extends StatefulWidget {
  const NearbyPlacesSheet({
    super.key,
    required this.origin,
    required this.service,
    required this.onPlace,
  });
  final LatLng origin;
  final PlacesService service;
  final ValueChanged<NearbyPlace> onPlace;
  @override
  State<NearbyPlacesSheet> createState() => _NearbyPlacesSheetState();
}

class _NearbyPlacesSheetState extends State<NearbyPlacesSheet> {
  String category = 'School';
  late Future<List<NearbyPlace>> results;
  @override
  void initState() {
    super.initState();
    search();
  }

  void search() {
    results = widget.service.searchNearby(widget.origin, category);
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: .65,
    minChildSize: .35,
    maxChildSize: .95,
    builder: (context, controller) => Material(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: ListView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        children: [
          Text('Nearby', style: Theme.of(context).textTheme.headlineSmall),
          const Text('Within 3 km of your location'),
          Wrap(
            spacing: 8,
            children: [
              for (final name in PlacesService.categories.keys)
                ChoiceChip(
                  label: Text(name),
                  selected: category == name,
                  onSelected: (_) => setState(() {
                    category = name;
                    search();
                  }),
                ),
            ],
          ),
          FutureBuilder<List<NearbyPlace>>(
            future: results,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Column(
                  children: [
                    Text(NearbyFailure.from(snapshot.error!).message),
                    TextButton(
                      onPressed: () => setState(search),
                      child: const Text('Retry'),
                    ),
                  ],
                );
              }
              final rows = snapshot.data ?? [];
              if (rows.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No places found in this category.'),
                );
              }
              return Column(
                children: [
                  for (final place in rows)
                    ListTile(
                      title: Text(place.name),
                      subtitle: Text(
                        '${place.address}${place.rating == null ? '' : ' - Rating ${place.rating}'}',
                      ),
                      trailing: const Icon(Icons.location_on_outlined),
                      onTap: () => widget.onPlace(place),
                    ),
                ],
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('Google Maps', textAlign: TextAlign.center),
          ),
        ],
      ),
    ),
  );
}
