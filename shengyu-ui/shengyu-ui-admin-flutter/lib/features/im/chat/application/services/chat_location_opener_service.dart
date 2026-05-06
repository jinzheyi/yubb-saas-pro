import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class ChatLocationOpenerService {
  Future<bool> open({
    required double latitude,
    required double longitude,
    String? name,
    String? address,
  });
}

class UrlLauncherChatLocationOpenerService
    implements ChatLocationOpenerService {
  const UrlLauncherChatLocationOpenerService();

  @override
  Future<bool> open({
    required double latitude,
    required double longitude,
    String? name,
    String? address,
  }) async {
    if (latitude.isNaN || longitude.isNaN) {
      return false;
    }
    final trimmedName = name?.trim() ?? '';
    final trimmedAddress = address?.trim() ?? '';
    final candidates = _buildCandidates(
      latitude: latitude,
      longitude: longitude,
      name: trimmedName,
      address: trimmedAddress,
    );
    for (final uri in candidates) {
      if (await launchUrl(uri, mode: LaunchMode.platformDefault)) {
        return true;
      }
    }
    return false;
  }

  List<Uri> _buildCandidates({
    required double latitude,
    required double longitude,
    required String name,
    required String address,
  }) {
    final coordinate = '$latitude,$longitude';
    final safeLabel = name.isNotEmpty ? name : coordinate;
    final tencentMarker = <String, String>{
      'marker': 'coord:$coordinate;title:$safeLabel;addr:$address',
    };
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return [
          Uri.parse(
            'geo:$coordinate?q=$coordinate(${Uri.encodeComponent(safeLabel)})',
          ),
          Uri.https('apis.map.qq.com', '/uri/v1/marker', tencentMarker),
        ];
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return [
          Uri.https('maps.apple.com', '/', <String, String>{
            'll': coordinate,
            'q': safeLabel,
          }),
          Uri.https('apis.map.qq.com', '/uri/v1/marker', tencentMarker),
        ];
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return [Uri.https('apis.map.qq.com', '/uri/v1/marker', tencentMarker)];
    }
  }
}
