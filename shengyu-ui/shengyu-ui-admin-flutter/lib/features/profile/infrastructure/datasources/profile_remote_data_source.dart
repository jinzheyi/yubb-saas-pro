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
}
