import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/features/profile/domain/entities/user_profile.dart';
import 'package:shengyu_ui_admin_im/features/profile/domain/repositories/profile_repository.dart';
import 'package:shengyu_ui_admin_im/features/profile/infrastructure/datasources/profile_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/features/profile/infrastructure/repositories/profile_repository_impl.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((
  ref,
) {
  return ProfileRemoteDataSource(dio: ref.read(dioProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.read(profileRemoteDataSourceProvider));
});

final currentUserProfileProvider = FutureProvider<UserProfile>((ref) {
  return ref.read(profileRepositoryProvider).getCurrentUserProfile();
});
