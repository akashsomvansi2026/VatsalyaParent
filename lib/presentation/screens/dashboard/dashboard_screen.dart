import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/status_views.dart';
import '../../../data/remote/realtime_gateway.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/infra_providers.dart';
import '../../providers/session_provider.dart';
import 'widgets/dashboard_reference_widgets.dart';
import 'widgets/dashboard_widgets.dart';
import 'widgets/pairing_card.dart';

/// Home dashboard: stats, SOS banner, pairing codes and children grid.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(dashboardProvider);
      if (!state.hasData && !state.isLoading) {
        ref.read(dashboardProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Real-time event dispatch (mirrors the portal's `useRealtime` hook on the
    // Dashboard page).
    ref.listen<AsyncValue<RealtimeEvent>>(realtimeStreamProvider, (prev, next) {
      final event = next.value;
      if (event == null) return;
      if (event.type == 'location') {
        ref
            .read(dashboardProvider.notifier)
            .applyLocationPatch(
              event.childId,
              ((event.data['location'] as Map?)?['batteryLevel'] as num?)
                  ?.toInt(),
            );
      } else {
        ref.read(dashboardProvider.notifier).reloadFromEvent(event.type);
      }
    });

    final state = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
            child: _buildBody(context, state),
          ),
          if (state.isRefreshing && state.hasData)
            const Positioned(
              top: 8,
              right: 16,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, DashboardState state) {
    if (state.isLoading && !state.hasData) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          LoadingView(message: 'Loading dashboard…'),
        ],
      );
    }
    if (state.error != null && !state.hasData) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          ErrorView(
            message: state.error!,
            onRetry: () => ref.read(dashboardProvider.notifier).load(),
          ),
        ],
      );
    }

    final data = state.data ?? const DashboardData();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        DashboardReferenceHeader(
          refreshing: state.isRefreshing,
          onRefresh: state.isRefreshing
              ? null
              : () => ref.read(dashboardProvider.notifier).refresh(),
        ),
        ResponsiveContent(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardGreeting(
                  parent: ref.watch(sessionProvider).parent,
                  status: state.error != null
                      ? 'Some data could not be updated'
                      : data.activeSosCount > 0
                      ? '${data.activeSosCount} active SOS alerts'
                      : ref.watch(sessionProvider).parent?.can('sos.view') ==
                            true
                      ? 'No active SOS alerts'
                      : 'Your family workspace',
                  statusColor: state.error != null
                      ? AppColors.warning
                      : data.activeSosCount > 0
                      ? AppColors.sos
                      : AppColors.online,
                ),
                const SizedBox(height: 16),
                if (state.error != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(state.error!),
                    ),
                  ),
                if (data.activeSosCount > 0) ...[
                  SosBanner(events: data.sosEvents),
                  const SizedBox(height: 16),
                ],
                DashboardSectionHeading(
                  title: 'Safety overview',
                  action: 'View details',
                  onTap: () => context.push('/features'),
                ),
                const SizedBox(height: 12),
                _buildStats(data, state.isRefreshing),
                const SizedBox(height: 16),
                DashboardSectionHeading(
                  title: 'My children',
                  action: 'Manage',
                  onTap:
                      ref.watch(sessionProvider).parent?.can('child.view') ==
                          true
                      ? () => context.push('/family/children')
                      : null,
                ),
                const SizedBox(height: 12),
                if (data.children.isEmpty)
                  DashboardEmptyChildren(
                    onAdd:
                        ref
                                .watch(sessionProvider)
                                .parent
                                ?.can('child.create') ==
                            true
                        ? () => context.push('/family/children?create=true')
                        : null,
                  )
                else
                  _buildChildrenGrid(data),
                const SizedBox(height: 24),
                if (ref.watch(sessionProvider).parent?.can('device.add') ==
                    true)
                  PairingCard(codes: data.pairingCodes),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(DashboardData data, bool refreshing) {
    final account = ref.watch(sessionProvider).parent;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            MediaQuery.textScalerOf(context).scale(14) > 20 ||
                constraints.maxWidth < 330
            ? 1
            : constraints.maxWidth >= 900
            ? 4
            : 2;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        final metrics = [
          DashboardMetricCard(
            label: 'Children',
            value: '${data.children.length}',
            subtitle: 'Total paired children',
            icon: Icons.family_restroom_rounded,
            accent: dashboardOrange,
            onTap: account?.can('child.view') == true
                ? () => context.push('/family/children')
                : null,
          ),
          DashboardMetricCard(
            label: 'Online',
            value: '${data.onlineCount}',
            subtitle: 'Children online now',
            icon: Icons.circle,
            accent: const Color(0xFF00A66B),
            onTap: account?.can('location.view') == true
                ? () => context.go('/')
                : null,
          ),
          DashboardMetricCard(
            label: 'Active SOS',
            value: '${data.activeSosCount}',
            subtitle: 'SOS alerts',
            icon: Icons.warning_amber_rounded,
            accent: const Color(0xFFE83427),
            onTap: account?.can('sos.view') == true
                ? () => context.push('/sos')
                : null,
          ),
          DashboardMetricCard(
            label: 'Pairing codes',
            value: '${data.pairingCodes.length}',
            subtitle: 'Pairing codes',
            icon: Icons.qr_code_2_rounded,
            accent: const Color(0xFF5769FF),
            onTap: account?.can('device.add') == true
                ? () => context.push('/pairing')
                : null,
          ),
        ];
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final card in metrics) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }

  Widget _buildChildrenGrid(DashboardData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 560 &&
                MediaQuery.textScalerOf(context).scale(14) <= 20
            ? 2
            : 1;
        final cards = data.children.map((child) {
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push('/child/${child.id}'),
            child: ChildCard(child: child),
          );
        }).toList();

        if (columns == 1) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                cards[i],
              ],
            ],
          );
        }
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards)
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: card),
          ],
        );
      },
    );
  }
}
