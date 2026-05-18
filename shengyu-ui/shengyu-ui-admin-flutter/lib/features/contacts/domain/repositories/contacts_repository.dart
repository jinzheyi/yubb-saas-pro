import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/contact_profile.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/contact_search_result.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/department_summary.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/direct_conversation_ref.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/group_summary.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_directory_item.dart';

abstract class ContactsRepository {
  Future<List<ContactDirectoryItem>> getContacts();

  Future<List<ContactDirectoryItem>> getStarContacts();

  Future<ContactProfile> getContactProfile(String userId);

  Future<bool> getContactStar(String userId);

  Future<void> updateContactStar(String userId, bool star);

  Future<List<ContactDirectoryItem>> getContactsByDepartment(
    String deptId, {
    String keyword = '',
  });

  Future<List<DepartmentSummary>> getMyDepartmentTree();

  Future<List<DepartmentSummary>> getOrganizationTree();

  Future<List<GroupSummary>> getMyGroups();

  Future<ContactSearchResult> search(String keyword);

  Future<DirectConversationRef> ensureDirectConversation(String userId);
}
