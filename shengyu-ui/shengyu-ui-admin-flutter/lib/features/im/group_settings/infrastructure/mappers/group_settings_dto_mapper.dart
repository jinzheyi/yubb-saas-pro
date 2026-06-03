import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_file_item.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_history_item.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_invite_info.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_join_request_item.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_member.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_settings_snapshot.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/infrastructure/dtos/group_file_item_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/infrastructure/dtos/group_history_item_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/infrastructure/dtos/group_info_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/infrastructure/dtos/group_invite_info_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/infrastructure/dtos/group_join_request_item_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/infrastructure/dtos/group_member_dto.dart';

abstract final class GroupSettingsDtoMapper {
  static GroupSettingsSnapshot toSnapshot(
    GroupInfoDto group,
    int pendingJoinRequestCount,
  ) {
    return GroupSettingsSnapshot(
      groupId: group.groupId,
      groupName: group.groupName,
      ownerUserId: group.ownerUserId,
      ownerName: group.ownerName,
      memberCount: group.memberCount,
      notice: group.notice,
      noticePinned: group.noticePinned,
      noticeUpdatedAt: group.noticeUpdatedAt,
      noDisturb: group.noDisturb,
      pinned: group.pinned,
      muteAll: group.muteAll,
      allowMemberInvite: group.allowMemberInvite,
      needApproval: group.needApproval,
      myNickname: group.myNickname,
      pendingJoinRequestCount: pendingJoinRequestCount,
      groupMemberStatus: group.groupMemberStatus,
      leftAt: group.leftAt,
      fromSnapshot: group.fromSnapshot,
    );
  }

  static GroupMember toMember(GroupMemberDto dto) {
    return GroupMember(
      userId: dto.userId,
      userName: dto.userName,
      nickname: dto.nickname,
      role: dto.role,
      avatarUrl: dto.avatarUrl,
      deptName: dto.deptName,
      joinTime: dto.joinTime,
      muteEndTime: dto.muteEndTime,
      isMuted: dto.isMuted,
    );
  }

  static GroupInviteInfo toInviteInfo(GroupInviteInfoDto dto) {
    return GroupInviteInfo(
      groupId: dto.groupId,
      inviteCode: dto.inviteCode,
      expireAt: dto.expireAt,
      needApproval: dto.needApproval,
      qrCodeUrl: dto.qrCodeUrl,
      qrCodeContent: dto.qrCodeContent,
    );
  }

  static GroupFileItem toFileItem(GroupFileItemDto dto) {
    return GroupFileItem(
      id: dto.id,
      fileId: dto.fileId,
      messageId: dto.messageId,
      fileName: dto.fileName,
      fileSize: dto.fileSize,
      fileUrl: dto.fileUrl,
      mediaType: dto.mediaType,
      uploadedAt: dto.uploadedAt,
      uploaderName: dto.uploaderName,
      mimeType: dto.mimeType,
    );
  }

  static GroupJoinRequestItem toJoinRequestItem(GroupJoinRequestItemDto dto) {
    return GroupJoinRequestItem(
      id: dto.id,
      applicantUserId: dto.applicantUserId,
      applicantNickname: dto.applicantNickname,
      applicantAvatar: dto.applicantAvatar,
      status: dto.status,
      createTime: dto.createTime,
      handledTime: dto.handledTime,
      rejectReason: dto.rejectReason,
    );
  }

  static GroupHistoryItem toHistoryItem(GroupHistoryItemDto dto) {
    return GroupHistoryItem(
      messageId: dto.messageId,
      chatId: dto.chatId,
      sequence: dto.sequence,
      senderName: dto.senderName,
      content: dto.content,
      messageType: dto.messageType,
      sentAt: dto.sentAt,
    );
  }
}
