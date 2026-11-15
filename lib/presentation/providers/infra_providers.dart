import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/token_storage.dart';
import '../../data/local/children_snapshot_cache.dart';
import '../../data/remote/api_client.dart';
import '../../data/remote/realtime_gateway.dart';
import '../../data/remote/parent_push_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/parents_repository.dart';
import '../../data/repositories/workspace_repository.dart';
import 'session_provider.dart';

/// Infrastructure providers (storage, API client, repositories, realtime).
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
final childrenSnapshotCacheProvider = Provider<ChildrenSnapshotCache>(
  (ref) => ChildrenSnapshotCache(),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(
    tokenProvider: () => storage.readToken(),
    onUnauthorized: () =>
        ref.read(sessionProvider.notifier).handleUnauthorized(),
    sessionRevision: () => ref.read(sessionProvider.notifier).revision,
  );
});

final workspaceRepositoryProvider = Provider<WorkspaceRepository>(
  (ref) => WorkspaceRepository(ref.watch(apiClientProvider)),
);
final parentPushProvider = Provider<ParentPushService>((ref) {
  final service = ParentPushService(ref.watch(workspaceRepositoryProvider));
  ref.onDispose(service.dispose);
  return service;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final parentsRepositoryProvider = Provider<ParentsRepository>((ref) {
  return ParentsRepository(apiClient: ref.watch(apiClientProvider));
});

final realtimeGatewayProvider = Provider<RealtimeGateway>((ref) {
  final gateway = RealtimeGateway(ref.watch(tokenStorageProvider));
  ref.onDispose(gateway.dispose);
  return gateway;
});

/// Stream of decoded realtime frames.
final realtimeStreamProvider = StreamProvider<RealtimeEvent>((ref) {
  return ref.watch(realtimeGatewayProvider).stream;
});
