import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FamilyMapAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FamilyMapAppBar({
    super.key,
    required this.canAddDevice,
    required this.busy,
    required this.onRefresh,
    required this.onPairDevice,
    this.height = 80,
    this.locationName = 'Family location',
    this.onNotifications,
  });
  final double height;
  final bool canAddDevice, busy;
  final VoidCallback onRefresh, onPairDevice;
  final VoidCallback? onNotifications;
  final String locationName;
  @override
  Size get preferredSize => Size.fromHeight(height);
  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    toolbarHeight: height,
    titleSpacing: 12,
    title: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VatsalyaEmblem(size: 28),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Vatsalya',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF101329),
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -.8,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFFFF5715),
                      size: 14,
                    ),
                    Flexible(
                      child: Text(
                        locationName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF535A6C),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: CircleAvatar(
          radius: 23,
          backgroundColor: Colors.white,
          child: IconButton(
            tooltip: 'Notifications',
            onPressed: onNotifications ?? onRefresh,
            icon: const Icon(
              Icons.notifications_rounded,
              color: Color(0xFF626878),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white,
          child: IconButton(
            tooltip: 'Profile',
            onPressed: () => context.push('/account'),
            icon: const Icon(
              Icons.person_rounded,
              color: Color(0xFF626878),
              size: 28,
            ),
          ),
        ),
      ),
    ],
  );
}

class VatsalyaEmblem extends StatelessWidget {
  const VatsalyaEmblem({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _VatsalyaLogoPainter()),
    );
  }
}

class _VatsalyaLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 32.0;
    canvas.save();
    canvas.scale(scale, scale);

    final orangePaint = Paint()
      ..color = const Color(0xFFFF5722)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Adult head
    canvas.drawCircle(const Offset(11, 8.5), 3.2, orangePaint);

    // Child head
    canvas.drawCircle(const Offset(21, 12), 2.6, orangePaint);

    // Adult torso & arm embracing child forming heart contour
    final path = Path();
    path.moveTo(6.5, 13);
    path.cubicTo(4, 18, 5, 23.5, 16, 28);
    path.cubicTo(27, 23.5, 28, 18, 25.5, 13);
    path.cubicTo(23.5, 9.5, 19, 10, 16, 13.5);
    path.cubicTo(13, 10, 8.5, 9.5, 6.5, 13);
    path.close();

    // Inner cutout to define the figures
    final innerCutout = Path();
    innerCutout.moveTo(16, 17.5);
    innerCutout.cubicTo(14.5, 15, 12, 14.5, 10.5, 16);
    innerCutout.cubicTo(9, 18, 9.5, 21, 16, 25.5);
    innerCutout.cubicTo(22.5, 21, 23, 18, 21.5, 16);
    innerCutout.cubicTo(20, 14.5, 17.5, 15, 16, 17.5);
    innerCutout.close();

    final figureShape = Path.combine(
      PathOperation.difference,
      path,
      innerCutout,
    );

    canvas.drawPath(figureShape, orangePaint);

    // Small heart in center
    final heartPath = Path();
    heartPath.moveTo(16, 18.5);
    heartPath.cubicTo(15, 17, 13.5, 17, 13.5, 18.2);
    heartPath.cubicTo(13.5, 19.5, 16, 21.5, 16, 21.5);
    heartPath.cubicTo(16, 21.5, 18.5, 19.5, 18.5, 18.2);
    heartPath.cubicTo(18.5, 17, 17, 17, 16, 18.5);
    heartPath.close();

    canvas.drawPath(heartPath, orangePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
