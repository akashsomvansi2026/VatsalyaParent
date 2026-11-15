import 'package:vrajrani_tech_solution/branding/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

/// Adaptive primary navigation. Routes and permission guards remain unchanged.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.child});
  final Widget child;
  static const paths = ['/', '/dashboard', '/features', '/settings'];
  static const labels = ['Family map', 'Dashboard', 'Features', 'Settings'];
  static const icons = [
    Icons.map_outlined,
    Icons.dashboard_outlined,
    Icons.grid_view_outlined,
    Icons.settings_outlined,
  ];
  static const activeIcons = [
    Icons.map_rounded,
    Icons.dashboard_rounded,
    Icons.grid_view_rounded,
    Icons.settings_rounded,
  ];
  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final index = paths.contains(path) ? paths.indexOf(path) : 0;
    void navigate(int selected) => context.go(paths[selected]);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= 840 ||
            (constraints.maxWidth >= 700 && constraints.maxHeight < 500);
        return Scaffold(
          body: Row(
            children: [
              if (wide)
                SafeArea(
                  child: NavigationRail(
                    scrollable: true,
                    extended:
                        constraints.maxWidth >= 1200 &&
                        MediaQuery.textScalerOf(context).scale(14) <= 21,
                    backgroundColor: AppColors.surface,
                    selectedIndex: index,
                    onDestinationSelected: navigate,
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Tooltip(
                        message: 'Vatsalya • Family care',
                        child: BrandMark(size: 32),
                      ),
                    ),
                    destinations: [
                      for (var i = 0; i < paths.length; i++)
                        NavigationRailDestination(
                          icon: Icon(icons[i]),
                          selectedIcon: Icon(activeIcons[i]),
                          label: Text(labels[i]),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: index == 0 ? double.infinity : 1120,
                    ),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0A0F172A),
                        blurRadius: 16,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        navigationBarTheme: NavigationBarThemeData(
                          height: 70,
                          backgroundColor: Colors.white,
                          indicatorColor: const Color(0xFFFFEEE5),
                          iconTheme: WidgetStateProperty.resolveWith(
                            (states) => IconThemeData(
                              size: 25,
                              color: states.contains(WidgetState.selected)
                                  ? const Color(0xFFFF5715)
                                  : const Color(0xFF626878),
                            ),
                          ),
                          labelTextStyle: WidgetStateProperty.resolveWith(
                            (states) => TextStyle(
                              fontSize: 11,
                              fontWeight: states.contains(WidgetState.selected)
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: states.contains(WidgetState.selected)
                                  ? const Color(0xFFFF5715)
                                  : const Color(0xFF626878),
                            ),
                          ),
                        ),
                      ),
                      child: NavigationBar(
                        labelBehavior:
                            MediaQuery.textScalerOf(context).scale(12) > 17
                            ? NavigationDestinationLabelBehavior.alwaysHide
                            : NavigationDestinationLabelBehavior.alwaysShow,
                        selectedIndex: index,
                        onDestinationSelected: navigate,
                        destinations: [
                          for (var i = 0; i < paths.length; i++)
                            NavigationDestination(
                              icon: Icon(icons[i]),
                              selectedIcon: Icon(activeIcons[i]),
                              label: labels[i],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
