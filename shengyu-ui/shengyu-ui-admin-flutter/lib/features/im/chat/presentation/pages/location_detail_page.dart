import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_strings.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/services/chat_location_opener_service.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/map_view.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

/// 位置详情页面
/// 
/// 显示完整的地图和位置信息，支持拖动查看
class LocationDetailPage extends ConsumerStatefulWidget {
  final LocationSharePayload payload;

  const LocationDetailPage({
    super.key,
    required this.payload,
  });

  @override
  ConsumerState<LocationDetailPage> createState() => _LocationDetailPageState();
}

class _LocationDetailPageState extends ConsumerState<LocationDetailPage> {
  static const _locationOpener = UrlLauncherChatLocationOpenerService();

  bool _mapLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  void _onMapLoaded() {
    setState(() {
      _mapLoaded = true;
    });
  }

  /// 导航到第三方地图应用
  Future<void> _navigateToMap() async {
    final success = await _locationOpener.open(
      latitude: widget.payload.latitude,
      longitude: widget.payload.longitude,
      name: widget.payload.name,
      address: widget.payload.address,
    );
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法打开地图应用')),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(strings.chatLocationDetailTitle),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF202531)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF202531),
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Column(
        children: [
          // 地图区域
          Expanded(
            child: Stack(
              children: [
                MapView(
                  latitude: widget.payload.latitude,
                  longitude: widget.payload.longitude,
                  zoom: 16,
                  enableDrag: false,
                  showMarker: true,
                  markerTitle: widget.payload.name,
                  markerAddress: widget.payload.address,
                  onMapLoaded: _onMapLoaded,
                ),
                if (!_mapLoaded)
                  Container(
                    color: Colors.white,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
          // 位置信息卡片
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppIcon(
                      AppIconKind.place,
                      size: 20,
                      color: Color(0xFF246BFD),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.payload.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF202531),
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.payload.address.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Text(
                      widget.payload.address,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8F96A3),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // 坐标信息
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Text(
                    '经纬度: ${widget.payload.latitude.toStringAsFixed(6)}, ${widget.payload.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB0B7C3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 操作按钮（仅保留导航）
                SizedBox(
                  width: double.infinity,
                  child: _ActionButton(
                    icon: Icons.navigation,
                    label: '导航到此处',
                    onTap: _navigateToMap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 操作按钮组件
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE6EDF8)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: const Color(0xFF246BFD),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF202531),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
