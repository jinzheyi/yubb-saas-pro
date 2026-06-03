import 'package:shengyu_ui_admin_im/core/error/app_error.dart';

class GroupMemberPreviewItem {
  const GroupMemberPreviewItem({
    required this.id,
    required this.name,
    required this.roleCode,
    required this.colorValue,
    this.avatarUrl,
    this.deptName,
    this.joinTime,
    this.muteEndTime,
    this.isMuted = false,
  });

  final String id;
  final String name;
  final int roleCode;
  final int colorValue;
  final String? avatarUrl;
  final String? deptName;
  final String? joinTime;
  final DateTime? muteEndTime;
  final bool isMuted;
}

enum GroupSettingsStatus { initial, loading, ready, failed }

class GroupSettingsState {
  const GroupSettingsState({
    this.status = GroupSettingsStatus.initial,
    this.groupName = '',
    this.chatId = '',
    this.notice = '',
    this.noticePinned = false,
    this.noticeUpdatedAt,
    this.members = const <GroupMemberPreviewItem>[],
    this.memberCount = 0,
    this.ownerUserId = '',
    this.ownerName = '',
    this.noDisturb = false,
    this.pinned = false,
    this.muteAll = false,
    this.allowMemberInvite = true,
    this.needApproval = false,
    this.myNickname = '',
    this.membershipBlocked = false,
    this.currentUserRoleCode = 0,
    this.currentUserMuteEndTime,
    this.pendingRequestCount = 0,
    this.groupMemberStatus,
    this.leftAt,
    this.readOnly = false,
    this.snapshotTime,
    this.isFromSnapshot = false,
    this.error,
  });

  final GroupSettingsStatus status;
  final String groupName;
  final String chatId;
  final String notice;
  final bool noticePinned;
  final DateTime? noticeUpdatedAt;
  final List<GroupMemberPreviewItem> members;
  final int memberCount;
  final String ownerUserId;
  final String ownerName;
  final bool noDisturb;
  final bool pinned;
  final bool muteAll;
  final bool allowMemberInvite;
  final bool needApproval;
  final String myNickname;
  final bool membershipBlocked;
  final int currentUserRoleCode;
  final DateTime? currentUserMuteEndTime;
  final int pendingRequestCount;
  final int? groupMemberStatus;
  final DateTime? leftAt;
  final bool readOnly;
  final DateTime? snapshotTime;
  final bool isFromSnapshot;
  final AppError? error;

  bool get isGroupLeft => groupMemberStatus == 1;
  bool get isGroupKicked => groupMemberStatus == 2;
  bool get isGroupDisbanded => groupMemberStatus == 3;
  bool get hasLeftGroup => isGroupLeft || isGroupKicked || isGroupDisbanded;

  GroupSettingsState copyWith({
    GroupSettingsStatus? status,
    String? groupName,
    String? chatId,
    String? notice,
    bool? noticePinned,
    DateTime? noticeUpdatedAt,
    List<GroupMemberPreviewItem>? members,
    int? memberCount,
    String? ownerUserId,
    String? ownerName,
    bool? noDisturb,
    bool? pinned,
    bool? muteAll,
    bool? allowMemberInvite,
    bool? needApproval,
    String? myNickname,
    bool? membershipBlocked,
    int? currentUserRoleCode,
    DateTime? currentUserMuteEndTime,
    int? pendingRequestCount,
    int? groupMemberStatus,
    DateTime? leftAt,
    bool? readOnly,
    DateTime? snapshotTime,
    bool? isFromSnapshot,
    AppError? error,
  }) {
    return GroupSettingsState(
      status: status ?? this.status,
      groupName: groupName ?? this.groupName,
      chatId: chatId ?? this.chatId,
      notice: notice ?? this.notice,
      noticePinned: noticePinned ?? this.noticePinned,
      noticeUpdatedAt: noticeUpdatedAt ?? this.noticeUpdatedAt,
      members: members ?? this.members,
      memberCount: memberCount ?? this.memberCount,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      ownerName: ownerName ?? this.ownerName,
      noDisturb: noDisturb ?? this.noDisturb,
      pinned: pinned ?? this.pinned,
      muteAll: muteAll ?? this.muteAll,
      allowMemberInvite: allowMemberInvite ?? this.allowMemberInvite,
      needApproval: needApproval ?? this.needApproval,
      myNickname: myNickname ?? this.myNickname,
      membershipBlocked: membershipBlocked ?? this.membershipBlocked,
      currentUserRoleCode: currentUserRoleCode ?? this.currentUserRoleCode,
      currentUserMuteEndTime:
          currentUserMuteEndTime ?? this.currentUserMuteEndTime,
      pendingRequestCount: pendingRequestCount ?? this.pendingRequestCount,
      groupMemberStatus: groupMemberStatus ?? this.groupMemberStatus,
      leftAt: leftAt ?? this.leftAt,
      readOnly: readOnly ?? this.readOnly,
      snapshotTime: snapshotTime ?? this.snapshotTime,
      isFromSnapshot: isFromSnapshot ?? this.isFromSnapshot,
      error: error,
    );
  }
}
