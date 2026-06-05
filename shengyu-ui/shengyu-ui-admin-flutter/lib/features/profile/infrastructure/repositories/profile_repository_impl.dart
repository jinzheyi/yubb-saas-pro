import 'package:shengyu_ui_admin_im/features/profile/domain/entities/user_profile.dart';
import 'package:shengyu_ui_admin_im/features/profile/domain/repositories/profile_repository.dart';
import 'package:shengyu_ui_admin_im/features/profile/infrastructure/datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remoteDataSource);

  final ProfileRemoteDataSource _remoteDataSource;

  @override
  Future<UserProfile> getCurrentUserProfile() async {
    final dto = await _remoteDataSource.getCurrentUserProfile();
    return UserProfile(
      userId: dto.userId,
      nickname: dto.nickname,
      mobile: dto.mobile,
      email: dto.email,
      avatarUrl: dto.avatarUrl,
      departmentName: dto.departmentName,
      postName: dto.postName,
    );
  }

  @override
  Future<String> uploadAvatar({required String fileName, required List<int> bytes}) {
    return _remoteDataSource.uploadAvatar(fileName: fileName, bytes: bytes);
  }

  @override
  Future<void> deleteAvatar() {
    return _remoteDataSource.deleteAvatar();
  }
}
