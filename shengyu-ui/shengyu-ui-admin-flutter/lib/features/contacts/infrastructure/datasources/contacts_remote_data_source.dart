import 'package:dio/dio.dart';
import 'package:shengyu_ui_admin_im/core/network/api_result.dart';
import 'package:shengyu_ui_admin_im/features/contacts/infrastructure/dtos/contact_dto.dart';
import 'package:shengyu_ui_admin_im/features/contacts/infrastructure/dtos/contact_profile_dto.dart';
import 'package:shengyu_ui_admin_im/features/contacts/infrastructure/dtos/department_summary_dto.dart';
import 'package:shengyu_ui_admin_im/features/contacts/infrastructure/dtos/group_summary_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/infrastructure/dtos/conversation_dto.dart';

class ContactsRemoteDataSource {
  const ContactsRemoteDataSource({required this.dio, required this.currentUserId});

  final Dio dio;
  final String currentUserId;

  Future<List<ContactDto>> getContacts() async {
    final response = await dio.get('/system/im/contact/list');
    final result = ApiResult.fromJson<List<ContactDto>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) => _mapList(raw, ContactDto.fromJson),
    );
    return result.requireData();
  }

  Future<List<ContactDto>> getStarContacts() async {
    final response = await dio.get('/system/im/contact/list-star');
    final result = ApiResult.fromJson<List<ContactDto>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) => _mapList(raw, ContactDto.fromJson),
    );
    return result.requireData();
  }

  Future<ContactProfileDto> getContactProfile(String userId) async {
    final response = await dio.get(
      '/system/user/get',
      queryParameters: {'id': userId},
    );
    final result = ApiResult.fromJson<ContactProfileDto>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) =>
          ContactProfileDto.fromJson(raw as Map<String, dynamic>? ?? const {}),
    );
    return result.requireData();
  }

  Future<bool> getContactStar(String userId) async {
    final response = await dio.get(
      '/system/im/contact/get',
      queryParameters: {'contactId': userId},
    );
    final result = ApiResult.fromJson<bool>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) =>
          (raw as Map<String, dynamic>? ?? const {})['star'] == true,
    );
    return result.requireData();
  }

  Future<void> updateContactStar(String userId, bool star) async {
    await dio.put(
      '/system/im/contact/setting/update',
      data: <String, dynamic>{'contactId': userId, 'star': star},
    );
  }

  Future<List<ContactDto>> getContactsByDepartment(
    String deptId, {
    String keyword = '',
  }) async {
    final response = await dio.get(
      '/system/im/contact/list-by-dept',
      queryParameters: {
        'deptId': deptId,
        'pageNo': 1,
        'pageSize': 200,
        if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      },
    );
    final result = ApiResult.fromJson<List<ContactDto>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        if (raw is Map<String, dynamic>) {
          return _mapPageList(raw, ContactDto.fromJson);
        }
        return _mapList(raw, ContactDto.fromJson);
      },
    );
    return result.requireData();
  }

  Future<List<DepartmentSummaryDto>> getMyDepartmentTree() async {
    final response = await dio.get('/system/dept/my-dept-tree');
    final result = ApiResult.fromJson<List<DepartmentSummaryDto>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) => _mapList(raw, DepartmentSummaryDto.fromJson),
    );
    return result.requireData();
  }

  Future<List<DepartmentSummaryDto>> getOrganizationTree() async {
    final response = await dio.get('/system/dept/org-tree');
    final result = ApiResult.fromJson<List<DepartmentSummaryDto>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) => _mapList(raw, DepartmentSummaryDto.fromJson),
    );
    return result.requireData();
  }

  Future<List<GroupSummaryDto>> getMyGroups() async {
    final response = await dio.get('/system/im/group/list');
    final result = ApiResult.fromJson<List<GroupSummaryDto>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) => _mapList(raw, GroupSummaryDto.fromJson),
    );
    return result.requireData();
  }

  Future<List<ContactDto>> searchContacts(String keyword) async {
    final response = await dio.get(
      '/system/im/contact/search',
      queryParameters: {'keyword': keyword, 'pageNo': 1, 'pageSize': 20},
    );
    final result = ApiResult.fromJson<List<ContactDto>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) => _mapPageList(raw, ContactDto.fromJson),
    );
    return result.requireData();
  }

  Future<ConversationDto> ensureDirectConversation(String userId) async {
    final response = await dio.get(
      '/system/im/conversation/get-by-target',
      queryParameters: {'targetId': userId, 'conversationType': 1},
    );
    final result = ApiResult.fromJson<ConversationDto>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) =>
          ConversationDto.fromJson(raw as Map<String, dynamic>? ?? const {}, currentUserId: currentUserId),
    );
    return result.requireData();
  }

  List<T> _mapList<T>(
    Object? raw,
    T Function(Map<String, dynamic> json) parser,
  ) {
    final items = raw as List<dynamic>? ?? const [];
    return items.whereType<Map<String, dynamic>>().map(parser).toList();
  }

  List<T> _mapPageList<T>(
    Object? raw,
    T Function(Map<String, dynamic> json) parser,
  ) {
    final data = raw as Map<String, dynamic>? ?? const {};
    final items = data['list'] as List<dynamic>? ?? const [];
    return items.whereType<Map<String, dynamic>>().map(parser).toList();
  }
}
