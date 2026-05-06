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
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/repositories/group_settings_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/infrastructure/datasources/group_settings_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/infrastructure/mappers/group_settings_dto_mapper.dart';

class GroupSettingsRepositoryImpl implements GroupSettingsRepository {
  GroupSettingsRepositoryImpl(this._remoteDataSource);

  final GroupSettingsRemoteDataSource _remoteDataSource;

  @override
  Future<GroupInviteInfo> getGroupInviteInfo(String groupId) async {
    final dto = await _remoteDataSource.getGroupInviteCode(groupId);
    return GroupSettingsDtoMapper.toInviteInfo(dto);
  }

  @override
  Future<GroupInviteVerificationResult> verifyInviteCode(String code) {
    return _remoteDataSource.verifyInviteCode(code);
  }

  @override
  Future<GroupJoinResult> joinGroupByInvite(String code) {
    return _remoteDataSource.joinGroupByInvite(code);
  }

  @override
  Future<void> deleteGroupFile(String id) {
    return _remoteDataSource.deleteGroupFile(id);
  }

  @override
  Future<GroupConversationSettings> getGroupConversationSettings(
    String groupId,
  ) async {
    final dto = await _remoteDataSource.ensureGroupConversation(groupId);
    return GroupConversationSettings(
      chatId: dto.chatId,
      pinned: dto.isPinned,
      noDisturb: dto.isMuted,
    );
  }

  @override
  Future<GroupCreateResult> createGroup({
    required String name,
    required int groupType,
    required List<String> memberIds,
    String introduction = '',
  }) {
    return _remoteDataSource.createGroup(
      name: name,
      groupType: groupType,
      memberIds: memberIds,
      introduction: introduction,
    );
  }

  @override
  Future<void> addGroupMembers({
    required String groupId,
    required List<String> memberIds,
  }) {
    return _remoteDataSource.addGroupMembers(
      groupId: groupId,
      memberIds: memberIds,
    );
  }

  @override
  Future<List<GroupJoinRequestItem>> getGroupJoinRequests({
    required String groupId,
    int? status,
  }) async {
    final items = await _remoteDataSource.getGroupJoinRequests(
      groupId: groupId,
      status: status,
    );
    return items.map(GroupSettingsDtoMapper.toJoinRequestItem).toList();
  }

  @override
  Future<String> ensureGroupChatId(String groupId) async {
    final dto = await _remoteDataSource.ensureGroupConversation(groupId);
    return dto.chatId;
  }

  @override
  Future<List<GroupFileItem>> getGroupFiles({
    required String groupId,
    String keyword = '',
    int pageNo = 1,
    int pageSize = 50,
  }) async {
    final items = await _remoteDataSource.getGroupFiles(
      groupId: groupId,
      keyword: keyword,
      pageNo: pageNo,
      pageSize: pageSize,
    );
    return items.map(GroupSettingsDtoMapper.toFileItem).toList();
  }

  @override
  Future<void> uploadGroupFile({
    required String groupId,
    required String filePath,
    required String fileName,
  }) {
    return _remoteDataSource.uploadGroupFile(
      groupId: groupId,
      filePath: filePath,
      fileName: fileName,
    );
  }

  @override
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    final items = await _remoteDataSource.getGroupMembers(groupId);
    return items.map(GroupSettingsDtoMapper.toMember).toList();
  }

  @override
  Future<List<GroupHistoryItem>> searchGroupHistory({
    required String chatId,
    required String keyword,
    String? category,
    int pageNo = 1,
    int pageSize = 50,
  }) async {
    final items = await _remoteDataSource.searchGroupHistory(
      chatId: chatId,
      keyword: keyword,
      category: category,
      pageNo: pageNo,
      pageSize: pageSize,
    );
    return items.map(GroupSettingsDtoMapper.toHistoryItem).toList();
  }

  @override
  Future<GroupSettingsSnapshot> getGroupSettings(String groupId) async {
    final group = await _remoteDataSource.getGroup(groupId);
    return GroupSettingsDtoMapper.toSnapshot(group, 0);
  }

  @override
  Future<int> getPendingJoinRequestCount(String groupId) {
    return _remoteDataSource.getPendingJoinRequestCount(groupId);
  }

  @override
  Future<void> updateGroupName({
    required String groupId,
    required String groupName,
  }) {
    return _remoteDataSource.updateGroupName(
      groupId: groupId,
      groupName: groupName,
    );
  }

  @override
  Future<void> updateGroupManageOptions({
    required String groupId,
    bool? allowMemberInvite,
    bool? needApproval,
  }) {
    return _remoteDataSource.updateGroupManageOptions(
      groupId: groupId,
      allowMemberInvite: allowMemberInvite,
      needApproval: needApproval,
    );
  }

  @override
  Future<void> updateGroupNotice({
    required String groupId,
    required String notice,
    bool? notifyMembers,
    bool? pinNotice,
  }) {
    return _remoteDataSource.updateGroupNotice(
      groupId: groupId,
      notice: notice,
      notifyMembers: notifyMembers,
      pinNotice: pinNotice,
    );
  }

  @override
  Future<void> updateMuteAll({required String groupId, required bool muted}) {
    return _remoteDataSource.updateMuteAll(groupId: groupId, muted: muted);
  }

  @override
  Future<void> updateNoDisturb({
    required String chatId,
    required bool noDisturb,
  }) {
    return _remoteDataSource.updateConversationSettings(
      chatId: chatId,
      noDisturb: noDisturb,
    );
  }

  @override
  Future<void> updatePinned({required String chatId, required bool pinned}) {
    return _remoteDataSource.updateConversationSettings(
      chatId: chatId,
      isPinned: pinned,
    );
  }

  @override
  Future<void> updateMyNickname({
    required String groupId,
    required String nickname,
  }) {
    return _remoteDataSource.updateMyNickname(
      groupId: groupId,
      nickname: nickname,
    );
  }

  @override
  Future<void> transferGroupOwner({
    required String groupId,
    required String newOwnerId,
  }) {
    return _remoteDataSource.transferGroupOwner(
      groupId: groupId,
      newOwnerId: newOwnerId,
    );
  }

  @override
  Future<void> dissolveGroup({required String groupId}) {
    return _remoteDataSource.dissolveGroup(groupId: groupId);
  }

  @override
  Future<void> quitGroup({required String groupId}) {
    return _remoteDataSource.quitGroup(groupId: groupId);
  }

  @override
  Future<void> approveGroupJoinRequest({required String requestId}) {
    return _remoteDataSource.approveGroupJoinRequest(requestId: requestId);
  }

  @override
  Future<void> rejectGroupJoinRequest({
    required String requestId,
    String rejectReason = '',
  }) {
    return _remoteDataSource.rejectGroupJoinRequest(
      requestId: requestId,
      rejectReason: rejectReason,
    );
  }

  @override
  Future<void> removeGroupMember({
    required String groupId,
    required String memberUserId,
  }) {
    return _remoteDataSource.removeGroupMember(
      groupId: groupId,
      memberUserId: memberUserId,
    );
  }

  @override
  Future<void> setGroupMemberRole({
    required String groupId,
    required String memberUserId,
    required int role,
  }) {
    return _remoteDataSource.setGroupMemberRole(
      groupId: groupId,
      memberUserId: memberUserId,
      role: role,
    );
  }

  @override
  Future<void> setGroupMemberMuted({
    required String groupId,
    required String memberUserId,
    required bool muted,
  }) {
    return _remoteDataSource.setGroupMemberMuted(
      groupId: groupId,
      memberUserId: memberUserId,
      muted: muted,
    );
  }

  @override
  Future<void> clearChatHistory({required String chatId}) {
    return _remoteDataSource.clearChatHistory(chatId: chatId);
  }
}
