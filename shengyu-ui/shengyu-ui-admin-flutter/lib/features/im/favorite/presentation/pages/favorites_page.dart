import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_strings.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/favorite_detail_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/domain/entities/favorite_item.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/presentation/providers/favorite_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/presentation/states/favorites_state.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_empty_view.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_error_view.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_loading_view.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/primary_page_scaffold.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  static const _tabs = ['default', 'normal', 'media', 'file'];

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(favoritesControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final state = ref.watch(favoritesControllerProvider);
    final tabLabels = [
      strings.favoriteTabDefault,
      strings.favoriteTabNormal,
      strings.favoriteTabMedia,
      strings.favoriteTabFile,
    ];

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: switch (state.status) {
        FavoritesStatus.initial ||
        FavoritesStatus.loading => const AppLoadingView(),
        FavoritesStatus.failed => AppErrorView(
          error: state.error,
          onRetry: () => ref.read(favoritesControllerProvider.notifier).load(),
        ),
        FavoritesStatus.ready => PrimaryPageScaffold(
          title: strings.favoritePageTitle,
          searchBar: PrimarySearchBar(
            hintText: state.keyword.isEmpty
                ? strings.favoriteSearchPlaceholder
                : state.keyword,
            onTap: () => _showSearchSheet(context, state.keyword),
          ),
          body: Column(
            children: [
              SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final selected = state.tab == _tabs[index];
                    return ChoiceChip(
                      label: Text(tabLabels[index]),
                      selected: selected,
                      onSelected: (_) {
                        ref
                            .read(favoritesControllerProvider.notifier)
                            .updateTab(_tabs[index]);
                      },
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemCount: _tabs.length,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      ref.read(favoritesControllerProvider.notifier).refresh(),
                  child: state.items.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            AppEmptyView(message: strings.favoritePageEmpty),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: state.items.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = state.items[index];
                            return _FavoriteCard(
                              favoriteCancelAction:
                                  strings.favoriteCancelAction,
                              favoriteTypeFallback: strings.favoriteTabNormal,
                              item: item,
                              onTap: () => _openFavorite(item),
                              onRemove: () => _removeFavorite(item),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      },
    );
  }

  Future<void> _showSearchSheet(BuildContext context, String keyword) async {
    final strings = ref.read(appStringsProvider);
    final controller = TextEditingController(text: keyword);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: strings.favoriteSearchPlaceholder,
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                  onSubmitted: (value) async {
                    Navigator.of(sheetContext).pop();
                    await ref
                        .read(favoritesControllerProvider.notifier)
                        .updateKeyword(value.trim());
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await ref
                          .read(favoritesControllerProvider.notifier)
                          .updateKeyword(controller.text.trim());
                    },
                    child: Text(strings.confirmAction),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFavorite(FavoriteItem item) {
    if (item.favoriteId.isEmpty || item.favoriteId == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(appStringsProvider).favoriteOpenFailed),
        ),
      );
      return;
    }
    context.pushNamed(
      RouteNames.favoriteDetail,
      extra: FavoriteDetailRouteArgs(favoriteId: item.favoriteId),
    );
  }

  Future<void> _removeFavorite(FavoriteItem item) async {
    final strings = ref.read(appStringsProvider);
    try {
      await ref.read(favoritesControllerProvider.notifier).removeFavorite(item);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.favoriteCancelSuccess)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.favoriteCancelAction,
    required this.favoriteTypeFallback,
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  final String favoriteCancelAction;
  final String favoriteTypeFallback;
  final FavoriteItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final timeText = DateFormat('MM-dd HH:mm').format(item.createdAt);
    final statusLabel = _favoriteStatusLabel(strings, item.status);
    final unavailable = _isUnavailableFavorite(item);
    final isGroupConversation = item.conversationType == ConversationType.group;
    final senderName = item.senderName.trim();
    final displayTitle = item.title.trim().isNotEmpty
        ? item.title.trim()
        : (senderName.isNotEmpty ? senderName : item.chatId);
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: unavailable ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isGroupConversation
                      ? const Color(0xFFFFF1DF)
                      : const Color(0xFFEEF3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isGroupConversation
                      ? Icons.groups_2_outlined
                      : Icons.star_outline_rounded,
                  color: isGroupConversation
                      ? const Color(0xFFFF9C2F)
                      : const Color(0xFF246BFD),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: unavailable
                                  ? const Color(0xFF8F96A3)
                                  : const Color(0xFF202531),
                            ),
                          ),
                        ),
                        if (statusLabel != null) ...[
                          const SizedBox(width: 8),
                          _FavoriteStatusChip(label: statusLabel),
                        ],
                        const SizedBox(width: 8),
                        Text(
                          timeText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF98A1B2),
                          ),
                        ),
                      ],
                    ),
                    if (senderName.isNotEmpty &&
                        senderName != displayTitle) ...[
                      const SizedBox(height: 4),
                      Text(
                        senderName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF98A1B2),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      item.summary.isEmpty
                          ? (item.messageType.isEmpty
                                ? favoriteTypeFallback
                                : item.messageType)
                          : item.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: unavailable
                            ? const Color(0xFF98A1B2)
                            : const Color(0xFF4E5666),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'remove') {
                    onRemove();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'remove',
                    child: Text(favoriteCancelAction),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteStatusChip extends StatelessWidget {
  const _FavoriteStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8F96A3),
        ),
      ),
    );
  }
}

bool _isUnavailableFavorite(FavoriteItem item) {
  final status = item.status.trim().toLowerCase();
  if (status.isEmpty) {
    return false;
  }
  return status.contains('delete') ||
      status.contains('removed') ||
      status.contains('recall') ||
      status.contains('invalid') ||
      status.contains('unavailable');
}

String? _favoriteStatusLabel(AppLocalizations strings, String status) {
  final normalized = status.trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }
  if (normalized.contains('recall')) {
    return strings.favoriteStatusRecalled;
  }
  if (normalized.contains('delete') || normalized.contains('removed')) {
    return strings.favoriteStatusDeleted;
  }
  if (normalized.contains('invalid') || normalized.contains('unavailable')) {
    return strings.favoriteStatusUnavailable;
  }
  return null;
}
