import 'package:shengyu_ui_admin_im/features/profile/domain/entities/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> getCurrentUserProfile();
  Future<String> uploadAvatar({required String fileName, required List<int> bytes});
  Future<void> deleteAvatar();
}
