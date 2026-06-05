import 'package:dio/dio.dart';
import 'package:shengyu_ui_admin_im/core/network/api_result.dart';
import 'package:shengyu_ui_admin_im/features/profile/infrastructure/dtos/user_profile_dto.dart';

class ProfileRemoteDataSource {
  const ProfileRemoteDataSource({required this.dio});

  final Dio dio;

  Future<UserProfileDto> getCurrentUserProfile() async {
    final response = await dio.get('/system/user/get-profile');
    final result = ApiResult.fromJson<UserProfileDto>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) =>
          UserProfileDto.fromJson(raw as Map<String, dynamic>? ?? const {}),
    );
    return result.requireData();
  }

  /// 上传用户头像（支持 Web 和原生平台）
  /// 参考 uniappx: updateCurrentUserAvatar 调用 /system/user/avatar
  Future<String> uploadAvatar({required String fileName, required List<int> bytes}) async {
    final multipart = MultipartFile.fromBytes(
      bytes,
      filename: fileName,
    );
    final formData = FormData.fromMap({'avatarFile': multipart});

    final response = await dio.post<Map<String, dynamic>>(
      '/system/user/avatar',
      data: formData,
    );
    final result = ApiResult.fromJson<Object?>(
      response.data as Map<String, dynamic>? ?? const {},
      dataParser: (raw) => raw,
    );
    final data = result.requireData();
    if (data is String) {
      return data;
    }
    if (data is Map) {
      return data['url']?.toString() ?? '';
    }
    return data?.toString() ?? '';
  }

  /// 删除用户自定义头像
  /// 参考 uniappx: clearCurrentUserAvatar 调用 DELETE /system/user/avatar
  Future<void> deleteAvatar() async {
    await dio.delete('/system/user/avatar');
  }
}
