// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '圣钰科技 IM';

  @override
  String get loginIntro => '企业级即时通讯与协同入口';

  @override
  String get enterConversation => '进入会话';

  @override
  String get backAction => '返回';

  @override
  String get cancelAction => '取消';

  @override
  String get confirmAction => '确定';

  @override
  String get doneAction => '完成';

  @override
  String get organizeAction => '整理';

  @override
  String get retry => '重试';

  @override
  String get unknownError => '系统开小差了，请稍后重试';

  @override
  String get searchAction => '搜索';

  @override
  String get resetAction => '重置';

  @override
  String get searchHint => '搜索';

  @override
  String get searchMinLength => '请至少输入 2 个字符';

  @override
  String get usernameLabel => '账号';

  @override
  String get passwordLabel => '密码';

  @override
  String get usernamePasswordLogin => '账号密码登录';

  @override
  String get phoneLogin => '手机号登录';

  @override
  String get loginAction => '登录';

  @override
  String get conversationTitle => '会话';

  @override
  String get emptyConversation => '暂无会话';

  @override
  String get conversationShortcutRecent => '最近更新';

  @override
  String get conversationShortcutUsers => '用户';

  @override
  String get conversationShortcutGroups => '用户群体';

  @override
  String get conversationShortcutMention => '提到我的';

  @override
  String get conversationShortcutMute => '免打扰';

  @override
  String get chatPageReadOnlyBannerKicked => '你已被移出群聊，无法发送和接收消息';

  @override
  String get chatPageReadOnlyBannerLeft => '你已退出群聊，无法发送和接收消息';

  @override
  String get chatPageReadOnlyBannerDisbanded => '该群已解散，无法发送和接收消息';

  @override
  String get chatPageBackToConversations => '返回会话列表';

  @override
  String get contactsTitle => '通讯录';

  @override
  String get contactsMyGroups => '我的群组';

  @override
  String get contactsFavorites => '我的关注';

  @override
  String get contactsOrganization => '组织结构';

  @override
  String get contactsDepartments => '我的部门';

  @override
  String get contactsDepartmentDataConnected => '当前页面已切到正式部门与成员接口挂点。';

  @override
  String get contactsOrganizationDataConnected => '当前页面已切到正式组织树接口挂点。';

  @override
  String contactsCountPeople(int count) {
    return '$count人';
  }

  @override
  String get contactsProfileTitle => '用户详情';

  @override
  String get contactsPhoneLabel => '手机号';

  @override
  String get contactsEmailLabel => '邮箱';

  @override
  String get contactsPostLabel => '岗位';

  @override
  String get contactsDetailMore => '更多';

  @override
  String get contactsDetailFollow => '关注';

  @override
  String get contactsDetailUnfollow => '取消关注';

  @override
  String get contactsDetailShareCard => '分享名片';

  @override
  String get contactsDetailName => '姓名';

  @override
  String get contactsDetailMobile => '手机号';

  @override
  String get contactsDetailEmail => '邮箱';

  @override
  String get contactsDetailPost => '岗位';

  @override
  String get contactsDetailDepartment => '部门';

  @override
  String get contactsDetailUnset => '未设置';

  @override
  String get contactsDetailMessage => '发消息';

  @override
  String get contactsDetailCall => '打电话';

  @override
  String get contactsDetailInvalidUser => '用户信息无效';

  @override
  String get contactsDetailFollowSuccess => '关注成功';

  @override
  String get contactsDetailUnfollowSuccess => '已取消关注';

  @override
  String get contactsDetailActionFailedRetry => '操作失败，请重试';

  @override
  String get contactsDetailLoadFailed => '加载用户详情失败';

  @override
  String get contactsDetailCallInDevelopment => '通话功能开发中';

  @override
  String get contactsDetailShareUnsupported => '分享名片暂未接入';

  @override
  String get contactsSearchResultTitle => '搜索结果';

  @override
  String contactsSearchKeyword(String keyword) {
    return '关键词：$keyword';
  }

  @override
  String get contactsSearchInputHint => '搜索联系人或部门';

  @override
  String get contactsPeopleSectionTitle => '联系人';

  @override
  String get contactsDepartmentSectionTitle => '部门';

  @override
  String get contactsSearchEmpty => '暂无结果';

  @override
  String get contactsFavoritesEmpty => '暂无关注联系人';

  @override
  String get messagePreviewImage => '[图片]';

  @override
  String get messagePreviewVoice => '[语音]';

  @override
  String get messagePreviewVideo => '[视频]';

  @override
  String get messagePreviewFile => '[文件]';

  @override
  String messagePreviewFileWithName(String fileName) {
    return '[文件] $fileName';
  }

  @override
  String get messagePreviewLocation => '[位置]';

  @override
  String get messagePreviewEmoji => '[表情]';

  @override
  String get messagePreviewSticker => '[动画表情]';

  @override
  String get messagePreviewContactCard => '[名片]';

  @override
  String get messagePreviewForward => '[聊天记录]';

  @override
  String get messagePreviewSystem => '[系统消息]';

  @override
  String get messagePreviewMePrefix => '我';

  @override
  String messagePreviewMePrefixColon(String summary) {
    return '我:$summary';
  }

  @override
  String get messagePreviewUnknownSender => '未知';

  @override
  String messagePreviewSenderColon(String sender, String summary) {
    return '$sender:$summary';
  }

  @override
  String get conversationPinnedNotice => '已置顶会话';

  @override
  String get conversationUnpinnedNotice => '已取消置顶';

  @override
  String get conversationMarkedReadNotice => '已标为已读';

  @override
  String get conversationMarkedUnreadNotice => '已标为未读';

  @override
  String get conversationDeleteDialogTitle => '删除会话';

  @override
  String get conversationDeleteDialogContent => '删除后将从当前用户会话列表移除。';

  @override
  String get conversationDeletedNotice => '会话已删除';

  @override
  String operationFailed(String error) {
    return '操作失败: $error';
  }

  @override
  String get systemEventGroupNoticeUpdated => '群公告有更新';

  @override
  String get systemEventGroupMuteAllEnabled => '当前群已开启全员禁言';

  @override
  String get systemEventGroupMuteAllDisabled => '当前群已关闭全员禁言';

  @override
  String get systemEventGroupMemberAdded => '有新成员加入群聊';

  @override
  String get systemEventGroupMemberRemoved => '有成员被移出群聊';

  @override
  String get systemEventGroupOwnerTransferred => '群主已完成转让';

  @override
  String get systemEventGroupMemberRoleSetAdmin => '群成员已被设为管理员';

  @override
  String get systemEventGroupMemberRoleSetMember => '群成员已被设置为普通成员';

  @override
  String get systemEventGroupMemberMuted => '群成员已被禁言';

  @override
  String get systemEventGroupMemberUnmuted => '群成员已被解除禁言';

  @override
  String systemEventGroupMemberAddedWithName(String firstName) {
    return '\"$firstName\" 加入了群聊';
  }

  @override
  String systemEventGroupMemberRemovedWithName(String firstName) {
    return '\"$firstName\" 被移出群聊';
  }

  @override
  String systemEventGroupOwnerTransferredTo(String firstName) {
    return '群主已转让给 \"$firstName\"';
  }

  @override
  String systemEventGroupMemberRoleSetAdminWithName(String firstName) {
    return '\"$firstName\" 已被设为管理员';
  }

  @override
  String systemEventGroupMemberRoleSetMemberWithName(String firstName) {
    return '\"$firstName\" 已被设置为普通成员';
  }

  @override
  String systemEventGroupMemberMutedWithName(String firstName) {
    return '\"$firstName\" 已被禁言';
  }

  @override
  String systemEventGroupMemberUnmutedWithName(String firstName) {
    return '\"$firstName\" 已被解除禁言';
  }

  @override
  String get contactsListEmpty => '暂无联系人';

  @override
  String get contactsMyGroupsEmpty => '暂无群组';

  @override
  String get contactsDepartmentsEmpty => '暂无部门成员';

  @override
  String get contactsOrganizationEmpty => '暂无组织架构数据';

  @override
  String get contactsSectionRecent => '最近联系人';

  @override
  String get chatTitle => '聊天';

  @override
  String get inputMessage => '输入消息';

  @override
  String chatTimeToday(String time) {
    return '今天 $time';
  }

  @override
  String chatTimeYesterday(String time) {
    return '昨天 $time';
  }

  @override
  String get chatLoadOlder => '查看更多消息';

  @override
  String get chatReadOnly => '当前会话为只读模式';

  @override
  String get chatReadOnlyClosed => '当前会话已关闭';

  @override
  String get chatGroupRemovedCannotSend => '你已被移出群聊，无法发送消息';

  @override
  String get chatGroupMuteAllEnabled => '当前群已开启全员禁言';

  @override
  String get chatGroupMuteAllDisabled => '当前群已关闭全员禁言';

  @override
  String chatGroupMutedUntil(String time) {
    return '当前已被禁言至 $time';
  }

  @override
  String get chatGroupMutedNoSend => '当前已被禁言，无法发送消息';

  @override
  String get chatGroupYouUnmuted => '你已被解除禁言';

  @override
  String get chatGroupMemberMutedGeneric => '群成员已被禁言';

  @override
  String get chatGroupMemberUnmutedGeneric => '群成员已被解除禁言';

  @override
  String get chatGroupMemberAdded => '有新成员加入群聊';

  @override
  String get chatGroupMemberRemoved => '有成员被移出群聊';

  @override
  String get chatGroupOwnerTransferred => '群主已完成转让';

  @override
  String chatGroupOwnerTransferredTo(String name) {
    return '群主已转让给\"$name\"';
  }

  @override
  String chatGroupMemberAddedOne(String firstName) {
    return '\"$firstName\" 加入了群聊';
  }

  @override
  String chatGroupMemberAddedTwo(String firstName, String secondName) {
    return '\"$firstName\"、\"$secondName\" 加入了群聊';
  }

  @override
  String chatGroupMemberAddedMany(
    String firstName,
    String secondName,
    int otherCount,
  ) {
    return '\"$firstName\"、\"$secondName\" 等$otherCount人加入了群聊';
  }

  @override
  String chatGroupMemberRemovedNamed(String name) {
    return '\"$name\" 已被移出群聊';
  }

  @override
  String get chatGroupMemberRoleSetAdmin => '群成员已被设为管理员';

  @override
  String chatGroupMemberRoleSetAdminNamed(
    String operatorName,
    String targetName,
  ) {
    return '\"$operatorName\" 将 \"$targetName\" 设置为管理员';
  }

  @override
  String get chatGroupMemberRoleSetMember => '群成员已被设置为普通成员';

  @override
  String chatGroupMemberRoleSetMemberNamed(
    String operatorName,
    String targetName,
  ) {
    return '\"$operatorName\" 将 \"$targetName\" 设置为普通成员';
  }

  @override
  String chatGroupMemberMutedNamed(String name) {
    return '\"$name\" 已被禁言';
  }

  @override
  String chatGroupMemberMutedUntil(String name, String time) {
    return '\"$name\" 已被禁言至 $time';
  }

  @override
  String chatGroupMemberUnmutedNamed(String name) {
    return '\"$name\" 已被解除禁言';
  }

  @override
  String get chatGroupYouAreNewOwner => '你已成为新群主';

  @override
  String get chatGroupYouTransferredOwner => '你已转让群主';

  @override
  String get chatGroupSystemSender => '系统';

  @override
  String get chatGroupNoticeUpdated => '群公告有更新';

  @override
  String get messageSending => '发送中';

  @override
  String get messageSent => '已发送';

  @override
  String get messageDelivered => '已送达';

  @override
  String get messageRead => '已读';

  @override
  String get messageFailed => '发送失败';

  @override
  String get retrySend => '重发消息';

  @override
  String get attachImageAction => '发送图片';

  @override
  String get attachFileAction => '发送文件';

  @override
  String get attachmentCapabilityPending => '附件选择器与上传入口正在接入中';

  @override
  String get chatOpenFailed => '打开失败';

  @override
  String get chatNoMoreMessages => '没有更多消息了';

  @override
  String get chatPreviewUnknownSender => '未知';

  @override
  String get chatPreviewMessage => '消息';

  @override
  String get chatPreviewMessageDeleted => '原消息已删除';

  @override
  String get chatPreviewImage => '[图片]';

  @override
  String get chatPreviewEmoji => '[表情]';

  @override
  String get chatPreviewSticker => '[动画表情]';

  @override
  String get chatPreviewVoice => '[语音]';

  @override
  String get chatPreviewVideo => '[视频]';

  @override
  String get chatPreviewFile => '[文件]';

  @override
  String chatPreviewFileWithName(String name) {
    return '[文件] $name';
  }

  @override
  String get chatPreviewLocation => '[位置]';

  @override
  String get chatPreviewContactCard => '[名片]';

  @override
  String get chatPreviewChatHistory => '[聊天记录]';

  @override
  String get chatPreviewRecalled => '[消息已撤回]';

  @override
  String get chatCustomMessage => '[自定义消息]';

  @override
  String get chatClickToViewDetail => '点击查看详情';

  @override
  String get chatRecallSuccess => '已撤回';

  @override
  String get chatRecallConfirmTitle => '提示';

  @override
  String get chatRecallConfirmContent => '确定撤回那条消息吗？';

  @override
  String get chatRecallFailed => '撤回失败';

  @override
  String get chatRecallSelfTip => '你撤回了一条消息';

  @override
  String chatRecallOtherTip(String operatorName) {
    return '$operatorName撤回了一条消息';
  }

  @override
  String get chatCopySuccess => '已复制消息内容';

  @override
  String get chatFavoriteSuccess => '已收藏消息';

  @override
  String get chatDeleteSuccess => '已删除';

  @override
  String get chatDeleteFailed => '删除失败';

  @override
  String get chatDeleteConfirmTitle => '删除消息';

  @override
  String get chatDeleteConfirmContent => '确定删除这条消息吗？';

  @override
  String get chatRetryingMessage => '正在重新发送消息';

  @override
  String get chatHeaderGroupNotice => '群公告';

  @override
  String get chatMultiDeleteTitle => '提示';

  @override
  String chatMultiDeleteContent(int count) {
    return '确定删除选中的 $count 条消息吗？';
  }

  @override
  String get chatVoiceUploadRetry => '语音上传失败，点击重试';

  @override
  String chatSelectedCount(int count) {
    return '已选择 $count 条';
  }

  @override
  String get chatForwardUnsupported => '当前文件暂不支持转发';

  @override
  String chatForwardSuccess(String title) {
    return '已转发到 $title';
  }

  @override
  String get chatReeditExpired => '重新编辑已过期';

  @override
  String get chatReeditUnsupported => '该消息类型不支持重新编辑';

  @override
  String get chatReeditAction => '重新编辑';

  @override
  String get chatRecordPermissionDenied => '录音失败，请检查麦克风权限';

  @override
  String get chatRecordTooShort => '说话时间太短';

  @override
  String get chatRecordFileCreateFailed => '录音文件生成失败';

  @override
  String get chatUploading => '上传中';

  @override
  String get chatOtherUser => '对方';

  @override
  String get chatAnchorFallback => '原消息已不可定位，已为你打开最近消息';

  @override
  String get chatQuoteMessageMissing => '原消息已不存在';

  @override
  String get chatVoiceFileUnavailable => '语音文件不可用';

  @override
  String get chatVoicePlayUrlFailed => '语音播放地址获取失败';

  @override
  String get chatActionCopy => '复制';

  @override
  String get chatActionQuote => '引用回复';

  @override
  String get chatActionFavorite => '收藏';

  @override
  String get chatActionRecall => '撤回';

  @override
  String get chatActionDelete => '删除';

  @override
  String get chatActionMultiSelect => '多选';

  @override
  String get chatMoreActionCamera => '拍摄';

  @override
  String get chatMoreActionCall => '音视频';

  @override
  String get chatMediaTitle => '聊天媒体';

  @override
  String get chatMediaEmpty => '暂无媒体记录';

  @override
  String get chatMediaToday => '今天';

  @override
  String get chatMediaYesterday => '昨天';

  @override
  String chatMediaMonthDay(String month, String day) {
    return '$month-$day';
  }

  @override
  String get chatMediaLoadingMore => '加载更多中...';

  @override
  String get chatMediaNoMore => '没有更多了';

  @override
  String get chatMediaPullMore => '上拉加载更多';

  @override
  String get chatMediaFilterVideo => '视频';

  @override
  String get chatMediaImageFallback => '图片';

  @override
  String get chatImagePlaceholder => '图片';

  @override
  String get chatMediaFileFallback => '文件';

  @override
  String get chatVideoPlayerTitle => '视频播放';

  @override
  String get chatVideoPlayerLoadFailed => '视频加载失败';

  @override
  String get chatVideoPlayerFallbackHint => '请重试，或使用外部应用打开该视频';

  @override
  String get chatVideoPlayerOpenExternally => '外部打开';

  @override
  String get chatVideoPlayerOpenExternalFailed => '外部打开失败';

  @override
  String get chatHistoryTitle => '聊天记录';

  @override
  String get chatHistoryEmpty => '暂无聊天记录';

  @override
  String get chatMessageDetailTitle => '消息详情';

  @override
  String get chatHistorySearchPlaceholder => '搜索聊天记录';

  @override
  String get chatHistoryStartTime => '开始';

  @override
  String get chatHistoryEndTime => '结束';

  @override
  String get chatHistoryUnlimited => '不限';

  @override
  String get chatHistoryEnterKeyword => '请输入搜索关键词';

  @override
  String get chatHistoryEmptySearched => '暂无符合条件的聊天记录';

  @override
  String get chatHistoryEmptyIdle => '输入关键词后可搜索聊天记录';

  @override
  String get chatHistorySearchFailed => '搜索聊天记录失败';

  @override
  String get chatHistoryNoMore => '没有更多了';

  @override
  String get chatHistoryLoading => '加载中...';

  @override
  String get chatHistoryLocateFailed => '无法定位到该消息';

  @override
  String get chatHistoryUnknownUser => '未知用户';

  @override
  String get chatHistoryStartAfterEnd => '开始时间不能晚于结束时间';

  @override
  String get chatHistoryEndBeforeStart => '结束时间不能早于开始时间';

  @override
  String chatHistoryTodayAt(String time) {
    return '今天 $time';
  }

  @override
  String chatHistoryYesterdayAt(String time) {
    return '昨天 $time';
  }

  @override
  String chatHistoryDaysAgoAt(int count, String time) {
    return '$count天前 $time';
  }

  @override
  String chatHistoryMonthDayAt(int month, int day, String time) {
    return '$month-$day $time';
  }

  @override
  String get chatHistoryPreviewImage => '[图片]';

  @override
  String get chatHistoryPreviewVoice => '[语音]';

  @override
  String get chatHistoryPreviewVideo => '[视频]';

  @override
  String get chatHistoryPreviewFile => '[文件]';

  @override
  String get chatHistoryPreviewLocation => '[位置]';

  @override
  String get chatHistoryPreviewEmoji => '[表情]';

  @override
  String get chatHistoryPreviewSticker => '[动画表情]';

  @override
  String get chatHistoryPreviewSystem => '[系统消息]';

  @override
  String get chatHistoryPreviewMessage => '[消息]';

  @override
  String get globalChatSearchTitle => '搜索聊天记录';

  @override
  String get globalChatSearchPlaceholder => '搜索聊天记录';

  @override
  String get globalChatSearchHint => '请输入至少 2 个字符开始搜索';

  @override
  String get globalChatSearchEmpty => '暂无相关聊天记录';

  @override
  String get globalChatSearchLoading => '搜索中...';

  @override
  String get globalChatSearchLoadMore => '上拉加载更多';

  @override
  String get chatSettingsTitle => '聊天设置';

  @override
  String get chatSettingsNoRoleInfo => '暂无岗位信息';

  @override
  String get chatSettingsTop => '置顶聊天';

  @override
  String get chatSettingsNotify => '消息免打扰';

  @override
  String get chatSettingsChatFilesSingle => '聊天文件';

  @override
  String get chatSettingsClearHistory => '清空聊天记录';

  @override
  String get chatSettingsClearHistoryConfirm => '确认清空当前聊天记录吗？';

  @override
  String get chatSettingsSubordinateTip =>
      '注：如需移交、删除下属关系等操作，请在通讯录中前往对应人员详情页处理。';

  @override
  String get chatSettingsPinned => '已置顶聊天';

  @override
  String get chatSettingsUnpinned => '已取消置顶';

  @override
  String get chatSettingsNotifyEnabled => '已开启消息提醒';

  @override
  String get chatSettingsNotifyDisabled => '已开启免打扰';

  @override
  String get chatSettingsCleared => '聊天记录已清空';

  @override
  String get chatSettingsClearHistoryFailed => '清空聊天记录失败';

  @override
  String get chatForwardEmptyTarget => '暂无可转发的会话';

  @override
  String get chatForwardTargetTitle => '选择会话';

  @override
  String get chatForwardTargetSummarySend => '将发送';

  @override
  String get chatForwardTargetSummaryForward => '将转发';

  @override
  String get chatForwardTargetSummaryTo => '到';

  @override
  String chatForwardTargetMessageCount(int count) {
    return '$count条消息';
  }

  @override
  String get chatForwardTargetSingleForward => '逐条转发';

  @override
  String get chatForwardTargetCombineForward => '合并转发';

  @override
  String get chatForwardTargetSending => '发送中...';

  @override
  String get chatForwardTargetSent => '已发送';

  @override
  String get chatForwardTargetForwarded => '已转发';

  @override
  String get chatForwardTargetForwardFailed => '转发失败';

  @override
  String chatForwardTargetPartialSuccess(int successCount, int expectedCount) {
    return '部分成功 $successCount/$expectedCount';
  }

  @override
  String get chatForwardSingle => '逐条转发';

  @override
  String get chatForwardCombine => '合并转发';

  @override
  String get chatForwardMenu => '转发';

  @override
  String get chatForwardSelectTarget => '选择会话';

  @override
  String get chatForwardDialogSend => '发送';

  @override
  String get chatChooseForwardMessage => '请选择要转发的消息';

  @override
  String chatMaxSelectReached(int count) {
    return '最多选择 $count 条消息';
  }

  @override
  String get chatChooseDeleteMessage => '请选择要删除的消息';

  @override
  String get chatForwardCombineDetailTitle => '合并转发详情';

  @override
  String get chatForwardCombineDetailInvalidParams => '参数无效';

  @override
  String get chatForwardCombineDetailLoading => '加载中...';

  @override
  String get chatForwardCombineDetailContentUnavailable => '内容不可查看';

  @override
  String get chatForwardCombineDetailQuoteTooDeep => '引用层级过深';

  @override
  String get chatForwardCombineDetailCircularReference => '检测到循环引用';

  @override
  String chatForwardCombineDetailTodayAt(String time) {
    return '今天 $time';
  }

  @override
  String chatForwardCombineDetailYesterdayAt(String time) {
    return '昨天 $time';
  }

  @override
  String get chatForwardCombineDetailEmpty => '暂无内容';

  @override
  String get chatForwardCombineDetailLoadFailed => '加载失败';

  @override
  String get chatReadReceiptTitle => '已读详情';

  @override
  String get chatReadReceiptClose => '关闭';

  @override
  String get chatReadReceiptReadLabel => '已读';

  @override
  String get chatReadReceiptUnreadTab => '未读';

  @override
  String chatReadReceiptRead(int count) {
    return '已读 $count 人';
  }

  @override
  String chatReadReceiptUnread(int count) {
    return '未读 $count 人';
  }

  @override
  String get chatReadReceiptVoiceHint => '语音消息\"已读\"按会话阅读水位统计，不代表已听语音';

  @override
  String chatReadReceiptTotal(int count) {
    return '总接收人数 $count 人';
  }

  @override
  String get chatReadReceiptEmptyRead => '暂无已读记录';

  @override
  String get chatReadReceiptEmptyUnread => '暂无未读成员';

  @override
  String get chatReadReceiptLoading => '加载中...';

  @override
  String get chatReadReceiptNoMore => '没有更多了';

  @override
  String get chatReadReceiptUnreadLabel => '暂未阅读';

  @override
  String get chatReadReceiptUnknownUser => '未知用户';

  @override
  String get chatReadReceiptReadAtUnknown => '暂无阅读时间';

  @override
  String get chatReadReceiptPending => '处理中';

  @override
  String get chatReadReceiptDataLoading => '回执数据加载中，请稍后重试';

  @override
  String get chatReadReceiptJustNow => '刚刚';

  @override
  String chatReadReceiptTodayAt(String time) {
    return '今天 $time';
  }

  @override
  String chatReadReceiptYesterdayAt(String time) {
    return '昨天 $time';
  }

  @override
  String get chatPresenceOffline => '离线';

  @override
  String get chatPresenceOnline => '在线';

  @override
  String get chatPresenceMobileOnline => '手机在线';

  @override
  String get chatPresenceWebOnline => '网页在线';

  @override
  String get chatPresenceMultiDeviceOnline => '多端在线';

  @override
  String get chatPresenceJustNowActive => '刚刚活跃';

  @override
  String chatPresenceMinutesAgoActive(int count) {
    return '$count分钟前活跃';
  }

  @override
  String chatPresenceTodayActiveAt(String time) {
    return '今天活跃于 $time';
  }

  @override
  String chatPresenceYesterdayActiveAt(String time) {
    return '昨天活跃于 $time';
  }

  @override
  String chatPresenceWeekdayActiveAt(String weekday, String time) {
    return '$weekday活跃于 $time';
  }

  @override
  String get chatPresenceRecentlyActive => '近期活跃';

  @override
  String get chatPresenceSunday => '周日';

  @override
  String get chatPresenceMonday => '周一';

  @override
  String get chatPresenceTuesday => '周二';

  @override
  String get chatPresenceWednesday => '周三';

  @override
  String get chatPresenceThursday => '周四';

  @override
  String get chatPresenceFriday => '周五';

  @override
  String get chatPresenceSaturday => '周六';

  @override
  String get chatTypingDirect => '正在输入...';

  @override
  String chatTypingNamed(String name) {
    return '$name 正在输入...';
  }

  @override
  String chatTypingNamedMany(String names) {
    return '$names 等人正在输入...';
  }

  @override
  String get chatRecordingSlideToCancel => '手指上滑，取消发送';

  @override
  String get chatRecordingReleaseToCancelShort => '松开 取消';

  @override
  String get chatActionFavoriteSticker => '添加到表情';

  @override
  String get chatStickerCannotAdd => '当前消息不可添加';

  @override
  String get chatStickerAdded => '已添加到表情';

  @override
  String get chatStickerExists => '已在表情库中';

  @override
  String chatMaxStickerReached(int count) {
    return '最多添加$count张表情';
  }

  @override
  String get chatStickerAdd => '添加';

  @override
  String get chatEmojiManage => '管理';

  @override
  String get chatEmojiTab => '表情';

  @override
  String get chatStickerTab => '贴纸';

  @override
  String get chatEmojiDelete => '删除';

  @override
  String get chatEmojiRecent => '最近使用';

  @override
  String get chatEmojiAll => '所有表情';

  @override
  String get chatMoreActionLocation => '位置';

  @override
  String get chatSelectLocationTitle => '选择位置';

  @override
  String get chatSelectLocationSearchHint => '搜索位置';

  @override
  String get chatSelectLocationSearchEmptyHint => '输入地点关键词后搜索真实位置';

  @override
  String get chatSelectLocationSendCurrent => '发送当前位置';

  @override
  String get chatSelectLocationTapToLocate => '点击发送当前位置';

  @override
  String get chatSelectLocationNearbyTitle => '附近地点';

  @override
  String get chatSelectLocationSearchResultTitle => '搜索结果';

  @override
  String get chatSelectLocationNoNearbyResult => '暂无附近地点';

  @override
  String get chatSelectLocationNoSearchResult => '暂无搜索结果';

  @override
  String get chatSelectLocationQuotaTitle => '位置服务额度已耗尽';

  @override
  String get chatSelectLocationQuotaDesc => '当前定位检索服务暂时不可用，请稍后再试';

  @override
  String get chatSelectLocationQuotaTip => '可先切换其他方式发送位置';

  @override
  String get chatSelectLocationServiceDisabledTitle => '位置服务未开启';

  @override
  String get chatSelectLocationServiceDisabledDesc => '当前环境尚未开启位置检索服务';

  @override
  String get chatSelectLocationChoose => '请选择位置';

  @override
  String get chatSelectLocationCurrentUnavailable => '当前位置暂不可用';

  @override
  String get chatCurrentLocationName => '当前位置';

  @override
  String get chatLocationUnknownName => '未知位置';

  @override
  String get chatLocationSendSuccess => '已发送位置';

  @override
  String get chatLocationMissing => '位置信息缺失';

  @override
  String get chatLocationOpenFailed => '暂时无法打开该位置';

  @override
  String get chatLocationNavigateAction => '导航前往';

  @override
  String get chatLocationCopyAction => '复制位置';

  @override
  String get chatLocationOpenUnsupported => '当前设备暂不支持直接打开地图，可复制位置信息后使用';

  @override
  String get chatLocationDefaultTitle => '位置';

  @override
  String chatLocationCoordinateFallback(String lat, String lng) {
    return '经纬度：$lat, $lng';
  }

  @override
  String get chatLocationCopied => '位置信息已复制';

  @override
  String get chatMoreActionContactCard => '名片';

  @override
  String get chatSelectContactCardTitle => '选择名片';

  @override
  String get chatSelectContactCardSearchHint => '搜索联系人';

  @override
  String get chatSelectContactCardLoading => '加载中...';

  @override
  String get chatSelectContactCardEmpty => '暂无可选联系人';

  @override
  String get chatSelectContactCardLoadFailed => '加载联系人失败';

  @override
  String get chatSelectContactCardPlaceholder => '请选择 1 位联系人';

  @override
  String chatSelectContactCardSelected(String name) {
    return '已选择：$name';
  }

  @override
  String get chatContactCardLabel => '个人名片';

  @override
  String get chatContactCardUnknownName => '未知联系人';

  @override
  String get chatContactCardSendSuccess => '已发送名片';

  @override
  String get chatContactMissing => '名片联系人不存在';

  @override
  String get filePreviewTitle => '文件预览';

  @override
  String get filePreviewForward => '转发';

  @override
  String get filePreviewPreview => '预览';

  @override
  String get filePreviewDownload => '下载';

  @override
  String get filePreviewPreviewUnavailable => '当前文件暂不支持预览';

  @override
  String get filePreviewDownloadStarted => '已开始下载';

  @override
  String get filePreviewDownloadFailed => '下载失败';

  @override
  String get filePreviewForwardUnsupported => '当前文件暂不支持转发';

  @override
  String get filePreviewModePdf => 'PDF 预览';

  @override
  String get filePreviewModeImage => '图片预览';

  @override
  String get filePreviewModeVideo => '视频预览';

  @override
  String get filePreviewModeAudio => '音频预览';

  @override
  String get filePreviewModeText => '文本预览';

  @override
  String get filePreviewModeMarkdown => 'Markdown 预览';

  @override
  String get filePreviewModeServerPdf => '服务端 PDF 预览';

  @override
  String get filePreviewModeServerHtml => '服务端 HTML 预览';

  @override
  String get filePreviewModeOffice => 'Office 预览';

  @override
  String get filePreviewModeDownloadOnly => '仅支持下载';

  @override
  String get filePreviewModeUnknown => '文件预览';

  @override
  String get browserTitle => '安全浏览';

  @override
  String get browserSourceScan => '扫码';

  @override
  String get browserSourceMessage => '消息';

  @override
  String get browserSourceFile => '文件';

  @override
  String get browserSourceExternal => '外部';

  @override
  String get browserUnknownSafeLink => '未知安全链接';

  @override
  String get browserBlockedTitle => '无法直接打开该内容';

  @override
  String get browserBlockedDesc => '当前内容不是可直接访问的安全网页链接，你仍可以复制后自行处理。';

  @override
  String get browserBlockedLabel => '原始内容';

  @override
  String get browserEmptyContent => '暂无内容';

  @override
  String get browserCopyLink => '复制链接';

  @override
  String get browserCopyContent => '复制内容';

  @override
  String get browserOpenExternally => '外部打开';

  @override
  String get browserNothingToCopy => '没有可复制的内容';

  @override
  String get browserCopySuccess => '复制成功';

  @override
  String get browserOpenExternalFailed => '外部打开失败';

  @override
  String get browserFileLoadingTitle => '正在准备文档预览';

  @override
  String get browserFileLoadingDesc => '文档转换或加载可能需要一点时间，请稍候。';

  @override
  String get browserFileFailedTitle => '文档预览失败';

  @override
  String get browserFileFailedDesc => '当前文档暂时无法在应用内完成预览，你可以重试或改用外部打开。';

  @override
  String get favoriteStatusDeleted => '原消息已删除';

  @override
  String get favoriteStatusRecalled => '原消息已撤回';

  @override
  String get favoriteStatusUnavailable => '原消息不可用';

  @override
  String get chatMentionSearchPlaceholder => '搜索群成员';

  @override
  String get chatMentionClose => '关闭';

  @override
  String get chatMentionLoading => '成员加载中...';

  @override
  String get chatMentionEmpty => '暂无可选择成员';

  @override
  String get chatMentionAllMembers => '所有人';

  @override
  String get chatMentionAllMembersHint => '仅群主或管理员可用';

  @override
  String get groupMemberAlreadyExists => '该成员已在群聊中';

  @override
  String get groupMemberFull => '群人数已达上限';

  @override
  String get groupMemberNotExists => '该成员已不在群聊中';

  @override
  String get groupMembersMute24h => '禁言 24 小时';

  @override
  String groupMembersMutedUntil(
    String month,
    String day,
    String hour,
    String minute,
  ) {
    return '禁言至 $month-$day $hour:$minute';
  }

  @override
  String get groupJoinApplySubmitted => '已提交入群申请';

  @override
  String get groupJoinWaitingApproval => '等待管理员审批';

  @override
  String get groupJoinApproved => '入群申请已通过';

  @override
  String get groupJoinRejected => '入群申请已被拒绝';

  @override
  String get groupJoinWithdrawn => '已撤回入群申请';

  @override
  String get groupJoinWithdrawFailed => '撤回申请失败';

  @override
  String get groupInviteCodeInvalid => '邀请码无效';

  @override
  String get groupInviteCodeExpired => '邀请码已过期';

  @override
  String get groupInviteCodeUsageLimitReached => '邀请码使用次数已达上限';

  @override
  String get groupDissolved => '群已解散';

  @override
  String get groupLeftStatus => '已退出';

  @override
  String get groupKickedStatus => '已被踢';

  @override
  String get groupDisbandedStatus => '已解散';

  @override
  String get groupLeftCannotSend => '你已退出该群聊，无法发送消息';

  @override
  String get groupKickedCannotSend => '你已被移出群聊，无法发送消息';

  @override
  String get groupDisbandedCannotSend => '该群已解散，无法发送消息';

  @override
  String get groupSettingsLeftPageTitle => '已退出群聊';

  @override
  String get groupSettingsKickedPageTitle => '已被移出群聊';

  @override
  String get groupSettingsDisbandedPageTitle => '群聊已解散';

  @override
  String get groupSettingsLeftHint => '你已退出该群聊，无法查看群设置';

  @override
  String get groupSettingsKickedHint => '你已被管理员移出群聊，无法查看群设置';

  @override
  String get groupSettingsDisbandedHint => '群主已解散该群聊，无法查看群设置';

  @override
  String get groupSettingsBackToConversations => '返回会话列表';

  @override
  String get groupSettingsReadOnlyBannerKicked => '你已被移出群聊，当前仅可查看历史信息';

  @override
  String get groupSettingsReadOnlyBannerLeft => '你已退出群聊，当前仅可查看历史信息';

  @override
  String get groupSettingsReadOnlyBannerDisbanded => '该群已解散';

  @override
  String get groupSettingsReadOnlyBannerDefault => '你已不在群内';

  @override
  String get groupSettingsSnapshotTimeLabel => '快照时间';

  @override
  String get groupSettingsLeftTimeLabel => '离群时间';

  @override
  String get groupSettingsCannotViewQrCode => '你无法查看该群二维码';

  @override
  String get groupSettingsCannotViewQrCodeHint => '你已不在该群内，无法获取群二维码';

  @override
  String get groupSettingsReadOnlyMembersHint => '你已不在该群内，仅可查看成员列表';

  @override
  String get groupInviteCodeTenantMismatch => '该邀请码不属于当前企业';

  @override
  String get groupJoinRequestRateLimited => '申请提交过于频繁，请稍后再试';

  @override
  String get groupMembersTitle => '群成员';

  @override
  String groupMembersTitleWithCount(int count) {
    return '群成员($count)';
  }

  @override
  String get groupMembersRemoveTitle => '删除成员';

  @override
  String get groupMembersTransferTitle => '转让群主';

  @override
  String groupMembersConfirmSelected(int count) {
    return '确定($count)';
  }

  @override
  String get groupMembersCannotRemoveOwner => '群主不能删除';

  @override
  String get groupMembersCannotRemoveSelf => '不能删除自己';

  @override
  String get groupMembersSelectMembersToRemove => '请选择要删除的成员';

  @override
  String groupMembersRemoveConfirm(String names) {
    return '确认删除以下成员：$names？';
  }

  @override
  String get groupMembersAlreadyOwner => '该成员已经是群主';

  @override
  String get groupMembersSelectOtherMember => '请选择其他群成员';

  @override
  String get groupMembersThisMember => '该成员';

  @override
  String groupMembersTransferConfirm(String name) {
    return '确认将群主转让给 $name？';
  }

  @override
  String groupMembersTransferredTo(String name) {
    return '已转让给 $name';
  }

  @override
  String get groupMembersTransferFailed => '转让群主失败';

  @override
  String get groupMembersActionSuccess => '操作成功';

  @override
  String get groupSettingsTitle => '群聊设置';

  @override
  String get groupSettingsViewAllMembers => '查看全部群成员';

  @override
  String get groupSettingsAdd => '添加';

  @override
  String get groupSettingsRemove => '删除';

  @override
  String get groupSettingsGroupName => '群聊名称';

  @override
  String get groupSettingsGroupQrCode => '群二维码';

  @override
  String get groupSettingsGroupNotice => '群公告';

  @override
  String get groupSettingsGroupFiles => '群文件';

  @override
  String get groupSettingsChatHistory => '聊天记录';

  @override
  String get groupSettingsMute => '消息免打扰';

  @override
  String get groupSettingsPin => '置顶聊天';

  @override
  String get groupSettingsMuteAll => '全员禁言';

  @override
  String get groupSettingsAllowInvite => '允许成员邀请';

  @override
  String get groupSettingsInviteConfirm => '群聊邀请确认';

  @override
  String get groupSettingsJoinRequests => '入群申请';

  @override
  String get groupSettingsNickname => '我在本群的昵称';

  @override
  String get groupSettingsTransferOwner => '转让群主';

  @override
  String get groupSettingsDissolve => '解散群聊';

  @override
  String get groupSettingsQuitGroup => '退出群聊';

  @override
  String get groupSettingsClearHistory => '清空聊天记录';

  @override
  String get groupSettingsOwner => '群主';

  @override
  String get groupSettingsAdmin => '管理员';

  @override
  String get groupSettingsMember => '成员';

  @override
  String get groupSettingsSetAdmin => '设为管理员';

  @override
  String get groupSettingsRemoveAdmin => '取消管理员';

  @override
  String get groupSettingsMuteMember => '禁言成员';

  @override
  String get groupSettingsUnmuteMember => '解除禁言';

  @override
  String get groupSettingsMutedMember => '已禁言';

  @override
  String get groupSettingsEditGroupName => '修改群聊名称';

  @override
  String get groupSettingsEditNickname => '修改本群昵称';

  @override
  String get groupSettingsInputHint => '请输入内容';

  @override
  String get groupSettingsConfirmAction => '确认操作';

  @override
  String get groupSettingsConfirmClearHistory => '确认清空当前群聊记录？';

  @override
  String get groupSettingsClearHistorySuccess => '已清空聊天记录';

  @override
  String get groupSettingsConfirmTransferOwner => '确认进入转让群主流程？';

  @override
  String get groupSettingsTransferOwnerSuccess => '已转让群主';

  @override
  String groupSettingsConfirmSetAdmin(String name) {
    return '确认将 $name 设为管理员？';
  }

  @override
  String groupSettingsConfirmRemoveAdmin(String name) {
    return '确认取消 $name 的管理员身份？';
  }

  @override
  String groupSettingsConfirmMuteMember(String name) {
    return '确认禁言 $name？';
  }

  @override
  String groupSettingsConfirmUnmuteMember(String name) {
    return '确认解除 $name 的禁言？';
  }

  @override
  String get groupSettingsSetAdminSuccess => '已设为管理员';

  @override
  String get groupSettingsRemoveAdminSuccess => '已取消管理员';

  @override
  String get groupSettingsMuteMemberSuccess => '已禁言成员';

  @override
  String get groupSettingsUnmuteMemberSuccess => '已解除成员禁言';

  @override
  String get groupSettingsConfirmDissolve => '确认解散当前群聊？';

  @override
  String get groupSettingsDissolveSuccess => '已解散群聊';

  @override
  String get groupSettingsConfirmQuitGroup => '确认退出当前群聊？';

  @override
  String get groupSettingsQuitGroupSuccess => '已退出群聊';

  @override
  String get groupSettingsRemoveMember => '移除成员';

  @override
  String get groupSettingsRemoveMemberSuccess => '已移除成员';

  @override
  String groupSettingsConfirmRemoveMember(String name) {
    return '确认移除 $name？';
  }

  @override
  String get groupSettingsPendingEmpty => '暂无待处理';

  @override
  String groupSettingsPendingCount(int count) {
    return '$count 条待处理';
  }

  @override
  String get groupSettingsSave => '保存';

  @override
  String get groupSettingsDone => '完成';

  @override
  String get groupSettingsManage => '管理';

  @override
  String groupSettingsRemoveSelected(int count) {
    return '移除所选成员 ($count)';
  }

  @override
  String get groupSettingsSearchMembers => '搜索成员';

  @override
  String groupSettingsMembersCount(int count) {
    return '共 $count 位成员';
  }

  @override
  String get groupSettingsMemberDetail => '成员详情';

  @override
  String get groupSettingsJoinTime => '加入时间';

  @override
  String get groupSettingsJoinTimeUnknown => '暂无加入时间';

  @override
  String get groupSettingsMuteUntil => '禁言截止';

  @override
  String get groupSettingsMuteUntilUnknown => '暂无禁言截止时间';

  @override
  String get groupSettingsSendMessage => '发送消息';

  @override
  String get groupSettingsViewProfile => '查看资料';

  @override
  String get groupSettingsSetRole => '设置角色';

  @override
  String get groupQrCodeSave => '保存二维码';

  @override
  String get groupQrCodeShare => '分享';

  @override
  String get groupQrCodeHint => '扫码可查看群信息并加入群聊，实际入群规则与有效期以服务端配置为准。';

  @override
  String get groupQrCodeNeedApproval => '需审批入群';

  @override
  String get groupQrCodeNeedApprovalHint => '此邀请码需管理员审批后方可入群';

  @override
  String get groupQrCodePermanent => '永久有效';

  @override
  String get groupQrCodeCopySuccess => '已复制邀请码';

  @override
  String get groupQrCodeUnavailable => '邀请码暂不可用';

  @override
  String get groupQrCodeRefresh => '刷新二维码';

  @override
  String get groupQrCodeRefreshing => '刷新中...';

  @override
  String get groupQrCodeRefreshSuccess => '刷新成功';

  @override
  String get groupQrCodeRefreshFailed => '刷新失败';

  @override
  String get groupQrCodeExpired => '已过期';

  @override
  String get groupQrCodeLoading => '二维码加载中...';

  @override
  String get groupJoinRequestsTitle => '入群审批';

  @override
  String get groupJoinRequestsEmpty => '暂无待审批申请';

  @override
  String get groupJoinRequestsTabPending => '待处理';

  @override
  String get groupJoinRequestsTabProcessed => '已处理';

  @override
  String get groupJoinRequestsEmptyPending => '暂无待处理申请';

  @override
  String get groupJoinRequestsEmptyProcessed => '暂无已处理申请';

  @override
  String get groupJoinRequestsStatusPending => '待处理';

  @override
  String get groupJoinRequestsStatusApproved => '已通过';

  @override
  String get groupJoinRequestsStatusRejected => '已拒绝';

  @override
  String groupJoinRequestsApplyTime(String time) {
    return '申请时间：$time';
  }

  @override
  String groupJoinRequestsHandleTime(String time) {
    return '处理时间：$time';
  }

  @override
  String groupJoinRequestsHandleResult(String result) {
    return '处理结果：$result';
  }

  @override
  String get groupJoinRequestsReject => '拒绝';

  @override
  String get groupJoinRequestsApprove => '通过';

  @override
  String get groupJoinRequestsApproved => '已通过申请';

  @override
  String get groupJoinRequestsRejected => '已拒绝申请';

  @override
  String get groupJoinRequestsRejectTitle => '拒绝申请';

  @override
  String groupJoinRequestsRejectConfirm(String name) {
    return '确认拒绝 $name 的入群申请？';
  }

  @override
  String get groupJoinRequestsRejectedByAdmin => '管理员已拒绝';

  @override
  String get groupJoinRequestsUnknownMember => '未知成员';

  @override
  String get groupJoinRequestsTimeUnknown => '暂无处理时间';

  @override
  String get groupAnnouncementEdit => '编辑';

  @override
  String get groupAnnouncementContent => '群公告内容';

  @override
  String get groupAnnouncementEditTitle => '编辑群公告';

  @override
  String get groupAnnouncementPlaceholder => '请输入群公告';

  @override
  String get groupAnnouncementEmpty => '暂无群公告';

  @override
  String get groupAnnouncementEmptyHint => '编辑后可作为群置顶公告展示给成员';

  @override
  String get groupAnnouncementPinned => '置顶公告';

  @override
  String get groupAnnouncementPublisher => '发布人';

  @override
  String get groupAnnouncementPublishTime => '发布时间';

  @override
  String get groupAnnouncementOwnerFallback => '群主';

  @override
  String get groupAnnouncementNotifyMembers => '通知群成员';

  @override
  String get groupAnnouncementNotifyMembersHint => '发布后将向群成员发送公告变更通知';

  @override
  String get groupAnnouncementPinNotice => '置顶公告';

  @override
  String get groupAnnouncementPinNoticeHint => '置顶后会在聊天页顶部横幅展示';

  @override
  String get groupAnnouncementPublish => '发布';

  @override
  String get groupAnnouncementTooLong => '群公告不能超过 500 字';

  @override
  String get groupAnnouncementPublishSuccess => '群公告已发布';

  @override
  String get groupAnnouncementPublishNotifySuccess => '群公告已发布并通知成员';

  @override
  String get groupAnnouncementCleared => '群公告已清空';

  @override
  String get groupAnnouncementPublishFailed => '群公告发布失败';

  @override
  String get groupAnnouncementDiscardTitle => '放弃本次编辑？';

  @override
  String get groupAnnouncementDiscardContent => '当前修改尚未保存，确认退出编辑吗？';

  @override
  String get groupFilesSearch => '搜索群文件';

  @override
  String get groupFilesEmpty => '暂无群文件';

  @override
  String get groupFilesActionDownload => '下载';

  @override
  String get groupFilesActionForward => '转发';

  @override
  String get groupFilesDownloadStarted => '已开始下载';

  @override
  String get groupFilesDownloadFailed => '下载失败';

  @override
  String get groupFilesForwardUnsupported => '当前文件暂不支持转发';

  @override
  String get groupHistorySearch => '搜索聊天记录';

  @override
  String get groupHistoryEmpty => '暂无相关聊天记录';

  @override
  String get groupHistoryTimeUnknown => '暂无发送时间';

  @override
  String get groupHistorySenderUnknown => '未知成员';

  @override
  String get groupHistoryFilterAll => '全部';

  @override
  String get groupHistoryFilterText => '文字';

  @override
  String get groupHistoryFilterFile => '文件';

  @override
  String get groupHistoryFilterImage => '图片';

  @override
  String get groupHistoryFilterVideo => '视频';

  @override
  String get groupHistoryFilterLink => '链接';

  @override
  String get favoritePageTitle => '消息收藏';

  @override
  String get favoritePageEmpty => '暂无收藏消息';

  @override
  String get favoriteSearchPlaceholder => '搜索收藏';

  @override
  String get favoriteDetailTitle => '收藏详情';

  @override
  String get favoriteDetailLoading => '加载中...';

  @override
  String get favoriteDetailEmpty => '暂无详情';

  @override
  String get favoriteDetailSendToChat => '发送到聊天';

  @override
  String get favoriteDetailTypeLink => '链接';

  @override
  String get favoriteDetailTypeNote => '笔记';

  @override
  String get favoriteDetailTypeImage => '图片';

  @override
  String get favoriteDetailTypeVideo => '视频';

  @override
  String get favoriteDetailTypeFile => '文件';

  @override
  String get favoriteDetailTypeDefault => '消息';

  @override
  String get favoriteDetailInvalidId => '收藏标识无效';

  @override
  String get favoriteDetailLoadFailed => '加载详情失败';

  @override
  String get favoriteDetailVideoUrlEmpty => '视频地址为空';

  @override
  String get favoriteDetailFileUrlEmpty => '文件地址为空';

  @override
  String get favoriteTabDefault => '默认';

  @override
  String get favoriteTabNormal => '普通消息';

  @override
  String get favoriteTabMedia => '图片与视频';

  @override
  String get favoriteTabFile => '文件';

  @override
  String get favoriteCancelAction => '取消收藏';

  @override
  String get favoriteCancelSuccess => '已取消收藏';

  @override
  String get favoriteOpenFailed => '无法打开收藏详情';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsThemeMode => '主题模式';

  @override
  String get settingsThemeModeSummary => '跟随系统 / 浅色 / 深色';

  @override
  String get settingsLanguage => '语言设置';

  @override
  String get settingsLanguageSummary => '跟随系统 / 简体中文 / English';

  @override
  String get settingsAboutApp => '关于圣钰 IM';

  @override
  String get settingsVersionValue => '版本 1.0.0';

  @override
  String get themeSettingsTitle => '主题模式';

  @override
  String get themeModeLightTitle => '浅色模式';

  @override
  String get themeModeLightDescription => '始终使用浅色页面与聊天背景';

  @override
  String get themeModeDarkTitle => '深色模式';

  @override
  String get themeModeDarkDescription => '始终使用深色页面与聊天背景';

  @override
  String get themeModeSystemTitle => '跟随系统';

  @override
  String get themeModeSystemDescription => '跟随设备系统外观设置';

  @override
  String get themePreviewTitle => '当前预览';

  @override
  String get themePreviewMessage => '接近老项目风格的主链路页面预览';

  @override
  String get themePreviewApplyBtn => '立即生效';

  @override
  String get languageSettingsTitle => '语言设置';

  @override
  String get languageModeSystemTitle => '跟随系统';

  @override
  String get languageModeSystemDescription => '使用设备当前语言';

  @override
  String get languageModeZhCnTitle => '简体中文';

  @override
  String get languageModeZhCnDescription => '强制使用中文（zh-CN）';

  @override
  String get languageModeEnTitle => 'English';

  @override
  String get languageModeEnDescription => '强制使用英文';

  @override
  String get languageModeJaTitle => '日本語';

  @override
  String get languageModeJaDescription => '强制使用日文';

  @override
  String get languageModeKoTitle => '한국어';

  @override
  String get languageModeKoDescription => '强制使用韩文';

  @override
  String get languageEffectiveLabel => '当前生效语言';

  @override
  String get profileTitle => '我的';

  @override
  String get profileUnknownUser => '未命名用户';

  @override
  String get profileCompanyLabel => '圣钰科技';

  @override
  String get profileSectionSettings => '设置';

  @override
  String get profileSectionAbout => '关于';

  @override
  String get profileNotifications => '消息通知';

  @override
  String get profilePrivacy => '隐私与安全';

  @override
  String get profileVersionLabel => '当前版本';

  @override
  String get profileThemeSwitch => '切换主题';

  @override
  String get profileFavorites => '收藏';

  @override
  String get profileScan => '扫一扫';

  @override
  String get profileLogout => '退出登录';

  @override
  String get profileAvatarHint => '点击更换或删除头像';

  @override
  String get profileUploadAvatar => '上传头像';

  @override
  String get profileReuploadAvatar => '重新上传头像';

  @override
  String get profileRemoveCustomAvatar => '删除自定义头像';

  @override
  String get profileConfirmRemoveAvatar => '确认删除自定义头像';

  @override
  String get profileAvatarUploadSuccess => '头像上传成功';

  @override
  String get profileAvatarUploadFailed => '头像上传失败';

  @override
  String get profileAvatarRemoveSuccess => '头像已删除';

  @override
  String get profileAvatarRemoveFailed => '头像删除失败';

  @override
  String get profileAvatarUploading => '头像上传中...';

  @override
  String get profileUploadFailedRetry => '上传失败，请重试';

  @override
  String get departmentFallback => '未分配部门';

  @override
  String get profilePostFallback => '未设置岗位';

  @override
  String get profileLoadError => '加载失败，请下拉刷新重试';

  @override
  String get workbenchTitle => '工作台';

  @override
  String get workbenchIntro => '常用协同能力与业务入口集中在这里。';

  @override
  String get workbenchApproval => '审批';

  @override
  String get workbenchTodo => '待办';

  @override
  String get workbenchCalendar => '日程';

  @override
  String get workbenchFiles => '云文件';

  @override
  String get workbenchMeeting => '会议';

  @override
  String get workbenchAnnouncements => '公告';

  @override
  String get workbenchEdit => '编辑';

  @override
  String get workbenchOfficeFlow => '办公流程';

  @override
  String get workbenchCommonFeatures => '常用功能';

  @override
  String get workbenchMail => '邮件';

  @override
  String get workbenchDelegation => '流程代理';

  @override
  String get workbenchAccountSwitch => '账号切换';

  @override
  String get workbenchAttendance => '考勤打卡';

  @override
  String get workbenchFieldWork => '外勤';

  @override
  String get workbenchMetricPlaceholder => '--';

  @override
  String get tabConversations => '消息';

  @override
  String get tabContacts => '通讯录';

  @override
  String get tabWorkbench => '工作台';

  @override
  String get tabProfile => '我';

  @override
  String get stickerManageTitle => '表情管理';

  @override
  String get stickerPin => '置顶';

  @override
  String get stickerMoveLeft => '左移';

  @override
  String get stickerMoveRight => '右移';

  @override
  String get stickerMoveBottom => '置底';

  @override
  String get stickerDeleted => '已删除表情';

  @override
  String get deleteStickerAction => '删除表情';

  @override
  String get pinConversation => '置顶会话';

  @override
  String get unpinConversation => '取消置顶';

  @override
  String get markAsRead => '标为已读';

  @override
  String get markAsUnread => '标为未读';

  @override
  String get deleteConversation => '删除会话';

  @override
  String get groupSettingsReadOnlyTitle => '群设置（只读）';

  @override
  String get groupKickedHint => '你已被移出群聊，当前仅可查看历史信息';

  @override
  String get groupLeftHint => '你已退出群聊，当前仅可查看历史信息';

  @override
  String get groupDisbandedHint => '该群已解散';

  @override
  String get groupNotInGroupHint => '你已不在群内';

  @override
  String groupMemberCount(Object count) {
    return '$count 人群';
  }

  @override
  String get myGroups => '我的群组';

  @override
  String get myFollows => '我的关注';

  @override
  String get organization => '组织架构';

  @override
  String get myDepartments => '我的部门';

  @override
  String get groupMemberAddedSuccess => '添加成员成功';

  @override
  String get addMemberAction => '添加成员';

  @override
  String get createGroupAction => '发起群聊';

  @override
  String get searchMemberHint => '搜索成员';

  @override
  String get atLeastTwoMembers => '至少选择两名成员';

  @override
  String get atLeastOneMember => '至少选择一名成员';

  @override
  String get groupNotAllowedAddMember => '当前群不允许添加成员';

  @override
  String get mustRetainCurrentUserInGroup => '当前登录账号必须保留在群聊中';

  @override
  String get groupInviteCode => '邀请码';

  @override
  String get groupExpireTime => '过期时间';

  @override
  String get groupJoinMethod => '加入方式';

  @override
  String get groupJoinRequiresApproval => '需管理员审核';

  @override
  String get scanPlatformNotSupported => '当前平台未接入原生扫码';

  @override
  String get scanManualJoinHint => '仍可继续通过下方入口手动入群。';

  @override
  String get callSwitch => '切换';

  @override
  String torchToggleFailed(Object error) {
    return '切换手电筒失败: $error';
  }

  @override
  String get searchTabAll => '全部';

  @override
  String get searchTabMessage => '消息';

  @override
  String get searchTabContact => '联系人';

  @override
  String get searchTabGroup => '群聊';

  @override
  String get searchTabMedia => '媒体';

  @override
  String get joinGroupAction => '加入群聊';

  @override
  String get viewGroupAction => '查看群聊';

  @override
  String get invalidInviteExpired => '邀请码无效或已过期';

  @override
  String get manualEntryTitle => '手动输入入群信息';

  @override
  String get inputInviteCodeHint => '请输入邀请码或群邀请链接';

  @override
  String get pasteAction => '粘贴';

  @override
  String get verifyingAction => '校验中...';

  @override
  String get verifyAction => '校验';

  @override
  String get invitePasteHint => '支持直接粘贴老项目二维码链接、邀请码文本或扫码结果。';

  @override
  String get waitingForInput => '等待输入邀请码';

  @override
  String get clipboardEmpty => '剪贴板为空';

  @override
  String get unrecognizedInvite => '无法识别入群码或邀请链接';

  @override
  String get unnamedGroup => '未命名群聊';

  @override
  String get expired => '已过期';

  @override
  String hoursMinutesExpire(Object hours, Object minutes) {
    return '$hours小时$minutes分钟后过期';
  }

  @override
  String minutesExpire(Object minutes) {
    return '$minutes分钟后过期';
  }

  @override
  String get applicationSubmitted => '申请已提交';

  @override
  String get joinedGroup => '已加入群聊';

  @override
  String get submittingAction => '提交中...';

  @override
  String get submitApplication => '提交申请';

  @override
  String get reEnterAction => '重新输入';

  @override
  String get reEnterHint => '请重新输入有效的邀请码或邀请链接。';

  @override
  String get expireTime => '过期时间';

  @override
  String get groupChatNotExist => '群聊不存在';

  @override
  String get searchMinLengthHint => '请输入至少 2 个字符开始搜索';

  @override
  String get searchingAction => '搜索中...';

  @override
  String noResultsFound(Object query) {
    return '未找到\"$query\"相关内容';
  }

  @override
  String get loadMoreAction => '加载更多...';

  @override
  String get noMoreData => '没有更多了';

  @override
  String get clearHistoryTitle => '清空搜索历史';

  @override
  String get clearHistoryConfirm => '确认清空全部搜索历史吗？';

  @override
  String get deleteHistoryTitle => '删除搜索历史';

  @override
  String deleteHistoryConfirm(Object keyword) {
    return '确认删除\"$keyword\"吗？';
  }

  @override
  String get searchHistory => '搜索历史';

  @override
  String get hotSearches => '热门搜索';

  @override
  String get yesterday => '昨天';

  @override
  String get groupMessages => '群消息';

  @override
  String get directMessages => '单聊消息';

  @override
  String get contactType => '联系人';

  @override
  String get groupType => '群聊';

  @override
  String get mediaType => '媒体';

  @override
  String memberCountLabel(Object count) {
    return '$count 人群';
  }

  @override
  String get discardChangesConfirm => '确认放弃语言更改？';

  @override
  String get continueEditAction => '继续编辑';

  @override
  String get discardAction => '放弃';
}
