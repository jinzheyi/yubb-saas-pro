import 'package:dio/dio.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
import 'package:shengyu_ui_admin_im/core/network/api_result.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/infrastructure/dtos/conversation_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_create_result.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_invite_verification_result.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_join_result.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/infrastructure/dtos/group_file_item_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/infrastructure/dtos/group_history_item_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/infrastructure/dtos/group_info_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/infrastructure/dtos/group_invite_info_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/infrastructure/dtos/group_join_request_item_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/infrastructure/dtos/group_member_dto.dart';

class GroupSettingsRemoteDataSource {
  const GroupSettingsRemoteDataSource({required this.dio, required this.currentUserId});

  final Dio dio;
  final String currentUserId;

  Future<GroupInfoDto> getGroup(String groupId) async {
    final response = await dio.get(
      '/system/im/group/get',
      queryParameters: {'id': groupId},
    );
    final result = ApiResult.fromJson<GroupInfoDto>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) =>
          GroupInfoDto.fromJson(raw as Map<String, dynamic>? ?? const {}),
    );
    return result.requireData();
  }

  Future<List<GroupMemberDto>> getGroupMembers(String groupId) async {
    final response = await dio.get(
      '/system/im/group/member/list',
      queryParameters: {'groupId': groupId, 'pageNo': 1, 'pageSize': 200},
    );
    final result = ApiResult.fromJson<List<GroupMemberDto>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        final items = raw as List<dynamic>? ?? const [];
        return items
            .whereType<Map<String, dynamic>>()
            .map(GroupMemberDto.fromJson)
            .toList();
      },
    );
    return result.requireData();
  }

  Future<int> getPendingJoinRequestCount(String groupId) async {
    final response = await dio.get(
      '/system/im/group/join-request/pending-count',
      queryParameters: {'groupId': groupId},
    );
    final result = ApiResult.fromJson<int>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) => (raw as num?)?.toInt() ?? 0,
    );
    return result.requireData();
  }

  Future<GroupInviteInfoDto> getGroupInviteCode(String groupId) async {
    final response = await dio.get(
      '/system/im/group/invite/get',
      queryParameters: {'groupId': groupId},
    );
    final result = ApiResult.fromJson<GroupInviteInfoDto>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) =>
          GroupInviteInfoDto.fromJson(raw as Map<String, dynamic>? ?? const {}),
    );
    return result.requireData();
  }

  Future<GroupInviteVerificationResult> verifyInviteCode(String code) async {
    final response = await dio.get(
      '/system/im/group/invite/verify',
      queryParameters: {'code': code},
    );
    final result = ApiResult.fromJson<GroupInviteVerificationResult>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        final data = raw as Map<String, dynamic>? ?? const {};
        return GroupInviteVerificationResult(
          valid: data['valid'] == true,
          groupId: '${data['groupId'] ?? ''}',
          groupName: '${data['groupName'] ?? data['name'] ?? ''}',
          groupAvatar: '${data['groupAvatar'] ?? data['avatarUrl'] ?? ''}',
          memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
          needApproval: data['needApproval'] == true,
          expireTime: '${data['expireTime'] ?? ''}',
        );
      },
    );
    return result.requireData();
  }

  Future<GroupJoinResult> joinGroupByInvite(String code) async {
    final response = await dio.post(
      '/system/im/group/invite/join',
      data: {'inviteCode': code},
    );
    final result = ApiResult.fromJson<GroupJoinResult>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        final data = raw as Map<String, dynamic>? ?? const {};
        return GroupJoinResult(
          resultType: (data['resultType'] as num?)?.toInt() ?? 1,
          groupId: '${data['groupId'] ?? ''}',
          chatId: '${data['chatId'] ?? ''}',
          message: '${data['message'] ?? ''}',
        );
      },
    );
    return result.requireData();
  }

  Future<List<GroupJoinRequestItemDto>> getGroupJoinRequests({
    required String groupId,
    int? status,
  }) async {
    final response = await dio.get(
      '/system/im/group/join-request/list',
      queryParameters: {'groupId': groupId, 'status': status, 'limit': 100},
    );
    final result = ApiResult.fromJson<List<GroupJoinRequestItemDto>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        final items = raw as List<dynamic>? ?? const [];
        return items
            .whereType<Map<String, dynamic>>()
            .map(GroupJoinRequestItemDto.fromJson)
            .toList();
      },
    );
    return result.requireData();
  }

  Future<List<GroupFileItemDto>> getGroupFiles({
    required String groupId,
    String keyword = '',
    int pageNo = 1,
    int pageSize = 50,
  }) async {
    final response = await dio.get(
      '/system/im/group/file/list',
      queryParameters: {
        'groupId': groupId,
        'pageNo': pageNo,
        'pageSize': pageSize,
        if (keyword.trim().isNotEmpty) 'fileName': keyword.trim(),
      },
    );
    final result = ApiResult.fromJson<List<GroupFileItemDto>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        final data = raw as Map<String, dynamic>? ?? const {};
        final items = data['list'] as List<dynamic>? ?? const [];
        return items
            .whereType<Map<String, dynamic>>()
            .map(GroupFileItemDto.fromJson)
            .toList();
      },
    );
    return result.requireData();
  }

  Future<void> uploadGroupFile({
    required String groupId,
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'directory': 'im/group/$groupId',
      'groupId': groupId,
      AppConfig.fileUploadFieldName: await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
    });
    await dio.post('/system/im/group/file/upload', data: formData);
  }

  Future<void> deleteGroupFile(String id) async {
    await dio.delete(
      '/system/im/group/file/delete',
      queryParameters: {'id': id},
    );
  }

  Future<ConversationDto> ensureGroupConversation(String groupId) async {
    final response = await dio.get(
      '/system/im/conversation/get-by-target',
      queryParameters: {'targetId': groupId, 'conversationType': 2},
    );
    final result = ApiResult.fromJson<ConversationDto>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) =>
          ConversationDto.fromJson(raw as Map<String, dynamic>? ?? const {}, currentUserId: currentUserId),
    );
    return result.requireData();
  }

  Future<GroupCreateResult> createGroup({
    required String name,
    required int groupType,
    required List<String> memberIds,
    String introduction = '',
  }) async {
    final response = await dio.post(
      '/system/im/group/create',
      data: {
        'name': name,
        'groupType': groupType,
        'memberIds': memberIds,
        'introduction': introduction,
      },
    );
    final result = ApiResult.fromJson<GroupCreateResult>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        if (raw is Map<String, dynamic>) {
          return GroupCreateResult(
            groupId: '${raw['groupId'] ?? raw['id'] ?? ''}',
            chatId: '${raw['chatId'] ?? ''}',
          );
        }
        final fallback = '${raw ?? ''}';
        return GroupCreateResult(groupId: fallback, chatId: '');
      },
    );
    return result.requireData();
  }

  Future<void> addGroupMembers({
    required String groupId,
    required List<String> memberIds,
  }) async {
    await dio.post(
      '/system/im/group/member/add',
      data: {'groupId': groupId, 'memberIds': memberIds},
    );
  }

  Future<void> updateConversationSettings({
    required String chatId,
    bool? isPinned,
    bool? noDisturb,
  }) async {
    final data = <String, dynamic>{'chatId': chatId};
    if (isPinned != null) {
      data['isPinned'] = isPinned;
    }
    if (noDisturb != null) {
      data['noDisturb'] = noDisturb;
    }
    await dio.put('/system/im/conversation/update', data: data);
  }

  Future<List<GroupHistoryItemDto>> searchGroupHistory({
    required String chatId,
    required String keyword,
    String? category,
    int pageNo = 1,
    int pageSize = 50,
  }) async {
    final response = await dio.get(
      '/system/im/message/search',
      queryParameters: {
        'chatId': chatId,
        'keyword': keyword.trim(),
        'pageNo': pageNo,
        'pageSize': pageSize,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    final result = ApiResult.fromJson<List<GroupHistoryItemDto>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        final data = raw as Map<String, dynamic>? ?? const {};
        final items = data['list'] as List<dynamic>? ?? const [];
        return items
            .whereType<Map<String, dynamic>>()
            .map(GroupHistoryItemDto.fromJson)
            .toList();
      },
    );
    return result.requireData();
  }

  Future<void> updateGroupName({
    required String groupId,
    required String groupName,
  }) async {
    await dio.put(
      '/system/im/group/update',
      data: {'id': groupId, 'name': groupName},
    );
  }

  Future<void> updateGroupManageOptions({
    required String groupId,
    bool? allowMemberInvite,
    bool? needApproval,
  }) async {
    await dio.put(
      '/system/im/group/update',
      data: {
        'id': groupId,
        'allowMemberInvite': allowMemberInvite,
        'needApproval': needApproval,
      },
    );
  }

  Future<void> updateGroupNotice({
    required String groupId,
    required String notice,
    bool? notifyMembers,
    bool? pinNotice,
  }) async {
    await dio.put(
      '/system/im/group/notice/update',
      data: {
        'groupId': groupId,
        'notice': notice,
        'notifyMembers': notifyMembers,
        'pinNotice': pinNotice,
      },
    );
  }

  Future<void> updateMyNickname({
    required String groupId,
    required String nickname,
  }) async {
    await dio.put(
      '/system/im/group/member/set-nickname',
      data: {'groupId': groupId, 'nickname': nickname},
    );
  }

  Future<void> transferGroupOwner({
    required String groupId,
    required String newOwnerId,
  }) async {
    await dio.put(
      '/system/im/group/transfer-owner',
      queryParameters: {'groupId': groupId, 'newOwnerId': newOwnerId},
    );
  }

  Future<void> dissolveGroup({required String groupId}) async {
    await dio.delete(
      '/system/im/group/dissolve',
      queryParameters: {'id': groupId},
    );
  }

  Future<void> quitGroup({required String groupId}) async {
    await dio.post('/system/im/group/quit', queryParameters: {'id': groupId});
  }

  Future<void> approveGroupJoinRequest({required String requestId}) async {
    await dio.put(
      '/system/im/group/join-request/approve',
      data: {'requestId': requestId},
    );
  }

  Future<void> rejectGroupJoinRequest({
    required String requestId,
    String rejectReason = '',
  }) async {
    await dio.put(
      '/system/im/group/join-request/reject',
      data: {'requestId': requestId, 'rejectReason': rejectReason},
    );
  }

  Future<void> removeGroupMember({
    required String groupId,
    required String memberUserId,
  }) async {
    await dio.delete(
      '/system/im/group/member/remove',
      queryParameters: {'groupId': groupId, 'memberUserId': memberUserId},
    );
  }

  Future<void> setGroupMemberRole({
    required String groupId,
    required String memberUserId,
    required int role,
  }) async {
    await dio.put(
      '/system/im/group/member/set-role',
      queryParameters: {
        'groupId': groupId,
        'memberUserId': memberUserId,
        'role': role,
      },
    );
  }

  Future<void> setGroupMemberMuted({
    required String groupId,
    required String memberUserId,
    required bool muted,
  }) async {
    await dio.put(
      '/system/im/group/member/set-muted',
      queryParameters: {
        'groupId': groupId,
        'memberUserId': memberUserId,
        'muted': muted,
      },
    );
  }

  Future<void> updateMuteAll({
    required String groupId,
    required bool muted,
  }) async {
    await dio.put(
      '/system/im/group/mute-all',
      queryParameters: {'groupId': groupId, 'muted': muted},
    );
  }

  Future<void> clearChatHistory({required String chatId}) async {
    await dio.delete(
      '/system/im/message/clear',
      queryParameters: {'chatId': chatId},
    );
  }
}
