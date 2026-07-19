import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';

/// 定位结果
class LocationResult {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final DateTime? timestamp;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.timestamp,
  });

  @override
  String toString() {
    return 'LocationResult(lat: $latitude, lng: $longitude, accuracy: $accuracy)';
  }
}

/// 定位服务接口
abstract class LocationService {
  /// 检查定位权限
  Future<bool> checkPermission();

  /// 请求定位权限
  Future<bool> requestPermission();

  /// 获取当前位置
  Future<LocationResult?> getCurrentLocation();

  /// 监听位置变化
  Stream<LocationResult> watchLocation();

  /// 检查定位服务是否开启
  Future<bool> isLocationServiceEnabled();
}

/// 基于 geolocator 的定位服务实现
/// 
/// 注意：Web 平台需要满足以下条件才能使用定位功能：
/// 1. 页面必须通过 HTTPS 提供（localhost 开发环境除外）
/// 2. 用户必须在浏览器中授予定位权限
/// 3. 浏览器必须支持 Geolocation API
class GeolocatorLocationService implements LocationService {
  @override
  Future<bool> checkPermission() async {
    try {
      var permission = await Geolocator.checkPermission();

      // 权限被拒绝时，主动弹窗请求（Web 和移动端都需要）
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // deniedForever 表示用户永久拒绝，无法再弹窗
      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] 定位权限被永久拒绝，请到系统设置中开启');
        return false;
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('[LocationService] checkPermission error: $e');
      if (kIsWeb) {
        return await requestPermission();
      }
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      
      // Web 平台可能返回不同的权限状态
      if (kIsWeb) {
        // 如果用户拒绝，返回 false
        if (permission == LocationPermission.denied || 
            permission == LocationPermission.deniedForever) {
          debugPrint('[LocationService] Web 端定位权限被拒绝');
          return false;
        }
      }
      
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('[LocationService] requestPermission error: $e');
      
      // Web 平台在某些情况下可能抛出异常（如不支持的浏览器）
      if (kIsWeb) {
        debugPrint('[LocationService] Web 端可能不支持 Geolocation API 或非 HTTPS 环境');
      }
      
      return false;
    }
  }

  @override
  Future<LocationResult?> getCurrentLocation() async {
    try {
      // Web 平台特殊检查
      if (kIsWeb) {
        debugPrint('[LocationService] Web 端定位需要 HTTPS 环境（localhost 除外）');
      }

      // 检查权限
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        debugPrint('[LocationService] 定位权限未授予');
        return null;
      }

      // 检查定位服务（Web 端可能不支持此方法）
      if (!kIsWeb) {
        final serviceEnabled = await isLocationServiceEnabled();
        if (!serviceEnabled) {
          debugPrint('[LocationService] 定位服务未开启');
          return null;
        }
      }

      // 获取当前位置
      // 强制使用 Android LocationManager 直连 GPS，避免 Google Play Services
      // 返回缓存的粗略位置（基站/WiFi 定位可能偏移几百米）
      final position = await Geolocator.getCurrentPosition(
        locationSettings: kIsWeb
            ? LocationSettings(
                accuracy: LocationAccuracy.best,
                timeLimit: const Duration(seconds: 20),
              )
            : AndroidSettings(
                accuracy: LocationAccuracy.best,
                timeLimit: const Duration(seconds: 15),
                forceLocationManager: true,
              ),
      );

      debugPrint(
        '[LocationService] 定位成功: lat=${position.latitude}, '
        'lng=${position.longitude}, accuracy=${position.accuracy}m',
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        timestamp: position.timestamp,
      );
    } catch (e) {
      debugPrint('[LocationService] getCurrentLocation error: $e');

      // Web 端提供更详细的错误信息
      if (kIsWeb) {
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('permission') || errorStr.contains('denied')) {
          debugPrint('[LocationService] Web 端：定位权限被拒绝');
        } else if (errorStr.contains('timeout')) {
          debugPrint('[LocationService] Web 端：定位超时，请检查网络连接');
        } else if (errorStr.contains('unavailable') || errorStr.contains('not support')) {
          debugPrint('[LocationService] Web 端：浏览器不支持定位或不在 HTTPS 环境');
        }
      }

      return null;
    }
  }

  @override
  Stream<LocationResult> watchLocation() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // 移动10米后更新
      ),
    ).map((position) {
      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        timestamp: position.timestamp,
      );
    });
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      // Web 端可能不支持此方法
      if (kIsWeb) {
        debugPrint('[LocationService] Web 端不支持检查定位服务状态，跳过此检查');
        return true; // 假设 Web 端定位服务已开启
      }
      
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('[LocationService] isLocationServiceEnabled error: $e');
      
      // Web 端异常时返回 true，让后续流程继续
      if (kIsWeb) {
        return true;
      }
      
      return false;
    }
  }
}
