import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

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
      final permission = await Geolocator.checkPermission();
      
      // Web 平台特殊处理
      if (kIsWeb) {
        // Web 端可能返回 denied 或 unableToDetermine
        // 需要尝试请求权限
        if (permission == LocationPermission.denied) {
          return await requestPermission();
        }
      }
      
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('[LocationService] checkPermission error: $e');
      
      // Web 平台在某些浏览器中可能抛出异常
      if (kIsWeb) {
        // 尝试直接请求权限
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
        // 检查是否是安全上下文（HTTPS 或 localhost）
        // 这个检查在 Web 端很重要
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
      // 使用高精度定位，Web 端使用更宽松的超时设置
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: kIsWeb ? 20 : 15),
        ),
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
