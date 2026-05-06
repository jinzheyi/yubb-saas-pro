import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_conversation_settings.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_create_result.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_file_item.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_history_item.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_invite_info.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_invite_verification_result.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_join_request_item.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_join_result.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_member.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_settings_snapshot.dart';

abstract class GroupSettingsRepository {
  Future<GroupSettingsSnapshot> getGroupSettings(String groupId);

  Future<int> getPendingJoinRequestCount(String groupId);

  Future<List<GroupMember>> getGroupMembers(String groupId);

  Future<GroupInviteInfo> getGroupInviteInfo(String groupId);

  Future<GroupInviteVerificationResult> verifyInviteCode(String code);

  Future<GroupJoinResult> joinGroupByInvite(String code);

  Future<GroupConversationSettings> getGroupConversationSettings(
    String groupId,
  );

  Future<GroupCreateResult> createGroup({
    required String name,
    required int groupType,
    required List<String> memberIds,
    String introduction = '',
  });

  Future<void> addGroupMembers({
    required String groupId,
    required List<String> memberIds,
  });

  Future<List<GroupJoinRequestItem>> getGroupJoinRequests({
    required String groupId,
    int? status,
  });

  Future<List<GroupFileItem>> getGroupFiles({
    required String groupId,
    String keyword = '',
    int pageNo = 1,
    int pageSize = 50,
  });

  Future<void> uploadGroupFile({
    required String groupId,
    required String filePath,
    required String fileName,
  });

  Future<void> deleteGroupFile(String id);

  Future<String> ensureGroupChatId(String groupId);

  Future<List<GroupHistoryItem>> searchGroupHistory({
    required String chatId,
    required String keyword,
    String? category,
    int pageNo = 1,
    int pageSize = 50,
  });

  Future<void> updateGroupName({
    required String groupId,
    required String groupName,
  });

  Future<void> updateGroupManageOptions({
    required String groupId,
    bool? allowMemberInvite,
    bool? needApproval,
  });

  Future<void> updateGroupNotice({
    required String groupId,
    required String notice,
    bool? notifyMembers,
    bool? pinNotice,
  });

  Future<void> updateMyNickname({
    required String groupId,
    required String nickname,
  });

  Future<void> transferGroupOwner({
    required String groupId,
    required String newOwnerId,
  });

  Future<void> dissolveGroup({required String groupId});

  Future<void> quitGroup({required String groupId});

  Future<void> approveGroupJoinRequest({required String requestId});

  Future<void> rejectGroupJoinRequest({
    required String requestId,
    String rejectReason = '',
  });

  Future<void> removeGroupMember({
    required String groupId,
    required String memberUserId,
  });

  Future<void> setGroupMemberRole({
    required String groupId,
    required String memberUserId,
    required int role,
  });

  Future<void> setGroupMemberMuted({
    required String groupId,
    required String memberUserId,
    required bool muted,
  });

  Future<void> updateMuteAll({required String groupId, required bool muted});

  Future<void> updatePinned({required String chatId, required bool pinned});

  Future<void> updateNoDisturb({
    required String chatId,
    required bool noDisturb,
  });

  Future<void> clearChatHistory({required String chatId});
}
