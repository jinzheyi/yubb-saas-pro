import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_search_item.dart';

class LocationSearchResult {
  const LocationSearchResult({
    required this.enabled,
    required this.message,
    required this.items,
  });

  final bool enabled;
  final String message;
  final List<LocationSearchItem> items;
}
