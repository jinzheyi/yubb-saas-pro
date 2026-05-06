import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/location_search_item_dto.dart';

class LocationSearchResultDto {
  const LocationSearchResultDto({
    required this.enabled,
    required this.message,
    required this.items,
  });

  final bool enabled;
  final String message;
  final List<LocationSearchItemDto> items;
}
