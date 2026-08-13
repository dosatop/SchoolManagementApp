import 'package:app/core/storage/storage_service.dart';
import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:app/features/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dio_client.dart';

final secureStorageProvider = Provider((ref) {
  return StorageService();
});

final routerProvider = Provider<GoRouter>((ref) {
  final router = appRouter(ref);

  ref.listen<AsyncValue<AuthState>>(authProvider, (_, __) {
    router.refresh();
  });

  ref.onDispose(router.dispose);

  return router;
});

final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.read(secureStorageProvider);

  return DioClient(storage, () async {
    await ref.read(authProvider.notifier).logout();
  });
});
