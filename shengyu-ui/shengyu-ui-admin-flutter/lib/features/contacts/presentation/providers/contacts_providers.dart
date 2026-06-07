import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/contact_profile.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/contact_search_result.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/department_summary.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/direct_conversation_ref.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/group_summary.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/controllers/contacts_page_controller.dart';
import 'package:shengyu_ui_admin_im/features/contacts/infrastructure/datasources/contacts_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/features/contacts/infrastructure/repositories/contacts_repository_impl.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_directory_item.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/states/contacts_page_state.dart';

final contactsRemoteDataSourceProvider = Provider<ContactsRemoteDataSource>((
  ref,
) {
  final currentUserId = ref.read(authSessionProvider).userId;
  return ContactsRemoteDataSource(
    dio: ref.read(dioProvider),
    currentUserId: currentUserId,
  );
});

final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  return ContactsRepositoryImpl(ref.read(contactsRemoteDataSourceProvider));
});

final contactsPageControllerProvider =
    StateNotifierProvider<ContactsPageController, ContactsPageState>((ref) {
      return ContactsPageController(ref.read(contactsRepositoryProvider));
    });

final contactProfileProvider = FutureProvider.family<ContactProfile, String>((
  ref,
  userId,
) {
  return ref.read(contactsRepositoryProvider).getContactProfile(userId);
});

final myDepartmentTreeProvider = FutureProvider<List<DepartmentSummary>>((ref) {
  return ref.read(contactsRepositoryProvider).getMyDepartmentTree();
});

final organizationTreeProvider = FutureProvider<List<DepartmentSummary>>((ref) {
  return ref.read(contactsRepositoryProvider).getOrganizationTree();
});

class DepartmentMembersQuery {
  const DepartmentMembersQuery({required this.deptId, this.keyword = ''});

  final String deptId;
  final String keyword;

  @override
  bool operator ==(Object other) {
    return other is DepartmentMembersQuery &&
        other.deptId == deptId &&
        other.keyword == keyword;
  }

  @override
  int get hashCode => Object.hash(deptId, keyword);
}

final departmentMembersProvider =
    FutureProvider.family<List<ContactDirectoryItem>, DepartmentMembersQuery>((
      ref,
      query,
    ) {
      return ref
          .read(contactsRepositoryProvider)
          .getContactsByDepartment(query.deptId, keyword: query.keyword);
    });

final starContactsProvider = FutureProvider<List<ContactDirectoryItem>>((ref) {
  return ref.read(contactsRepositoryProvider).getStarContacts();
});

final myGroupsProvider = FutureProvider<List<GroupSummary>>((ref) {
  return ref.read(contactsRepositoryProvider).getMyGroups();
});

final contactSearchProvider =
    FutureProvider.family<ContactSearchResult, String>((ref, keyword) {
      return ref.read(contactsRepositoryProvider).search(keyword);
    });

final directConversationProvider =
    FutureProvider.family<DirectConversationRef, String>((ref, userId) {
      return ref
          .read(contactsRepositoryProvider)
          .ensureDirectConversation(userId);
    });
