import 'package:flutter/material.dart';

const familyOrange = Color(0xFFFF681D);
const familyInk = Color(0xFF20211E);
const familyMuted = Color(0xFF858985);

class FamilyManagementHero extends StatelessWidget {
  const FamilyManagementHero({
    super.key,
    required this.devices,
    required this.subtitle,
  });
  final bool devices;
  final String subtitle;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < 340 ||
          MediaQuery.textScalerOf(context).scale(14) > 20;
      final artworkWidth = (constraints.maxWidth * .43).clamp(120.0, 230.0);
      final heading = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: devices ? 'Connected ' : 'Your '),
                TextSpan(
                  text: devices ? 'Devices' : 'Family Circle',
                  style: const TextStyle(color: familyOrange),
                ),
              ],
            ),
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: familyInk,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: familyMuted,
            ),
          ),
        ],
      );
      final art = ExcludeSemantics(
        child: devices
            ? Container(
                width: artworkWidth,
                height: artworkWidth * .75,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFF0E6),
                ),
                child: const Icon(
                  Icons.devices_rounded,
                  color: familyOrange,
                  size: 85,
                ),
              )
            : Image.asset(
                'assets/illustrations/family_portrait.png',
                width: artworkWidth,
              ),
      );
      if (stacked) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading,
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 150,
                height: 130,
                child: FittedBox(fit: BoxFit.contain, child: art),
              ),
            ),
          ],
        );
      }
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 145),
        child: Stack(
          children: [
            Positioned(right: 0, bottom: -8, child: art),
            Padding(
              padding: EdgeInsets.only(
                right: artworkWidth * .88,
                top: 36,
                bottom: 26,
              ),
              child: heading,
            ),
          ],
        ),
      );
    },
  );
}

class FamilySearchField extends StatelessWidget {
  const FamilySearchField({
    super.key,
    required this.devices,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });
  final bool devices;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: 'Search ${devices ? 'devices' : 'children'}',
      prefixIcon: const Icon(
        Icons.search_rounded,
        color: Color(0xFF6E3F2A),
        size: 26,
      ),
      suffixIcon: controller.text.isEmpty
          ? null
          : IconButton(
              tooltip: 'Clear search',
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            ),
      filled: true,
      fillColor: const Color(0xFFFFF6F0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(32)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: const BorderSide(color: familyOrange, width: 1.5),
      ),
    ),
  );
}

class FamilyEmptyState extends StatelessWidget {
  const FamilyEmptyState({
    super.key,
    required this.devices,
    required this.filtered,
    this.onAdd,
    this.onClear,
  });
  final bool devices, filtered;
  final VoidCallback? onAdd, onClear;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 34, 12, 28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: SizedBox(
            width: 230,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 14,
                  left: 15,
                  child: Container(
                    width: 196,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E8),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
                Container(
                  width: 124,
                  height: 124,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFF0F4F7)],
                    ),
                    border: Border.all(
                      color: const Color(0xFFFFF0E7),
                      width: 4,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0CFF681D), blurRadius: 20),
                    ],
                  ),
                  child: Icon(
                    filtered
                        ? Icons.search_rounded
                        : devices
                        ? Icons.phone_android_rounded
                        : Icons.child_care_rounded,
                    size: 49,
                    color: const Color(0xFF8D938E),
                  ),
                ),
                const Positioned(
                  right: 0,
                  top: 8,
                  child: Icon(
                    Icons.send_rounded,
                    size: 31,
                    color: Color(0xFFFFA073),
                  ),
                ),
                const Positioned(
                  left: 10,
                  top: 42,
                  child: Icon(
                    Icons.cloud_rounded,
                    size: 36,
                    color: Color(0xFFFFEEE6),
                  ),
                ),
                const Positioned(
                  left: 54,
                  top: 0,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 19,
                    color: Color(0xFFFF9E71),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          filtered
              ? 'No matching ${devices ? 'devices' : 'children'}'
              : devices
              ? 'No Devices Found'
              : 'No Children Found',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 23,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: -.6,
            color: familyInk,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Text(
            filtered
                ? 'Try another name or clear your search.'
                : devices
                ? 'Add a device profile to manage device settings and link to your children.'
                : 'Add your children to start supervising their digital well-being.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: familyMuted,
            ),
          ),
        ),
        if (filtered && onClear != null) ...[
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Clear search'),
          ),
        ] else if (onAdd != null) ...[
          const SizedBox(height: 22),
          FamilyAddButton(devices: devices, onPressed: onAdd),
        ],
      ],
    ),
  );
}

class FamilyAddButton extends StatelessWidget {
  const FamilyAddButton({
    super.key,
    required this.devices,
    required this.onPressed,
  });
  final bool devices;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        colors: [Color(0xFFFF771B), Color(0xFFF0580C), Color(0xFFFF8841)],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x24FF681D),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        minimumSize: const Size(190, 50),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      icon: Icon(
        devices ? Icons.add_rounded : Icons.person_add_alt_1_rounded,
        size: 23,
      ),
      label: Text(
        'Add ${devices ? 'Device' : 'Child'}',
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class FamilyRecordCard extends StatelessWidget {
  const FamilyRecordCard({
    super.key,
    required this.devices,
    required this.title,
    required this.status,
    required this.detail,
    required this.inactive,
    required this.onTap,
    required this.menu,
  });
  final bool devices, inactive;
  final String title, status, detail;
  final VoidCallback onTap;
  final Widget menu;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFFFEDE1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 6, 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  devices
                      ? Icons.phone_android_rounded
                      : Icons.child_care_rounded,
                  color: familyOrange,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: familyInk,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: inactive
                                ? const Color(0xFFFFE9E6)
                                : const Color(0xFFECF8F1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: inactive
                                  ? const Color(0xFFBE3327)
                                  : const Color(0xFF27815D),
                            ),
                          ),
                        ),
                        Text(
                          detail,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: familyMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              menu,
            ],
          ),
        ),
      ),
    ),
  );
}
