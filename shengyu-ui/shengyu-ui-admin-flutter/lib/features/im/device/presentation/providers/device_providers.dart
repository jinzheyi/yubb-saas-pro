import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error_mapper.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/features/im/device/data/device_api_service.dart';
import 'package:shengyu_ui_admin_im/features/im/device/domain/device_info.dart';

final deviceRemoteDataSourceProvider = Provider<DeviceRemoteDataSource>((ref) {
  return DeviceRemoteDataSource(dio: ref.read(dioProvider));
});

final deviceListProvider =
    StateNotifierProvider<DeviceListController, DeviceListState>((ref) {
      return DeviceListController(ref.read(deviceRemoteDataSourceProvider));
    });

class DeviceListState {
  const DeviceListState({
    this.status = DeviceListStatus.initial,
    this.devices = const <DeviceInfo>[],
    this.error,
    this.kickingDeviceType,
  });

  final DeviceListStatus status;
  final List<DeviceInfo> devices;
  final String? error;
  final int? kickingDeviceType;

  bool get isLoading => status == DeviceListStatus.loading;
  bool get isKicking => kickingDeviceType != null;

  DeviceListState copyWith({
    DeviceListStatus? status,
    List<DeviceInfo>? devices,
    String? error,
    int? kickingDeviceType,
  }) {
    return DeviceListState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      error: error ?? this.error,
      kickingDeviceType: kickingDeviceType ?? this.kickingDeviceType,
    );
  }
}

enum DeviceListStatus { initial, loading, ready, failed }

class DeviceListController extends StateNotifier<DeviceListState> {
  DeviceListController(this._dataSource) : super(const DeviceListState());

  final DeviceRemoteDataSource _dataSource;

  Future<void> load() async {
    state = state.copyWith(
      status: DeviceListStatus.loading,
      error: null,
    );
    try {
      final devices = await _dataSource.getDeviceList();
      state = state.copyWith(
        status: DeviceListStatus.ready,
        devices: devices,
        error: null,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        status: DeviceListStatus.failed,
        error: AppErrorMapper.map(error, stackTrace).toString(),
      );
    }
  }

  Future<void> refresh() => load();

  Future<void> kickDevice(int deviceType) async {
    state = state.copyWith(kickingDeviceType: deviceType);
    try {
      await _dataSource.kickDevice(deviceType);
      // 踢出后刷新列表
      await load();
    } catch (error, stackTrace) {
      state = state.copyWith(
        error: AppErrorMapper.map(error, stackTrace).toString(),
      );
    } finally {
      state = state.copyWith(kickingDeviceType: null);
    }
  }
}
