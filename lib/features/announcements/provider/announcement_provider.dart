import 'package:app/core/network/dio_client.dart';
import 'package:app/core/network/dio_provider.dart';
import 'package:app/features/announcements/models/announcement_model.dart';

import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ====================================================================
// API
// ====================================================================
// Backend: AnnouncementsController (api/announcements) and
// DevicesController (api/devices).

class AnnouncementApi {
  AnnouncementApi(this.dioClient);

  final DioClient dioClient;

  Future<AnnouncementPage> getFeed({
    int page = 1,
    int pageSize = 20,
    bool unreadOnly = false,
    bool mine = false,
  }) async {
    final response = await dioClient.dio.get(
      '/announcements',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'unreadOnly': unreadOnly,
        'mine': mine,
      },
    );
    return AnnouncementPage.fromJson(response.data);
  }

  Future<AnnouncementModel> getOne(String id) async {
    final response = await dioClient.dio.get('/announcements/$id');
    return AnnouncementModel.fromJson(response.data);
  }

  Future<int> getUnreadCount() async {
    final response = await dioClient.dio.get('/announcements/unread-count');
    final data = response.data;
    final v = data is Map ? (data['unreadCount'] ?? data['UnreadCount']) : data;
    return v is num ? v.toInt() : int.tryParse('$v') ?? 0;
  }

  Future<int> markRead(String id) async {
    final response = await dioClient.dio.post('/announcements/$id/read');
    final v = response.data is Map ? response.data['unreadCount'] : null;
    return v is num ? v.toInt() : 0;
  }

  Future<void> markAllRead() async {
    await dioClient.dio.post('/announcements/read-all');
  }

  Future<ComposeOptions> getComposeOptions() async {
    final response = await dioClient.dio.get('/announcements/compose-options');
    return ComposeOptions.fromJson(response.data);
  }

  /// Returns the server's message, e.g. "…sent to 42 people."
  Future<String> create({
    required String title,
    required String body,
    required int audience,
    required int priority,
    String? schoolId,
    String? classId,
    bool isPinned = false,
    DateTime? expiresAt,
    bool sendPush = true,
  }) async {
    final response = await dioClient.dio.post(
      '/announcements',
      data: {
        'title': title,
        'body': body,
        'audience': audience,
        'priority': priority,
        'schoolId': schoolId,
        'classId': classId,
        'isPinned': isPinned,
        'expiresAt': expiresAt?.toUtc().toIso8601String(),
        'sendPush': sendPush,
      },
    );
    final data = response.data;
    return data is Map && data['message'] != null
        ? '${data['message']}'
        : 'Announcement posted';
  }

  Future<void> update(
    String id, {
    required String title,
    required String body,
    required int priority,
    bool isPinned = false,
    DateTime? expiresAt,
    bool resendPush = false,
  }) async {
    await dioClient.dio.put(
      '/announcements/$id',
      data: {
        'title': title,
        'body': body,
        'priority': priority,
        'isPinned': isPinned,
        'expiresAt': expiresAt?.toUtc().toIso8601String(),
        'resendPush': resendPush,
      },
    );
  }

  Future<void> delete(String id) async {
    await dioClient.dio.delete('/announcements/$id');
  }

  // ---- push devices --------------------------------------------------

  Future<void> registerDevice(String token, String platform) async {
    await dioClient.dio.post(
      '/devices',
      data: {'token': token, 'platform': platform},
    );
  }

  Future<void> unregisterDevice(String token) async {
    await dioClient.dio.delete('/devices/${Uri.encodeComponent(token)}');
  }
}

final announcementApiProvider = Provider<AnnouncementApi>((ref) {
  return AnnouncementApi(ref.read(dioClientProvider));
});

/// True for any signed-in user. Watching auth means every provider
/// below reloads on login / logout (and never calls the API logged out).
bool _signedIn(Ref ref) =>
    ref.watch(authProvider).valueOrNull?.isAuthenticated ?? false;

/// Roles that can post.
bool canPostAnnouncements(String? role) =>
    role == 'SuperAdmin' || role == 'Admin' || role == 'Teacher';

// ====================================================================
// UNREAD COUNT (bell badge)
// ====================================================================

final unreadAnnouncementsProvider =
    AsyncNotifierProvider<UnreadAnnouncementsNotifier, int>(
      UnreadAnnouncementsNotifier.new,
    );

class UnreadAnnouncementsNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    if (!_signedIn(ref)) return 0;
    try {
      return await ref.read(announcementApiProvider).getUnreadCount();
    } catch (_) {
      return 0; // a badge should never show an error
    }
  }

  void set(int value) => state = AsyncData(value < 0 ? 0 : value);

  Future<void> refresh() async {
    if (!_signedInRead()) return;
    try {
      set(await ref.read(announcementApiProvider).getUnreadCount());
    } catch (_) {}
  }

  bool _signedInRead() =>
      ref.read(authProvider).valueOrNull?.isAuthenticated ?? false;
}

// ====================================================================
// FEED (one per filter: all / unread / mine), with "load more"
// ====================================================================

enum AnnouncementFilter { all, unread, mine }

class AnnouncementFeed {
  final List<AnnouncementModel> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;

  const AnnouncementFeed({
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.loadingMore = false,
  });

  AnnouncementFeed copyWith({
    List<AnnouncementModel>? items,
    int? page,
    bool? hasMore,
    bool? loadingMore,
  }) => AnnouncementFeed(
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

final announcementFeedProvider = AsyncNotifierProvider.family<
  AnnouncementFeedNotifier,
  AnnouncementFeed,
  AnnouncementFilter
>(AnnouncementFeedNotifier.new);

class AnnouncementFeedNotifier
    extends FamilyAsyncNotifier<AnnouncementFeed, AnnouncementFilter> {
  static const _pageSize = 20;

  @override
  Future<AnnouncementFeed> build(AnnouncementFilter filter) async {
    if (!_signedIn(ref)) return const AnnouncementFeed();
    return _load(1, const []);
  }

  Future<AnnouncementFeed> _load(
    int page,
    List<AnnouncementModel> existing,
  ) async {
    final result = await ref
        .read(announcementApiProvider)
        .getFeed(
          page: page,
          pageSize: _pageSize,
          unreadOnly: arg == AnnouncementFilter.unread,
          mine: arg == AnnouncementFilter.mine,
        );

    ref.read(unreadAnnouncementsProvider.notifier).set(result.unreadCount);

    return AnnouncementFeed(
      items: [...existing, ...result.items],
      page: result.page,
      hasMore: result.hasMore,
    );
  }

  /// Pull-to-refresh: keeps the list on screen while reloading.
  Future<void> refresh() async {
    state = const AsyncLoading<AnnouncementFeed>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _load(1, const []));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;

    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      state = AsyncData(await _load(current.page + 1, current.items));
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }

  /// Local update after marking read (no reload, no flash).
  void markLocal(String id) {
    final current = state.valueOrNull;
    if (current == null) return;

    final items = arg == AnnouncementFilter.unread
        ? current.items.where((a) => a.id != id).toList()
        : current.items
              .map((a) => a.id == id ? a.copyWith(isRead: true) : a)
              .toList();

    state = AsyncData(current.copyWith(items: items));
  }

  void markAllLocal() {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        items: arg == AnnouncementFilter.unread
            ? const []
            : current.items.map((a) => a.copyWith(isRead: true)).toList(),
      ),
    );
  }
}

/// One announcement (details page opened from a push notification).
final announcementProvider = FutureProvider.autoDispose
    .family<AnnouncementModel, String>((ref, id) async {
      if (!_signedIn(ref)) throw Exception('Please sign in.');
      return ref.read(announcementApiProvider).getOne(id);
    });

final composeOptionsProvider = FutureProvider.autoDispose<ComposeOptions>((
  ref,
) async {
  if (!_signedIn(ref)) throw Exception('Please sign in.');
  return ref.read(announcementApiProvider).getComposeOptions();
});

// ====================================================================
// ACTIONS — each returns null on success or a message to show
// ====================================================================

final announcementActionsProvider = Provider<AnnouncementActions>(
  AnnouncementActions.new,
);

class AnnouncementActions {
  AnnouncementActions(this._ref);

  final Ref _ref;

  AnnouncementApi get _api => _ref.read(announcementApiProvider);

  void _reloadFeeds() {
    for (final f in AnnouncementFilter.values) {
      _ref.invalidate(announcementFeedProvider(f));
    }
    _ref.read(unreadAnnouncementsProvider.notifier).refresh();
  }

  Future<void> markRead(AnnouncementModel a) async {
    if (a.isRead || a.isMine) return;

    for (final f in AnnouncementFilter.values) {
      if (_ref.exists(announcementFeedProvider(f))) {
        _ref.read(announcementFeedProvider(f).notifier).markLocal(a.id);
      }
    }

    final unread = _ref.read(unreadAnnouncementsProvider).valueOrNull ?? 0;
    _ref.read(unreadAnnouncementsProvider.notifier).set(unread - 1);

    try {
      final serverCount = await _api.markRead(a.id);
      _ref.read(unreadAnnouncementsProvider.notifier).set(serverCount);
    } catch (_) {
      // Not critical — it'll sync on the next refresh.
    }
  }

  Future<String?> markAllRead() async {
    try {
      await _api.markAllRead();
    } catch (e) {
      return announcementError(e);
    }

    for (final f in AnnouncementFilter.values) {
      if (_ref.exists(announcementFeedProvider(f))) {
        _ref.read(announcementFeedProvider(f).notifier).markAllLocal();
      }
    }
    _ref.read(unreadAnnouncementsProvider.notifier).set(0);
    return null;
  }

  /// Returns (error, successMessage).
  Future<(String?, String?)> create({
    required String title,
    required String body,
    required int audience,
    required int priority,
    String? schoolId,
    String? classId,
    bool isPinned = false,
    DateTime? expiresAt,
    bool sendPush = true,
  }) async {
    try {
      final message = await _api.create(
        title: title,
        body: body,
        audience: audience,
        priority: priority,
        schoolId: schoolId,
        classId: classId,
        isPinned: isPinned,
        expiresAt: expiresAt,
        sendPush: sendPush,
      );
      _reloadFeeds();
      return (null, message);
    } catch (e) {
      return (announcementError(e), null);
    }
  }

  Future<String?> update(
    String id, {
    required String title,
    required String body,
    required int priority,
    bool isPinned = false,
    DateTime? expiresAt,
    bool resendPush = false,
  }) async {
    try {
      await _api.update(
        id,
        title: title,
        body: body,
        priority: priority,
        isPinned: isPinned,
        expiresAt: expiresAt,
        resendPush: resendPush,
      );
    } catch (e) {
      return announcementError(e);
    }
    _reloadFeeds();
    _ref.invalidate(announcementProvider(id));
    return null;
  }

  Future<String?> delete(String id) async {
    try {
      await _api.delete(id);
    } catch (e) {
      return announcementError(e);
    }
    _reloadFeeds();
    return null;
  }
}

// ====================================================================
// FRIENDLY ERROR
// ====================================================================

String announcementError(Object error) {
  try {
    final data = (error as dynamic).response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['Message'];
      if (message != null && '$message'.trim().isNotEmpty) return '$message';

      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        return first is List && first.isNotEmpty ? '${first.first}' : '$first';
      }
    }
    final status = (error as dynamic).response?.statusCode;
    if (status == 404) return 'Announcement not found.';
    if (status == 403) return "You don't have permission to do this.";
  } catch (_) {}

  final text = error.toString().replaceFirst('Exception: ', '').trim();
  if (text.isEmpty || text.contains('DioException')) {
    return 'Something went wrong. Check your connection and try again.';
  }
  return text;
}
