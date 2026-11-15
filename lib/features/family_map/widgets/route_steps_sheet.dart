import 'package:flutter/material.dart';
import '../services/directions_service.dart';

class RouteStepsSheet extends StatelessWidget {
  const RouteStepsSheet({super.key, required this.route});
  final RouteResult route;
  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: .65,
    minChildSize: .3,
    maxChildSize: .95,
    builder: (context, controller) => ListView(
      controller: controller,
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Turn-by-turn directions',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        for (var i = 0; i < route.steps.length; i++)
          ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(route.steps[i].instruction),
            subtitle: Text(
              '${route.steps[i].distance} - ${route.steps[i].duration}',
            ),
          ),
        Text(route.copyright),
      ],
    ),
  );
}
