import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import 'dashboard_reference_widgets.dart';
import '../../../../data/models/pairing_code.dart';
import '../../../widgets/provisioning_sheet.dart';

class PairingCard extends StatelessWidget {
  const PairingCard({super.key, required this.codes});
  final List<PairingCode> codes;
  @override
  Widget build(BuildContext context) {
    final activeCount = codes.where((code) => code.isActive).length;
    return DashboardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked =
                  constraints.maxWidth < 380 &&
                  MediaQuery.textScalerOf(context).scale(12) > 17;
              final badge = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: activeCount > 0
                      ? AppColors.onlineTint
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: activeCount > 0
                        ? AppColors.online.withValues(alpha: 0.25)
                        : AppColors.cardBorder,
                  ),
                ),
                child: Text(
                  '$activeCount active',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: activeCount > 0
                        ? AppColors.onlineDark
                        : AppColors.muted,
                  ),
                ),
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1DE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: dashboardOrange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Pair a child device',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.2,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      if (!stacked) badge,
                    ],
                  ),
                  if (stacked) ...[const SizedBox(height: 10), badge],
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          const Text(
            'Generate QR pairing codes to connect new child phones and tablets to your family workspace.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          DashboardOrangeButton(
            onPressed: () => context.push('/pairing'),
            icon: Icons.qr_code_2,
            label: 'Manage pairing codes',
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFF5E5DA)),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => showProvisioningSheet(context),
            icon: const Icon(Icons.security, size: 16),
            label: const Text('Hardware protection setup guide'),
          ),
        ],
      ),
    );
  }
}
