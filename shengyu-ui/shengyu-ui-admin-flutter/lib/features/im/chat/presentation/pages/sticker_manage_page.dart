import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/sticker_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_empty_view.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_error_view.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_loading_view.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/primary_page_scaffold.dart';

class StickerManagePage extends ConsumerStatefulWidget {
  const StickerManagePage({super.key});

  @override
  ConsumerState<StickerManagePage> createState() => _StickerManagePageState();
}

class _StickerManagePageState extends ConsumerState<StickerManagePage> {
  static const int _limit = 150;

  bool _loading = true;
  bool _sortMode = false;
  bool _savingSort = false;
  String? _selectedStickerId;
  String? _error;
  List<StickerItem> _stickers = const <StickerItem>[];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const AppLoadingView()
        : _error != null
        ? AppErrorView(onRetry: _load)
        : _stickers.isEmpty
        ? ListView(
            children: const [
              SizedBox(height: 120),
              AppEmptyView(message: '还没有收藏的表情'),
            ],
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              children: [
                PrimarySectionCard(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '我的表情',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF202531),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_stickers.length}/$_limit',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF246BFD),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _summaryText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF98A1B2),
                        ),
                      ),
                      if (_sortMode && _selectedStickerId != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '已选中一个表情，点击其它表情可移动到目标位置。',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF246BFD),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedStickerId = null;
                                });
                              },
                              child: const Text('取消选择'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: _stickers.length,
                  itemBuilder: (context, index) {
                    final item = _stickers[index];
                    final selected = _selectedStickerId == item.stickerId;
                    return _StickerTile(
                      item: item,
                      selected: selected,
                      sortMode: _sortMode,
                      savingSort: _savingSort,
                      onTap: () => _handleStickerTap(item),
                      onLongPress: () => _removeStickerWithConfirm(item),
                      onRemove: () => _removeStickerWithConfirm(item),
                      onMoveTop: () => _moveStickerToIndex(index, 0),
                      onMoveLeft: () => _moveStickerToIndex(index, index - 1),
                      onMoveRight: () => _moveStickerToIndex(index, index + 1),
                      onMoveBottom: () =>
                          _moveStickerToIndex(index, _stickers.length - 1),
                      canMoveTop: index > 0,
                      canMoveBottom: index < _stickers.length - 1,
                    );
                  },
                ),
              ],
            ),
          );

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),
      appBar: AppBar(
        title: const Text('表情管理'),
        actions: [
          TextButton(
            onPressed: _loading || _savingSort
                ? null
                : () {
                    setState(() {
                      _sortMode = !_sortMode;
                      if (!_sortMode) {
                        _selectedStickerId = null;
                      }
                    });
                  },
            child: Text(_sortMode ? '完成' : '整理'),
          ),
        ],
      ),
      body: PrimaryPageScaffold(
        title: '表情管理',
        headerBottomSpacing: 8,
        body: body,
      ),
    );
  }

  String get _summaryText {
    if (!_sortMode) {
      return '长按可删除，进入整理后可调整顺序。';
    }
    if (_savingSort) {
      return '正在保存排序...';
    }
    if (_selectedStickerId != null) {
      return '已选中表情，可点击其它表情调整到目标位置。';
    }
    return '点击一个表情后，再点击目标位置完成排序。';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catalog = await ref
          .read(stickerRepositoryProvider)
          .getStickerCatalog();
      final favorites = [...catalog.favorites]
        ..sort((a, b) => (a.sortNo ?? 0).compareTo(b.sortNo ?? 0));
      if (!mounted) {
        return;
      }
      setState(() {
        _stickers = favorites;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _handleStickerTap(StickerItem item) async {
    if (!_sortMode || _savingSort) {
      return;
    }
    if (_selectedStickerId == null) {
      setState(() {
        _selectedStickerId = item.stickerId;
      });
      return;
    }
    if (_selectedStickerId == item.stickerId) {
      setState(() {
        _selectedStickerId = null;
      });
      return;
    }
    final sourceIndex = _stickers.indexWhere(
      (sticker) => sticker.stickerId == _selectedStickerId,
    );
    final targetIndex = _stickers.indexWhere(
      (sticker) => sticker.stickerId == item.stickerId,
    );
    if (sourceIndex < 0 || targetIndex < 0) {
      setState(() {
        _selectedStickerId = null;
      });
      return;
    }
    await _moveStickerToIndex(sourceIndex, targetIndex);
  }

  Future<void> _moveStickerToIndex(int sourceIndex, int targetIndex) async {
    if (_savingSort ||
        sourceIndex < 0 ||
        sourceIndex >= _stickers.length ||
        targetIndex < 0 ||
        targetIndex >= _stickers.length ||
        sourceIndex == targetIndex) {
      return;
    }
    final next = [..._stickers];
    final current = next.removeAt(sourceIndex);
    next.insert(targetIndex, current);
    final previous = _stickers;
    setState(() {
      _stickers = next;
      _savingSort = true;
      _selectedStickerId = null;
    });
    try {
      await ref
          .read(stickerRepositoryProvider)
          .sortSticker(
            items: [
              for (var index = 0; index < next.length; index++)
                (stickerId: next[index].stickerId, sortNo: index + 1),
            ],
          );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _stickers = previous;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _savingSort = false;
        });
      }
    }
  }

  Future<void> _removeStickerWithConfirm(StickerItem item) async {
    if (_savingSort) {
      return;
    }
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const AppIcon(
                  AppIconKind.delete,
                  size: 20,
                  color: Color(0xFF202531),
                ),
                title: const Text('删除表情'),
                onTap: () => Navigator.of(sheetContext).pop(true),
              ),
              ListTile(
                leading: const AppIcon(
                  AppIconKind.close,
                  size: 20,
                  color: Color(0xFF202531),
                ),
                title: const Text('取消'),
                onTap: () => Navigator.of(sheetContext).pop(false),
              ),
            ],
          ),
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    try {
      await ref
          .read(stickerRepositoryProvider)
          .removeSticker(stickerId: item.stickerId);
      if (!mounted) {
        return;
      }
      setState(() {
        _stickers = _stickers
            .where((sticker) => sticker.stickerId != item.stickerId)
            .toList();
        if (_selectedStickerId == item.stickerId) {
          _selectedStickerId = null;
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已删除表情')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _StickerTile extends StatelessWidget {
  const _StickerTile({
    required this.item,
    required this.selected,
    required this.sortMode,
    required this.savingSort,
    required this.onTap,
    required this.onLongPress,
    required this.onRemove,
    required this.onMoveTop,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onMoveBottom,
    required this.canMoveTop,
    required this.canMoveBottom,
  });

  final StickerItem item;
  final bool selected;
  final bool sortMode;
  final bool savingSort;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRemove;
  final VoidCallback onMoveTop;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;
  final VoidCallback onMoveBottom;
  final bool canMoveTop;
  final bool canMoveBottom;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF246BFD) : const Color(0xFFE6EBF2),
            width: selected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A162033),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: const BoxDecoration(color: Color(0xFFF4F6FA)),
                      child: Image.network(
                        item.url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: AppIcon(
                              AppIconKind.smile,
                              size: 26,
                              color: Color(0xFF98A1B2),
                            ),
                          );
                        },
                      ),
                    ),
                    if (sortMode)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: InkWell(
                          onTap: savingSort ? null : onRemove,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Color(0xAA202531),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'x',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (selected)
                      Positioned(
                        left: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF246BFD),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            '已选中',
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (sortMode) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _SortMiniButton(
                    label: '置顶',
                    enabled: canMoveTop && !savingSort,
                    onTap: onMoveTop,
                  ),
                  _SortMiniButton(
                    label: '左移',
                    enabled: canMoveTop && !savingSort,
                    onTap: onMoveLeft,
                  ),
                  _SortMiniButton(
                    label: '右移',
                    enabled: canMoveBottom && !savingSort,
                    onTap: onMoveRight,
                  ),
                  _SortMiniButton(
                    label: '置底',
                    enabled: canMoveBottom && !savingSort,
                    onTap: onMoveBottom,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SortMiniButton extends StatelessWidget {
  const _SortMiniButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 44,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF3F5F9) : const Color(0xFFF7F8FB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: enabled ? const Color(0xFF202531) : const Color(0xFFB2BAC7),
          ),
        ),
      ),
    );
  }
}
