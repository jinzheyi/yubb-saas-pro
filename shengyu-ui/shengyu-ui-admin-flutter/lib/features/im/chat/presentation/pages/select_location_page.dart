import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_strings.dart';
import 'package:shengyu_ui_admin_im/core/platform/location_service.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_search_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_search_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/location_share_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/map_view.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class SelectLocationPage extends ConsumerStatefulWidget {
  const SelectLocationPage({super.key});

  @override
  ConsumerState<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends ConsumerState<SelectLocationPage> {
  static const double _defaultLatitude = 28.6837;
  static const double _defaultLongitude = 115.8579;

  final TextEditingController _controller = TextEditingController();
  final LocationService _locationService = GeolocatorLocationService();
  
  bool _loading = false;
  bool _quotaExhausted = false;
  bool _serviceDisabled = false;
  bool _locationLoading = false;
  bool _locationRelocating = false;
  String _keyword = '';
  String _noticeMessage = '';
  String _currentAddress = '';
  double _currentLatitude = _defaultLatitude;
  double _currentLongitude = _defaultLongitude;
  List<LocationSearchItem> _items = const <LocationSearchItem>[];
  LocationSearchItem? _selectedItem;
  
  // Map center key - forces WebView rebuild when center changes
  int _mapCenterKey = 0;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() {
      _locationLoading = true;
    });

    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null && mounted) {
        setState(() {
          _currentLatitude = location.latitude;
          _currentLongitude = location.longitude;
          _locationLoading = false;
        });
        // 加载附近 POI
        _loadNearby();
      } else {
        setState(() {
          _locationLoading = false;
        });
        // 使用默认位置加载附近 POI
        _loadNearby();
      }
    } catch (e) {
      setState(() {
        _locationLoading = false;
      });
      debugPrint('[SelectLocationPage] 获取定位失败: $e');
      // 使用默认位置加载附近 POI
      _loadNearby();
    }
  }

  void _onMapDragEnd(double latitude, double longitude) {
    setState(() {
      _currentLatitude = latitude;
      _currentLongitude = longitude;
      _currentAddress = ''; // 清空地址，等待逆地理编码
      _selectedItem = null; // 拖动后清除选中，等 POI 加载后自动选第一项
    });
    // 加载新位置的附近 POI
    _loadNearby();
  }

  /// 一键定位到当前位置（微信风格）
  Future<void> _relocateToCurrentPosition() async {
    if (_locationRelocating) return;
    setState(() {
      _locationRelocating = true;
    });
    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null && mounted) {
        setState(() {
          _currentLatitude = location.latitude;
          _currentLongitude = location.longitude;
          _currentAddress = '';
          _selectedItem = null;
          _mapCenterKey++;
          _locationRelocating = false;
        });
        await _loadNearby();
      } else if (mounted) {
        setState(() {
          _locationRelocating = false;
        });
      }
    } catch (e) {
      debugPrint('[SelectLocationPage] 重新定位失败: $e');
      if (mounted) {
        setState(() {
          _locationRelocating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(strings.chatSelectLocationTitle),
        actions: [
          IconButton(
            tooltip: strings.chatSelectLocationChoose,
            onPressed: _handleConfirm,
            icon: const AppIcon(
              AppIconKind.check,
              size: 22,
              color: Color(0xFF202531),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 地图预览区域
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                MapView(
                  key: ValueKey('map_$_mapCenterKey'),
                  latitude: _currentLatitude,
                  longitude: _currentLongitude,
                  zoom: 15,
                  enableDrag: true,
                  showMarker: true,
                  onDragEnd: _onMapDragEnd,
                ),
                if (_locationLoading)
                  Container(
                    color: Colors.white.withOpacity(0.7),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
          // 一键定位按钮（放在地图下方右侧，避免被 iframe 拦截）
          Container(
            height: 36,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _relocateToCurrentPosition,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: _locationRelocating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF246BFD)),
                        ),
                      )
                    : const AppIcon(
                        AppIconKind.myLocation,
                        size: 20,
                        color: Color(0xFF246BFD),
                      ),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: strings.chatSelectLocationSearchHint,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: AppIcon(
                    AppIconKind.search,
                    size: 18,
                    color: Color(0xFF98A1B2),
                  ),
                ),
                suffixIcon: _keyword.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _clearKeyword,
                        icon: const AppIcon(
                          AppIconKind.close,
                          size: 18,
                          color: Color(0xFF98A1B2),
                        ),
                      ),
              ),
              onChanged: (value) {
                setState(() {
                  _keyword = value.trim();
                });
              },
              onSubmitted: (_) => _handleSearch(),
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _handleSendCurrentLocation,
              child: Ink(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE6EDF8)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: const AppIcon(
                        AppIconKind.myLocation,
                        size: 22,
                        color: Color(0xFF246BFD),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.chatSelectLocationSendCurrent,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF202531),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentLocationSubtitle(strings),
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: Color(0xFF8F96A3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _keyword.isEmpty
                    ? strings.chatSelectLocationNearbyTitle
                    : strings.chatSelectLocationSearchResultTitle,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF8F96A3),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(strings)),
        ],
      ),
    );
  }

  Widget _buildBody(dynamic strings) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_quotaExhausted) {
      return _StateCard(
        icon: AppIconKind.warning,
        title: strings.chatSelectLocationQuotaTitle,
        description: strings.chatSelectLocationQuotaDesc,
        tip: strings.chatSelectLocationQuotaTip,
      );
    }
    if (_serviceDisabled) {
      return _StateCard(
        icon: AppIconKind.locationOff,
        title: strings.chatSelectLocationServiceDisabledTitle,
        description: strings.chatSelectLocationServiceDisabledDesc,
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _keyword.isEmpty
                ? strings.chatSelectLocationNoNearbyResult
                : strings.chatSelectLocationNoSearchResult,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF8F96A3)),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      itemCount: _items.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final item = _items[index];
        final selected =
            _selectedItem?.poiId == item.poiId &&
            _selectedItem?.latitude == item.latitude &&
            _selectedItem?.longitude == item.longitude;
        return ListTile(
          tileColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          onTap: () {
            setState(() {
              _selectedItem = item;
              // 微信行为：点击 POI 后地图中心移动到该位置
              _currentLatitude = item.latitude;
              _currentLongitude = item.longitude;
              _currentAddress = item.address;
              _mapCenterKey++;
            });
          },
          title: Text(
            item.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF202531),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              item.address,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: Color(0xFF8F96A3),
              ),
            ),
          ),
          trailing: selected
              ? const AppIcon(
                  AppIconKind.check,
                  size: 18,
                  color: Color(0xFF246BFD),
                )
              : null,
        );
      },
    );
  }

  String _currentLocationSubtitle(dynamic strings) {
    if (_currentAddress.isNotEmpty) {
      return _currentAddress;
    }
    if (_noticeMessage.isNotEmpty) {
      return _noticeMessage;
    }
    return strings.chatSelectLocationTapToLocate;
  }

  Future<void> _loadNearby() async {
    await _loadLocationResult(
      keyword: '',
      latitude: _currentLatitude,
      longitude: _currentLongitude,
      pageSize: 10,
    );
  }

  Future<void> _handleSearch() async {
    final keyword = _controller.text.trim();
    setState(() {
      _keyword = keyword;
      _selectedItem = null; // 搜索前重置，确保新结果能触发地图同步
    });
    if (keyword.isEmpty) {
      await _loadNearby();
      return;
    }
    await _loadLocationResult(
      keyword: keyword,
      latitude: _currentLatitude,
      longitude: _currentLongitude,
      pageSize: 20,
    );
  }

  void _clearKeyword() {
    _controller.clear();
    setState(() {
      _keyword = '';
      _noticeMessage = '';
    });
    _loadNearby();
  }

  Future<void> _loadLocationResult({
    required String keyword,
    required double latitude,
    required double longitude,
    required int pageSize,
  }) async {
    setState(() {
      _loading = true;
      _quotaExhausted = false;
      _serviceDisabled = false;
      _noticeMessage = '';
    });
    try {
      final result = await ref
          .read(messageRepositoryProvider)
          .searchLocationResult(
            keyword: keyword,
            latitude: latitude,
            longitude: longitude,
            pageSize: pageSize,
          );
      if (!mounted) {
        return;
      }
      _applyResult(result);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _items = const <LocationSearchItem>[];
        _selectedItem = null;
        _noticeMessage = error.toString();
        _loading = false;
      });
    }
  }

  void _applyResult(LocationSearchResult result) {
    final message = result.message.trim();
    final quota =
        message.contains('额度') || message.toLowerCase().contains('quota');
    final enabled = result.enabled;
    final items = result.items;
    
    // 关键：必须在赋值前判断，否则 _selectedItem 已被覆盖为 items.first
    // 微信行为：用户没有手动选择过（或拖动后），地图中心同步到第一项 POI
    // 搜索后也应该同步（移除 keywordIsNearby 限制）
    final hadNoManualSelection = _selectedItem == null;
    final shouldSyncMapCenter = hadNoManualSelection && items.isNotEmpty;
    
    setState(() {
      _quotaExhausted = quota;
      _serviceDisabled = !enabled && !quota;
      _noticeMessage = (!quota && message.isNotEmpty) ? message : '';
      _items = (enabled && !quota) ? items : const <LocationSearchItem>[];
      _selectedItem = items.isNotEmpty ? items.first : null;
      
      if (shouldSyncMapCenter) {
        // 地图中心同步到第一项 POI 位置
        _currentLatitude = items.first.latitude;
        _currentLongitude = items.first.longitude;
        _currentAddress = items.first.name.trim().isNotEmpty
            ? items.first.name
            : items.first.address;
        _mapCenterKey++; // 强制地图重建
      } else if (_currentAddress.isEmpty && items.isNotEmpty) {
        _currentAddress = items.first.name.trim().isNotEmpty
            ? items.first.name
            : items.first.address;
      }
      _loading = false;
    });
  }

  void _handleConfirm() {
    final strings = ref.read(appStringsProvider);
    final selected = _selectedItem;
    if (selected == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.chatSelectLocationChoose)));
      return;
    }
    Navigator.of(context).pop(
      LocationSharePayload(
        name: selected.name,
        address: selected.address,
        latitude: selected.latitude,
        longitude: selected.longitude,
        provider: selected.provider,
        poiId: selected.poiId,
      ),
    );
  }

  void _handleSendCurrentLocation() {
    final strings = ref.read(appStringsProvider);
    
    // 微信行为：如果用户点击了某个 POI，使用该 POI 的名称和地址
    // 否则使用当前定位的实际地址（来自逆地理编码）
    String name;
    String address;
    
    if (_selectedItem != null) {
      // 用户手动选择了 POI
      name = _selectedItem!.name;
      address = _selectedItem!.address;
    } else if (_currentAddress.isNotEmpty) {
      // 有实际地址（来自逆地理编码或 POI 加载）
      name = _currentAddress;
      address = _currentAddress;
    } else {
      // 兜底：显示"当前位置"
      name = strings.chatCurrentLocationName;
      address = '';
    }
    
    Navigator.of(context).pop(
      LocationSharePayload(
        name: name,
        address: address,
        latitude: _currentLatitude,
        longitude: _currentLongitude,
        provider: 'device',
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.description,
    this.tip,
  });

  final AppIconKind icon;
  final String title;
  final String description;
  final String? tip;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: 34, color: const Color(0xFF98A1B2)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202531),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF8F96A3),
              ),
            ),
            if (tip != null && tip!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                tip!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF246BFD)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
