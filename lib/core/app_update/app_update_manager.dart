import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_update.dart';

/// One declarative update surface above the existing router: no stacked routes.
class AppUpdateManager extends ConsumerStatefulWidget {
  const AppUpdateManager({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<AppUpdateManager> createState() => _AppUpdateManagerState();
}

class _AppUpdateManagerState extends ConsumerState<AppUpdateManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(ref.read(appUpdateProvider).check());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(appUpdateProvider).check(returnedFromStore: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appUpdateProvider);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final update = controller.update;
        return PopScope(
          canPop: !controller.visible,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !controller.blocked) controller.later();
          },
          child: Stack(
            children: [
              ExcludeSemantics(
                excluding: controller.visible,
                child: IgnorePointer(
                  ignoring: controller.visible,
                  child: ExcludeFocus(
                    excluding: controller.visible,
                    child: widget.child,
                  ),
                ),
              ),
              if (update != null && update.available)
                Positioned.fill(
                  child: Material(
                    color: controller.blocked
                        ? Theme.of(context).colorScheme.surface
                        : Colors.black54,
                    child: SafeArea(
                      child: Stack(
                        children: [
                          if (!controller.blocked)
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: controller.later,
                                behavior: HitTestBehavior.opaque,
                              ),
                            ),
                          Center(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.95, end: 1),
                              duration: const Duration(milliseconds: 220),
                              builder: (context, value, child) =>
                                  Transform.scale(scale: value, child: child),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 480,
                                  ),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(24),
                                      child: UpdateContent(
                                        controller: controller,
                                        update: update,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class UpdateContent extends StatelessWidget {
  const UpdateContent({
    super.key,
    required this.controller,
    required this.update,
  });
  final AppUpdateController controller;
  final AppUpdate update;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: update.mandatory ? 'Required app update' : 'App update available',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.system_update_rounded,
              size: 36,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            update.mandatory
                ? 'An update is required'
                : 'A fresh update is ready',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            update.mandatory
                ? 'Update Vatsalya Guard to keep using supported family safety features.'
                : 'Get the latest improvements for your family.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Installed ${update.installed}')),
              Chip(label: Text('Latest ${update.latest}')),
            ],
          ),
          if (update.notes?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Text('What’s new', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(
              update.notes!,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
          if (controller.error != null) ...[
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                controller.error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (controller.updateStatus != null) ...[
            Text(controller.updateStatus!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
          ],
          if (controller.launching && controller.apkUpdater != null) ...[
            LinearProgressIndicator(value: controller.downloadProgress),
            const SizedBox(height: 8),
            if (controller.downloadProgress != null)
              Text(
                '${(controller.downloadProgress! * 100).round()}%',
                textAlign: TextAlign.center,
              ),
            TextButton(
              onPressed: controller.cancelDownload,
              child: const Text('Cancel download'),
            ),
          ],
          FilledButton.icon(
            onPressed: controller.launching || controller.checking
                ? null
                : controller.openUpdate,
            icon: controller.launching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.open_in_new_rounded),
            label: Text(controller.launching ? 'Please wait…' : 'Update Now'),
          ),
          if (update.mandatory || controller.error != null)
            TextButton(
              onPressed: controller.checking || controller.launching
                  ? null
                  : () => controller.check(manual: true),
              child: Text(
                controller.checking ? 'Checking…' : 'Retry update check',
              ),
            ),
          if (!update.mandatory)
            TextButton(
              onPressed: controller.launching ? null : controller.later,
              child: const Text('Later'),
            ),
        ],
      ),
    );
  }
}
