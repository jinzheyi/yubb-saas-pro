import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/contact_profile.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/contact_search_result.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/department_summary.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/direct_conversation_ref.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/group_summary.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:shengyu_ui_admin_im/features/contacts/infrastructure/datasources/contacts_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/features/contacts/infrastructure/dtos/contact_dto.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_directory_item.dart';

class ContactsRepositoryImpl implements ContactsRepository {
  const ContactsRepositoryImpl(this._remoteDataSource);

  final ContactsRemoteDataSource _remoteDataSource;

  @override
  Future<List<ContactDirectoryItem>> getContacts() async {
    final items = await _remoteDataSource.getContacts();
    return items.map(_toDirectoryItem).toList();
  }

  @override
  Future<List<ContactDirectoryItem>> getStarContacts() async {
    final items = await _remoteDataSource.getStarContacts();
    return items.map(_toDirectoryItem).toList();
  }

  @override
  Future<ContactProfile> getContactProfile(String userId) async {
    final dto = await _remoteDataSource.getContactProfile(userId);
    return ContactProfile(
      userId: dto.userId,
      name: dto.nickname,
      departmentName: dto.departmentName,
      postName: dto.postName,
      phone: dto.mobile,
      email: dto.email,
      avatarUrl: dto.avatarUrl,
    );
  }

  @override
  Future<List<ContactDirectoryItem>> getContactsByDepartment(
    String deptId, {
    String keyword = '',
  }) async {
    final items = await _remoteDataSource.getContactsByDepartment(
      deptId,
      keyword: keyword,
    );
    return items.map(_toDirectoryItem).toList();
  }

  @override
  Future<List<DepartmentSummary>> getMyDepartmentTree() async {
    final items = await _remoteDataSource.getMyDepartmentTree();
    return items
        .map(
          (item) => DepartmentSummary(
            deptId: item.deptId,
            name: item.name,
            memberCount: item.memberCount,
            parentDeptId: item.parentDeptId,
            sort: item.sort,
          ),
        )
        .toList();
  }

  @override
  Future<List<DepartmentSummary>> getOrganizationTree() async {
    final items = await _remoteDataSource.getOrganizationTree();
    return items
        .map(
          (item) => DepartmentSummary(
            deptId: item.deptId,
            name: item.name,
            memberCount: item.memberCount,
            parentDeptId: item.parentDeptId,
            sort: item.sort,
          ),
        )
        .toList();
  }

  @override
  Future<List<GroupSummary>> getMyGroups() async {
    final items = await _remoteDataSource.getMyGroups();
    return items
        .map(
          (item) => GroupSummary(
            groupId: item.groupId,
            name: item.name,
            memberCount: item.memberCount,
            avatarUrl: item.avatarUrl,
            myRole: item.myRole,
            pendingJoinRequestCount: item.pendingJoinRequestCount,
          ),
        )
        .toList();
  }

  @override
  Future<ContactSearchResult> search(String keyword) async {
    final contacts = await _remoteDataSource.searchContacts(keyword);
    final departments = await _remoteDataSource.getOrganizationTree();
    return ContactSearchResult(
      contacts: contacts.map(_toDirectoryItem).toList(),
      departments: departments
          .where((item) => item.name.contains(keyword))
          .map(
            (item) => DepartmentSummary(
              deptId: item.deptId,
              name: item.name,
              memberCount: item.memberCount,
              parentDeptId: item.parentDeptId,
              sort: item.sort,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<DirectConversationRef> ensureDirectConversation(String userId) async {
    final dto = await _remoteDataSource.ensureDirectConversation(userId);
    return DirectConversationRef(
      chatId: dto.chatId,
      targetId: dto.targetId.isEmpty ? userId : dto.targetId,
      title: dto.title,
    );
  }

  ContactDirectoryItem _toDirectoryItem(ContactDto dto) {
    return ContactDirectoryItem(
      userId: dto.userId,
      name: dto.nickname,
      departmentName: dto.departmentName,
      chatId: '',
      avatarUrl: dto.avatarUrl,
      postName: dto.postName,
      email: '',
      officeLocation: '',
    );
  }
}
