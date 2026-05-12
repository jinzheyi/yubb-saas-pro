import 'package:shengyu_ui_admin_im/features/im/favorite/domain/entities/favorite_item.dart';

class FavoritePageResult {
  const FavoritePageResult({
    required this.items,
    required this.total,
    required this.hasMore,
  });

  final List<FavoriteItem> items;
  final int total;
  final bool hasMore;
}
