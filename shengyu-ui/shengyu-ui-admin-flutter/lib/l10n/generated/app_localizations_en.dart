// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Shengyu IM';

  @override
  String get loginIntro => 'Enterprise IM and collaboration entry';

  @override
  String get enterConversation => 'Enter Conversations';

  @override
  String get conversationTitle => 'Conversations';

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get workbenchTitle => 'Workbench';

  @override
  String get profileTitle => 'Me';

  @override
  String get chatTitle => 'Chat';

  @override
  String get emptyConversation => 'No conversations';

  @override
  String get inputMessage => 'Type a message';

  @override
  String get searchHint => 'Search';

  @override
  String get usernameLabel => 'Username';

  @override
  String get passwordLabel => 'Password';

  @override
  String get usernamePasswordLogin => 'Account Login';

  @override
  String get phoneLogin => 'Phone Login';

  @override
  String get loginAction => 'Sign In';

  @override
  String get tabConversations => 'Messages';

  @override
  String get tabContacts => 'Contacts';

  @override
  String get tabWorkbench => 'Workbench';

  @override
  String get tabProfile => 'Me';

  @override
  String get conversationShortcutRecent => 'Recent';

  @override
  String get conversationShortcutUsers => 'Users';

  @override
  String get conversationShortcutGroups => 'Groups';

  @override
  String get conversationShortcutMention => 'Mentions';

  @override
  String get conversationShortcutMute => 'Muted';

  @override
  String get contactsMyGroups => 'My Groups';

  @override
  String get contactsFavorites => 'Favorites';

  @override
  String get contactsOrganization => 'Organization';

  @override
  String get contactsDepartments => 'Departments';

  @override
  String get contactsDepartmentDataConnected =>
      'This page is now wired to the formal department and member endpoints.';

  @override
  String get contactsOrganizationDataConnected =>
      'This page is now wired to the formal organization tree endpoint.';

  @override
  String contactsCountPeople(Object count) {
    return '$count people';
  }

  @override
  String get contactsProfileTitle => 'User Details';

  @override
  String get contactsPhoneLabel => 'Phone';

  @override
  String get contactsEmailLabel => 'Email';

  @override
  String get contactsPostLabel => 'Position';

  @override
  String get contactsDetailMore => 'More';

  @override
  String get contactsDetailFollow => 'Follow';

  @override
  String get contactsDetailUnfollow => 'Unfollow';

  @override
  String get contactsDetailShareCard => 'Share Contact Card';

  @override
  String get contactsDetailName => 'Name';

  @override
  String get contactsDetailMobile => 'Phone';

  @override
  String get contactsDetailEmail => 'Email';

  @override
  String get contactsDetailPost => 'Position';

  @override
  String get contactsDetailDepartment => 'Department';

  @override
  String get contactsDetailUnset => 'Unset';

  @override
  String get contactsDetailMessage => 'Message';

  @override
  String get contactsDetailCall => 'Call';

  @override
  String get contactsDetailInvalidUser => 'Invalid user';

  @override
  String get contactsDetailFollowSuccess => 'Followed';

  @override
  String get contactsDetailUnfollowSuccess => 'Unfollowed';

  @override
  String get contactsDetailActionFailedRetry => 'Action failed, please retry';

  @override
  String get contactsDetailLoadFailed => 'Failed to load user details';

  @override
  String get contactsDetailCallInDevelopment => 'Calling is under development';

  @override
  String get contactsDetailShareUnsupported =>
      'Contact card sharing is not wired yet';

  @override
  String get chatSettingsTitle => 'Chat Settings';

  @override
  String get chatSettingsNoRoleInfo => 'No role information';

  @override
  String get chatSettingsTop => 'Pin Chat';

  @override
  String get chatSettingsNotify => 'Mute Notifications';

  @override
  String get chatSettingsChatFilesSingle => 'Chat Files';

  @override
  String get chatSettingsClearHistory => 'Clear Chat History';

  @override
  String get chatSettingsClearHistoryConfirm =>
      'Clear the current chat history?';

  @override
  String get chatSettingsSubordinateTip =>
      'Note: manage subordinate relationships from the matching contact detail page.';

  @override
  String get chatSettingsPinned => 'Chat pinned';

  @override
  String get chatSettingsUnpinned => 'Chat unpinned';

  @override
  String get chatSettingsNotifyEnabled => 'Notifications enabled';

  @override
  String get chatSettingsNotifyDisabled => 'Mute enabled';

  @override
  String get chatSettingsCleared => 'Chat history cleared';

  @override
  String get chatSettingsClearHistoryFailed => 'Failed to clear chat history';

  @override
  String get chatMediaTitle => 'Chat Media';

  @override
  String get chatMediaEmpty => 'No media records';

  @override
  String get chatMediaToday => 'Today';

  @override
  String get chatMediaYesterday => 'Yesterday';

  @override
  String chatMediaMonthDay(Object month, Object day) {
    return '$month-$day';
  }

  @override
  String get chatMediaLoadingMore => 'Loading more...';

  @override
  String get chatMediaNoMore => 'No more items';

  @override
  String get chatMediaPullMore => 'Pull up to load more';

  @override
  String get chatMediaFilterVideo => 'Videos';

  @override
  String get chatMediaImageFallback => 'Image';

  @override
  String get chatImagePlaceholder => 'Image';

  @override
  String get chatMediaFileFallback => 'File';

  @override
  String get chatHistoryTitle => 'Chat History';

  @override
  String get chatHistoryEmpty => 'No chat history';

  @override
  String get chatHistorySearchPlaceholder => 'Search chat history';

  @override
  String get chatHistoryStartTime => 'Start';

  @override
  String get chatHistoryEndTime => 'End';

  @override
  String get chatHistoryUnlimited => 'Unlimited';

  @override
  String get chatHistoryEnterKeyword => 'Enter a search keyword';

  @override
  String get chatHistoryEmptySearched => 'No matching chat history';

  @override
  String get chatHistoryEmptyIdle => 'Enter a keyword to search chat history';

  @override
  String get chatHistorySearchFailed => 'Failed to search chat history';

  @override
  String get chatHistoryNoMore => 'No more items';

  @override
  String get chatHistoryLoading => 'Loading...';

  @override
  String get chatHistoryLocateFailed => 'Unable to locate this message';

  @override
  String get chatHistoryUnknownUser => 'Unknown User';

  @override
  String get chatHistoryStartAfterEnd =>
      'Start time cannot be later than end time';

  @override
  String get chatHistoryEndBeforeStart =>
      'End time cannot be earlier than start time';

  @override
  String chatHistoryTodayAt(Object time) {
    return 'Today $time';
  }

  @override
  String chatHistoryYesterdayAt(Object time) {
    return 'Yesterday $time';
  }

  @override
  String chatHistoryDaysAgoAt(Object count, Object time) {
    return '$count days ago $time';
  }

  @override
  String chatHistoryMonthDayAt(Object month, Object day, Object time) {
    return '$month-$day $time';
  }

  @override
  String get chatHistoryPreviewImage => '[Image]';

  @override
  String get chatHistoryPreviewVoice => '[Voice]';

  @override
  String get chatHistoryPreviewVideo => '[Video]';

  @override
  String get chatHistoryPreviewFile => '[File]';

  @override
  String get chatHistoryPreviewLocation => '[Location]';

  @override
  String get chatHistoryPreviewEmoji => '[Emoji]';

  @override
  String get chatHistoryPreviewSticker => '[Animated Sticker]';

  @override
  String get chatHistoryPreviewSystem => '[System Message]';

  @override
  String get chatHistoryPreviewMessage => '[Message]';

  @override
  String get globalChatSearchTitle => 'Search Chat History';

  @override
  String get globalChatSearchPlaceholder => 'Search chat history';

  @override
  String get globalChatSearchHint => 'Enter at least 2 characters to search';

  @override
  String get globalChatSearchEmpty => 'No matching chat history';

  @override
  String get globalChatSearchLoading => 'Searching...';

  @override
  String get globalChatSearchLoadMore => 'Pull up to load more';

  @override
  String get searchAction => 'Search';

  @override
  String get resetAction => 'Reset';

  @override
  String get searchMinLength => 'Enter at least 2 characters';

  @override
  String chatTimeToday(Object time) {
    return 'Today $time';
  }

  @override
  String chatTimeYesterday(Object time) {
    return 'Yesterday $time';
  }

  @override
  String get chatLoadOlder => 'Load older messages';

  @override
  String get contactsSearchResultTitle => 'Search Results';

  @override
  String contactsSearchKeyword(Object keyword) {
    return 'Keyword: $keyword';
  }

  @override
  String get contactsSearchInputHint => 'Search contacts or departments';

  @override
  String get contactsPeopleSectionTitle => 'Contacts';

  @override
  String get contactsDepartmentSectionTitle => 'Departments';

  @override
  String get contactsSearchEmpty => 'No results';

  @override
  String get contactsFavoritesEmpty => 'No favorite contacts yet';

  @override
  String get contactsListEmpty => 'No contacts yet';

  @override
  String get contactsMyGroupsEmpty => 'No groups yet';

  @override
  String get contactsDepartmentsEmpty => 'No department members yet';

  @override
  String get contactsOrganizationEmpty => 'No organization data yet';

  @override
  String get contactsSectionRecent => 'Recent Contacts';

  @override
  String get workbenchIntro =>
      'Common collaboration and business entries live here.';

  @override
  String get workbenchApproval => 'Approvals';

  @override
  String get workbenchTodo => 'To-do';

  @override
  String get workbenchCalendar => 'Calendar';

  @override
  String get workbenchFiles => 'Files';

  @override
  String get workbenchMeeting => 'Meetings';

  @override
  String get workbenchAnnouncements => 'Announcements';

  @override
  String get workbenchEdit => 'Edit';

  @override
  String get workbenchOfficeFlow => 'Office Flow';

  @override
  String get workbenchCommonFeatures => 'Common Features';

  @override
  String get workbenchMail => 'Mail';

  @override
  String get workbenchDelegation => 'Delegation';

  @override
  String get workbenchAccountSwitch => 'Switch Account';

  @override
  String get workbenchAttendance => 'Attendance';

  @override
  String get workbenchFieldWork => 'Field Work';

  @override
  String get workbenchMetricPlaceholder => '--';

  @override
  String get profileUnknownUser => 'Unknown User';

  @override
  String get profileCompanyLabel => 'Shengyu Tech';

  @override
  String get profileSectionSettings => 'Settings';

  @override
  String get profileSectionAbout => 'About';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profilePrivacy => 'Privacy & Security';

  @override
  String get profileVersionLabel => 'Current Version';

  @override
  String get profileThemeSwitch => 'Theme';

  @override
  String get profileFavorites => 'Favorites';

  @override
  String get profileScan => 'Scan';

  @override
  String get profileLogout => 'Sign Out';

  @override
  String get profileAvatarHint => 'Tap to change or remove avatar';

  @override
  String get profileDepartmentFallback => 'No department assigned';

  @override
  String get profilePostFallback => 'No position set';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsThemeMode => 'Theme';

  @override
  String get settingsThemeModeSummary => 'System / Light / Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSummary => 'System / Simplified Chinese / English';

  @override
  String get settingsAboutApp => 'About Shengyu IM';

  @override
  String get settingsVersionValue => 'Version 1.0.0';

  @override
  String get themeSettingsTitle => 'Theme';

  @override
  String get themeModeLightTitle => 'Light mode';

  @override
  String get themeModeLightDescription =>
      'Always use light pages and chat backgrounds';

  @override
  String get themeModeDarkTitle => 'Dark mode';

  @override
  String get themeModeDarkDescription =>
      'Always use dark pages and chat backgrounds';

  @override
  String get themePreviewTitle => 'Preview';

  @override
  String get themePreviewMessage =>
      'Primary flow preview close to the legacy product style';

  @override
  String get retry => 'Retry';

  @override
  String get languageSettingsTitle => 'Language';

  @override
  String get languageModeSystemTitle => 'Follow system';

  @override
  String get languageModeSystemDescription => 'Use the device language';

  @override
  String get languageModeZhCnTitle => 'Simplified Chinese';

  @override
  String get languageModeZhCnDescription => 'Force Chinese (zh-CN)';

  @override
  String get languageModeEnTitle => 'English';

  @override
  String get languageModeEnDescription => 'Force English';

  @override
  String get languageEffectiveLabel => 'Current language';

  @override
  String get retrySend => 'Retry sending';

  @override
  String get messageSending => 'Sending';

  @override
  String get messageSent => 'Sent';

  @override
  String get messageDelivered => 'Delivered';

  @override
  String get messageRead => 'Read';

  @override
  String get messageFailed => 'Failed';

  @override
  String get attachImageAction => 'Send image';

  @override
  String get attachFileAction => 'Send file';

  @override
  String get attachmentCapabilityPending => 'Attachment picker is being wired';

  @override
  String get unknownError => 'Something went wrong';

  @override
  String get groupSettingsTitle => 'Group Settings';

  @override
  String get groupMembersTitle => 'Group Members';

  @override
  String groupMembersTitleWithCount(Object count) {
    return 'Group Members ($count)';
  }

  @override
  String get groupMembersRemoveTitle => 'Remove Members';

  @override
  String get groupMembersTransferTitle => 'Transfer Owner';

  @override
  String groupMembersConfirmSelected(Object count) {
    return 'Confirm ($count)';
  }

  @override
  String get groupMembersCannotRemoveOwner => 'The owner cannot be removed';

  @override
  String get groupMembersCannotRemoveSelf => 'You cannot remove yourself';

  @override
  String get groupMembersSelectMembersToRemove => 'Select members to remove';

  @override
  String groupMembersRemoveConfirm(Object names) {
    return 'Remove the following members: $names?';
  }

  @override
  String get groupMembersAlreadyOwner => 'This member is already the owner';

  @override
  String get groupMembersSelectOtherMember => 'Select another group member';

  @override
  String get groupMembersThisMember => 'this member';

  @override
  String groupMembersTransferConfirm(Object name) {
    return 'Transfer group owner to $name?';
  }

  @override
  String groupMembersTransferredTo(Object name) {
    return 'Transferred to $name';
  }

  @override
  String get groupMembersTransferFailed => 'Failed to transfer group owner';

  @override
  String get groupMembersActionSuccess => 'Action completed';

  @override
  String get groupMembersMute24h => 'Mute for 24 hours';

  @override
  String groupMembersMutedUntil(
    Object month,
    Object day,
    Object hour,
    Object minute,
  ) {
    return 'Muted until $month-$day $hour:$minute';
  }

  @override
  String get groupSettingsViewAllMembers => 'View All Members';

  @override
  String get groupSettingsAdd => 'Add';

  @override
  String get groupSettingsRemove => 'Remove';

  @override
  String get groupSettingsGroupName => 'Group Name';

  @override
  String get groupSettingsGroupQrCode => 'Group QR Code';

  @override
  String get groupSettingsGroupNotice => 'Group Notice';

  @override
  String get groupSettingsGroupFiles => 'Group Files';

  @override
  String get groupSettingsChatHistory => 'Chat History';

  @override
  String get groupSettingsMute => 'Mute Notifications';

  @override
  String get groupSettingsPin => 'Pin Chat';

  @override
  String get groupSettingsMuteAll => 'Mute All Members';

  @override
  String get groupSettingsAllowInvite => 'Allow Member Invites';

  @override
  String get groupSettingsInviteConfirm => 'Invite Confirmation';

  @override
  String get groupSettingsJoinRequests => 'Join Requests';

  @override
  String get groupSettingsNickname => 'My Group Nickname';

  @override
  String get groupSettingsTransferOwner => 'Transfer Owner';

  @override
  String get groupSettingsDissolve => 'Dissolve Group';

  @override
  String get groupSettingsQuitGroup => 'Leave Group';

  @override
  String get groupSettingsClearHistory => 'Clear Chat History';

  @override
  String get groupSettingsOwner => 'Owner';

  @override
  String get groupSettingsAdmin => 'Admin';

  @override
  String get groupSettingsMember => 'Member';

  @override
  String get groupSettingsSetAdmin => 'Set as Admin';

  @override
  String get groupSettingsRemoveAdmin => 'Remove Admin';

  @override
  String get groupSettingsMuteMember => 'Mute Member';

  @override
  String get groupSettingsUnmuteMember => 'Unmute Member';

  @override
  String get groupSettingsMutedMember => 'Muted';

  @override
  String get groupSettingsEditGroupName => 'Edit Group Name';

  @override
  String get groupSettingsEditNickname => 'Edit My Nickname';

  @override
  String get groupSettingsInputHint => 'Enter content';

  @override
  String get groupSettingsConfirmAction => 'Confirm Action';

  @override
  String get groupSettingsConfirmClearHistory => 'Clear current chat history?';

  @override
  String get groupSettingsClearHistorySuccess => 'Chat history cleared';

  @override
  String get groupSettingsConfirmTransferOwner => 'Enter transfer owner flow?';

  @override
  String get groupSettingsTransferOwnerSuccess => 'Owner transferred';

  @override
  String groupSettingsConfirmSetAdmin(Object name) {
    return 'Set $name as admin?';
  }

  @override
  String groupSettingsConfirmRemoveAdmin(Object name) {
    return 'Remove admin role from $name?';
  }

  @override
  String groupSettingsConfirmMuteMember(Object name) {
    return 'Mute $name?';
  }

  @override
  String groupSettingsConfirmUnmuteMember(Object name) {
    return 'Unmute $name?';
  }

  @override
  String get groupSettingsSetAdminSuccess => 'Admin assigned';

  @override
  String get groupSettingsRemoveAdminSuccess => 'Admin removed';

  @override
  String get groupSettingsMuteMemberSuccess => 'Member muted';

  @override
  String get groupSettingsUnmuteMemberSuccess => 'Member unmuted';

  @override
  String get groupSettingsConfirmDissolve => 'Dissolve this group?';

  @override
  String get groupSettingsDissolveSuccess => 'Group dissolved';

  @override
  String get groupSettingsConfirmQuitGroup => 'Leave this group?';

  @override
  String get groupSettingsQuitGroupSuccess => 'Left the group';

  @override
  String get groupSettingsRemoveMember => 'Remove Member';

  @override
  String get groupSettingsRemoveMemberSuccess => 'Member removed';

  @override
  String groupSettingsConfirmRemoveMember(Object name) {
    return 'Remove $name from the group?';
  }

  @override
  String get groupSettingsPendingEmpty => 'No pending requests';

  @override
  String groupSettingsPendingCount(Object count) {
    return '$count pending';
  }

  @override
  String get groupJoinRequestsTabPending => 'Pending';

  @override
  String get groupJoinRequestsTabProcessed => 'Processed';

  @override
  String get groupJoinRequestsEmptyPending => 'No pending requests';

  @override
  String get groupJoinRequestsEmptyProcessed => 'No processed requests';

  @override
  String get groupJoinRequestsStatusPending => 'Pending';

  @override
  String get groupJoinRequestsStatusApproved => 'Approved';

  @override
  String get groupJoinRequestsStatusRejected => 'Rejected';

  @override
  String groupJoinRequestsApplyTime(Object time) {
    return 'Applied at: $time';
  }

  @override
  String groupJoinRequestsHandleTime(Object time) {
    return 'Handled at: $time';
  }

  @override
  String groupJoinRequestsHandleResult(Object result) {
    return 'Result: $result';
  }

  @override
  String get groupJoinRequestsReject => 'Reject';

  @override
  String get groupJoinRequestsApprove => 'Approve';

  @override
  String get groupJoinRequestsApproved => 'Request approved';

  @override
  String get groupJoinRequestsRejected => 'Request rejected';

  @override
  String get groupJoinRequestsRejectTitle => 'Reject Request';

  @override
  String groupJoinRequestsRejectConfirm(Object name) {
    return 'Reject $name\'s request to join the group?';
  }

  @override
  String get groupJoinRequestsRejectedByAdmin => 'Rejected by admin';

  @override
  String get groupJoinRequestsUnknownMember => 'Unknown Member';

  @override
  String get groupJoinRequestsTimeUnknown => 'No processing time yet';

  @override
  String get groupSettingsSave => 'Save';

  @override
  String get groupSettingsDone => 'Done';

  @override
  String get groupSettingsManage => 'Manage';

  @override
  String groupSettingsRemoveSelected(Object count) {
    return 'Remove Selected ($count)';
  }

  @override
  String get groupSettingsSearchMembers => 'Search Members';

  @override
  String groupSettingsMembersCount(Object count) {
    return '$count members';
  }

  @override
  String get groupSettingsMemberDetail => 'Member Details';

  @override
  String get groupSettingsJoinTime => 'Joined At';

  @override
  String get groupSettingsJoinTimeUnknown => 'No join time yet';

  @override
  String get groupSettingsMuteUntil => 'Muted Until';

  @override
  String get groupSettingsMuteUntilUnknown => 'No mute end time yet';

  @override
  String get groupSettingsSendMessage => 'Send Message';

  @override
  String get groupSettingsViewProfile => 'View Profile';

  @override
  String get groupSettingsSetRole => 'Set Role';

  @override
  String get groupQrCodeSave => 'Save QR Code';

  @override
  String get groupQrCodeShare => 'Share';

  @override
  String get groupQrCodeHint =>
      'Scan to preview group info and join the group. Actual join rules and expiry follow server configuration.';

  @override
  String get groupQrCodeNeedApproval => 'Approval required';

  @override
  String get groupQrCodeCopySuccess => 'Invite code copied';

  @override
  String get groupQrCodeUnavailable => 'Invite code is unavailable';

  @override
  String get groupAnnouncementEdit => 'Edit';

  @override
  String get groupAnnouncementContent => 'Notice Content';

  @override
  String get groupAnnouncementEditTitle => 'Edit Group Notice';

  @override
  String get groupAnnouncementPlaceholder => 'Enter group notice';

  @override
  String get groupAnnouncementEmpty => 'No group notice yet';

  @override
  String get groupAnnouncementEmptyHint =>
      'After editing, it can be shown as a pinned announcement to members';

  @override
  String get groupAnnouncementPinned => 'Pinned Notice';

  @override
  String get groupAnnouncementPublisher => 'Publisher';

  @override
  String get groupAnnouncementPublishTime => 'Published At';

  @override
  String get groupAnnouncementOwnerFallback => 'Group Owner';

  @override
  String get groupAnnouncementNotifyMembers => 'Notify Members';

  @override
  String get groupAnnouncementNotifyMembersHint =>
      'Publishing will send a notice update to group members';

  @override
  String get groupAnnouncementPinNotice => 'Pin Notice';

  @override
  String get groupAnnouncementPinNoticeHint =>
      'When pinned, it will appear in the chat page top banner';

  @override
  String get groupAnnouncementPublish => 'Publish';

  @override
  String get groupAnnouncementTooLong =>
      'The group notice cannot exceed 500 characters';

  @override
  String get groupAnnouncementPublishSuccess => 'Group notice published';

  @override
  String get groupAnnouncementPublishNotifySuccess =>
      'Group notice published and members notified';

  @override
  String get groupAnnouncementCleared => 'Group notice cleared';

  @override
  String get groupAnnouncementPublishFailed => 'Failed to publish group notice';

  @override
  String get groupAnnouncementDiscardTitle => 'Discard this edit?';

  @override
  String get groupAnnouncementDiscardContent =>
      'Your current changes are not saved. Leave editing anyway?';

  @override
  String get groupFilesSearch => 'Search Group Files';

  @override
  String get groupFilesEmpty => 'No group files yet';

  @override
  String get groupFilesActionDownload => 'Download';

  @override
  String get groupFilesActionForward => 'Forward';

  @override
  String get groupFilesDownloadStarted => 'Download started';

  @override
  String get groupFilesDownloadFailed => 'Download failed';

  @override
  String get groupFilesForwardUnsupported =>
      'This file cannot be forwarded right now';

  @override
  String get groupHistorySearch => 'Search Chat History';

  @override
  String get groupHistoryEmpty => 'No related chat history';

  @override
  String get groupHistoryTimeUnknown => 'No sent time yet';

  @override
  String get groupHistorySenderUnknown => 'Unknown member';

  @override
  String get groupHistoryFilterAll => 'All';

  @override
  String get groupHistoryFilterFile => 'Files';

  @override
  String get groupHistoryFilterImage => 'Images';

  @override
  String get groupHistoryFilterLink => 'Links';

  @override
  String get favoritePageTitle => 'Message Favorites';

  @override
  String get favoritePageEmpty => 'No favorite messages';

  @override
  String get favoriteSearchPlaceholder => 'Search favorites';

  @override
  String get favoriteDetailTitle => 'Favorite Detail';

  @override
  String get favoriteDetailLoading => 'Loading...';

  @override
  String get favoriteDetailEmpty => 'No detail available';

  @override
  String get favoriteDetailSendToChat => 'Send to Chat';

  @override
  String get favoriteDetailTypeLink => 'Link';

  @override
  String get favoriteDetailTypeNote => 'Note';

  @override
  String get favoriteDetailTypeImage => 'Image';

  @override
  String get favoriteDetailTypeVideo => 'Video';

  @override
  String get favoriteDetailTypeFile => 'File';

  @override
  String get favoriteDetailTypeDefault => 'Message';

  @override
  String get favoriteDetailInvalidId => 'Invalid favorite id';

  @override
  String get favoriteDetailLoadFailed => 'Failed to load detail';

  @override
  String get favoriteDetailVideoUrlEmpty => 'Video URL is empty';

  @override
  String get favoriteDetailFileUrlEmpty => 'File URL is empty';

  @override
  String get favoriteTabDefault => 'Default';

  @override
  String get favoriteTabNormal => 'Messages';

  @override
  String get favoriteTabMedia => 'Images & Videos';

  @override
  String get favoriteTabFile => 'Files';

  @override
  String get favoriteCancelAction => 'Unfavorite';

  @override
  String get favoriteCancelSuccess => 'Removed from favorites';

  @override
  String get favoriteOpenFailed => 'Unable to open favorite detail';

  @override
  String get chatOpenFailed => 'Open failed';

  @override
  String get chatMessageDetailTitle => 'Message Detail';

  @override
  String get browserTitle => 'Secure Browser';

  @override
  String get browserSourceScan => 'Scan';

  @override
  String get browserSourceMessage => 'Message';

  @override
  String get browserSourceFile => 'File';

  @override
  String get browserSourceExternal => 'External';

  @override
  String get browserUnknownSafeLink => 'Unknown safe link';

  @override
  String get browserBlockedTitle => 'This content cannot be opened directly';

  @override
  String get browserBlockedDesc =>
      'This content is not a safe web link that can be opened directly. You can still copy it and handle it yourself.';

  @override
  String get browserBlockedLabel => 'Raw Content';

  @override
  String get browserEmptyContent => 'No content';

  @override
  String get browserCopyLink => 'Copy Link';

  @override
  String get browserCopyContent => 'Copy Content';

  @override
  String get browserOpenExternally => 'Open Externally';

  @override
  String get browserNothingToCopy => 'Nothing to copy';

  @override
  String get browserCopySuccess => 'Copied';

  @override
  String get browserOpenExternalFailed => 'Failed to open externally';

  @override
  String get browserFileLoadingTitle => 'Preparing document preview';

  @override
  String get browserFileLoadingDesc =>
      'Document conversion or loading may take a moment.';

  @override
  String get browserFileFailedTitle => 'Document preview failed';

  @override
  String get browserFileFailedDesc =>
      'This document cannot be previewed in-app right now. You can retry or open it externally.';

  @override
  String get favoriteStatusDeleted => 'Original message deleted';

  @override
  String get favoriteStatusRecalled => 'Original message recalled';

  @override
  String get favoriteStatusUnavailable => 'Original message unavailable';

  @override
  String get chatReadOnlyClosed => 'This conversation has been closed';

  @override
  String get chatGroupRemovedCannotSend =>
      'You were removed from the group and cannot send messages';

  @override
  String get chatGroupMuteAllEnabled => 'This group has muted all members';

  @override
  String get chatGroupMuteAllDisabled => 'This group has turned off mute-all';

  @override
  String chatGroupMutedUntil(Object time) {
    return 'Muted until $time';
  }

  @override
  String get chatGroupMutedNoSend => 'You are muted and cannot send messages';

  @override
  String get chatGroupYouUnmuted => 'You have been unmuted';

  @override
  String get chatGroupMemberMutedGeneric => 'A group member has been muted';

  @override
  String get chatGroupMemberUnmutedGeneric => 'A group member has been unmuted';

  @override
  String get chatGroupMemberAdded => 'A new member joined the group';

  @override
  String get chatGroupMemberRemoved => 'A member was removed from the group';

  @override
  String get chatGroupOwnerTransferred =>
      'Group ownership has been transferred';

  @override
  String chatGroupOwnerTransferredTo(Object name) {
    return 'Group ownership has been transferred to \"$name\"';
  }

  @override
  String chatGroupMemberAddedOne(Object firstName) {
    return '\"$firstName\" joined the group';
  }

  @override
  String chatGroupMemberAddedTwo(Object firstName, Object secondName) {
    return '\"$firstName\" and \"$secondName\" joined the group';
  }

  @override
  String chatGroupMemberAddedMany(
    Object firstName,
    Object secondName,
    Object otherCount,
  ) {
    return '\"$firstName\", \"$secondName\" and $otherCount others joined the group';
  }

  @override
  String chatGroupMemberRemovedNamed(Object name) {
    return '\"$name\" was removed from the group';
  }

  @override
  String get chatGroupMemberRoleSetAdmin => 'A group member was set as admin';

  @override
  String chatGroupMemberRoleSetAdminNamed(
    Object operatorName,
    Object targetName,
  ) {
    return '\"$operatorName\" set \"$targetName\" as admin';
  }

  @override
  String get chatGroupMemberRoleSetMember => 'A group member was set as member';

  @override
  String chatGroupMemberRoleSetMemberNamed(
    Object operatorName,
    Object targetName,
  ) {
    return '\"$operatorName\" set \"$targetName\" as member';
  }

  @override
  String chatGroupMemberMutedNamed(Object name) {
    return '\"$name\" has been muted';
  }

  @override
  String chatGroupMemberMutedUntil(Object name, Object time) {
    return '\"$name\" has been muted until $time';
  }

  @override
  String chatGroupMemberUnmutedNamed(Object name) {
    return '\"$name\" has been unmuted';
  }

  @override
  String get chatGroupYouAreNewOwner => 'You are now the group owner';

  @override
  String get chatGroupYouTransferredOwner =>
      'You transferred the group owner role';

  @override
  String get chatGroupSystemSender => 'System';

  @override
  String get chatGroupNoticeUpdated => 'The group notice has been updated';

  @override
  String get chatForwardEmptyTarget =>
      'No conversation available for forwarding';

  @override
  String get chatForwardTargetTitle => 'Choose Conversation';

  @override
  String get chatForwardTargetSummarySend => 'Send';

  @override
  String get chatForwardTargetSummaryForward => 'Forward';

  @override
  String get chatForwardTargetSummaryTo => 'to';

  @override
  String chatForwardTargetMessageCount(Object count) {
    return '$count message(s)';
  }

  @override
  String get chatForwardTargetSingleForward => 'Forward Individually';

  @override
  String get chatForwardTargetCombineForward => 'Forward as Merge';

  @override
  String get chatForwardTargetSending => 'Sending...';

  @override
  String get chatForwardTargetSent => 'Sent';

  @override
  String get chatForwardTargetForwarded => 'Forwarded';

  @override
  String get chatVideoPlayerTitle => 'Video';

  @override
  String get chatVideoPlayerLoadFailed => 'Failed to load video';

  @override
  String get chatVideoPlayerFallbackHint =>
      'Try again, or open this video in an external app.';

  @override
  String get chatVideoPlayerOpenExternally => 'Open Externally';

  @override
  String get chatVideoPlayerOpenExternalFailed => 'Failed to open externally';

  @override
  String get chatForwardTargetForwardFailed => 'Forward failed';

  @override
  String chatForwardTargetPartialSuccess(
    Object successCount,
    Object expectedCount,
  ) {
    return 'Partially succeeded $successCount/$expectedCount';
  }

  @override
  String get chatForwardSingle => 'Forward Individually';

  @override
  String get chatForwardCombine => 'Forward as Merge';

  @override
  String get chatForwardMenu => 'Forward';

  @override
  String get chatForwardSelectTarget => 'Choose Conversation';

  @override
  String get chatForwardDialogSend => 'Send';

  @override
  String get chatChooseForwardMessage => 'Choose messages to forward';

  @override
  String chatMaxSelectReached(Object count) {
    return 'You can select up to $count messages';
  }

  @override
  String get chatChooseDeleteMessage => 'Please select messages to delete';

  @override
  String get chatVoiceUploadRetry => 'Voice upload failed. Tap to retry';

  @override
  String chatMaxStickerReached(Object count) {
    return 'You can add up to $count stickers';
  }

  @override
  String chatSelectedCount(Object count) {
    return '$count selected';
  }

  @override
  String get chatForwardUnsupported =>
      'This file does not support forwarding yet';

  @override
  String chatForwardSuccess(Object title) {
    return 'Forwarded to $title';
  }

  @override
  String get chatForwardCombineDetailTitle => 'Forward Merge Detail';

  @override
  String get chatForwardCombineDetailInvalidParams => 'Invalid parameters';

  @override
  String get chatForwardCombineDetailLoading => 'Loading...';

  @override
  String get chatForwardCombineDetailContentUnavailable =>
      'Content unavailable';

  @override
  String get chatForwardCombineDetailQuoteTooDeep => 'Quote depth exceeded';

  @override
  String get chatForwardCombineDetailCircularReference =>
      'Circular reference detected';

  @override
  String chatForwardCombineDetailTodayAt(Object time) {
    return 'Today $time';
  }

  @override
  String chatForwardCombineDetailYesterdayAt(Object time) {
    return 'Yesterday $time';
  }

  @override
  String get chatForwardCombineDetailEmpty => 'No content';

  @override
  String get chatForwardCombineDetailLoadFailed => 'Load failed';

  @override
  String get chatRecallSuccess => 'Recalled';

  @override
  String get chatRecallConfirmTitle => 'Notice';

  @override
  String get chatRecallConfirmContent => 'Recall this message?';

  @override
  String get chatRecallFailed => 'Recall failed';

  @override
  String get chatRecallSelfTip => 'You recalled a message';

  @override
  String chatRecallOtherTip(Object operatorName) {
    return '$operatorName recalled a message';
  }

  @override
  String get chatCopySuccess => 'Message copied';

  @override
  String get chatFavoriteSuccess => 'Message favorited';

  @override
  String get chatDeleteSuccess => 'Deleted';

  @override
  String get chatDeleteFailed => 'Delete failed';

  @override
  String get chatDeleteConfirmTitle => 'Delete Message';

  @override
  String get chatDeleteConfirmContent => 'Delete this message?';

  @override
  String get chatRetryingMessage => 'Retrying message';

  @override
  String get chatHeaderGroupNotice => 'Group Notice';

  @override
  String get chatReadOnly => 'This conversation is read-only';

  @override
  String get chatMultiDeleteTitle => 'Reminder';

  @override
  String chatMultiDeleteContent(Object count) {
    return 'Are you sure you want to delete $count selected messages?';
  }

  @override
  String get chatMentionSearchPlaceholder => 'Search group members';

  @override
  String get chatMentionClose => 'Close';

  @override
  String get chatMentionLoading => 'Loading members...';

  @override
  String get chatMentionEmpty => 'No members available';

  @override
  String get chatMentionAllMembers => 'All Members';

  @override
  String get chatMentionAllMembersHint =>
      'Only the owner or admins can use this';

  @override
  String get chatPresenceOffline => 'Offline';

  @override
  String get chatPresenceOnline => 'Online';

  @override
  String get chatPresenceMobileOnline => 'Mobile Online';

  @override
  String get chatPresenceWebOnline => 'Web Online';

  @override
  String get chatPresenceMultiDeviceOnline => 'Multi-device Online';

  @override
  String get chatPresenceJustNowActive => 'Just active';

  @override
  String chatPresenceMinutesAgoActive(Object count) {
    return 'Active $count minutes ago';
  }

  @override
  String chatPresenceTodayActiveAt(Object time) {
    return 'Active today at $time';
  }

  @override
  String chatPresenceYesterdayActiveAt(Object time) {
    return 'Active yesterday at $time';
  }

  @override
  String chatPresenceWeekdayActiveAt(Object weekday, Object time) {
    return 'Active on $weekday at $time';
  }

  @override
  String get chatPresenceRecentlyActive => 'Recently active';

  @override
  String get chatPresenceSunday => 'Sunday';

  @override
  String get chatPresenceMonday => 'Monday';

  @override
  String get chatPresenceTuesday => 'Tuesday';

  @override
  String get chatPresenceWednesday => 'Wednesday';

  @override
  String get chatPresenceThursday => 'Thursday';

  @override
  String get chatPresenceFriday => 'Friday';

  @override
  String get chatPresenceSaturday => 'Saturday';

  @override
  String get chatTypingDirect => 'Typing...';

  @override
  String chatTypingNamed(Object name) {
    return '$name is typing...';
  }

  @override
  String chatTypingNamedMany(Object names) {
    return '$names and others are typing...';
  }

  @override
  String get chatRecordingSlideToCancel => 'Slide up to cancel';

  @override
  String get chatRecordingReleaseToCancelShort => 'Release to cancel';

  @override
  String get chatQuoteMessageMissing => 'The original message no longer exists';

  @override
  String get chatAnchorFallback =>
      'The original message could not be located. Latest messages are shown instead';

  @override
  String get chatNoMoreMessages => 'No more messages';

  @override
  String get chatPreviewUnknownSender => 'Unknown';

  @override
  String get chatPreviewMessage => 'Message';

  @override
  String get chatPreviewMessageDeleted => 'Original message deleted';

  @override
  String get chatPreviewImage => '[Image]';

  @override
  String get chatPreviewEmoji => '[Emoji]';

  @override
  String get chatPreviewSticker => '[Sticker]';

  @override
  String get chatPreviewVoice => '[Voice]';

  @override
  String get chatPreviewVideo => '[Video]';

  @override
  String get chatPreviewFile => '[File]';

  @override
  String chatPreviewFileWithName(Object name) {
    return '[File] $name';
  }

  @override
  String get chatPreviewLocation => '[Location]';

  @override
  String get chatPreviewContactCard => '[Contact Card]';

  @override
  String get chatPreviewChatHistory => '[Chat History]';

  @override
  String get chatPreviewRecalled => '[Message recalled]';

  @override
  String get chatCustomMessage => '[Custom Message]';

  @override
  String get chatClickToViewDetail => 'Tap to view details';

  @override
  String get chatActionFavoriteSticker => 'Add to Stickers';

  @override
  String get chatActionCopy => 'Copy';

  @override
  String get chatActionQuote => 'Quote Reply';

  @override
  String get chatActionFavorite => 'Favorite';

  @override
  String get chatActionRecall => 'Recall';

  @override
  String get chatActionDelete => 'Delete';

  @override
  String get chatActionMultiSelect => 'Multi-select';

  @override
  String get chatMoreActionCamera => 'Camera';

  @override
  String get chatMoreActionLocation => 'Location';

  @override
  String get chatMoreActionContactCard => 'Contact Card';

  @override
  String get chatMoreActionCall => 'Audio & Video';

  @override
  String get chatSelectLocationTitle => 'Select Location';

  @override
  String get chatSelectLocationSearchHint => 'Search location';

  @override
  String get chatSelectLocationSearchEmptyHint =>
      'Search by place name to pick a location';

  @override
  String get chatSelectLocationSendCurrent => 'Send current location';

  @override
  String get chatSelectLocationTapToLocate => 'Tap to send current location';

  @override
  String get chatSelectLocationNearbyTitle => 'Nearby places';

  @override
  String get chatSelectLocationSearchResultTitle => 'Search results';

  @override
  String get chatSelectLocationNoNearbyResult => 'No nearby places';

  @override
  String get chatSelectLocationNoSearchResult => 'No search results';

  @override
  String get chatSelectLocationQuotaTitle => 'Location search quota exhausted';

  @override
  String get chatSelectLocationQuotaDesc =>
      'Location lookup is temporarily unavailable, please try again later';

  @override
  String get chatSelectLocationQuotaTip =>
      'You can switch to another way to send a location first';

  @override
  String get chatSelectLocationServiceDisabledTitle =>
      'Location service disabled';

  @override
  String get chatSelectLocationServiceDisabledDesc =>
      'Location lookup service is not enabled in the current environment';

  @override
  String get chatSelectLocationChoose => 'Please choose a location';

  @override
  String get chatSelectLocationCurrentUnavailable =>
      'Current location is unavailable';

  @override
  String get chatCurrentLocationName => 'Current Location';

  @override
  String get chatLocationUnknownName => 'Unknown Location';

  @override
  String get chatLocationSendSuccess => 'Location sent';

  @override
  String get chatLocationMissing => 'Location coordinates are missing';

  @override
  String get chatLocationOpenFailed => 'Unable to open this location right now';

  @override
  String get chatLocationNavigateAction => 'Navigate';

  @override
  String get chatLocationCopyAction => 'Copy Location';

  @override
  String get chatLocationOpenUnsupported =>
      'This device cannot open maps directly right now. Copy the location details instead.';

  @override
  String get chatLocationDefaultTitle => 'Location';

  @override
  String chatLocationCoordinateFallback(Object lat, Object lng) {
    return 'Coordinates: $lat, $lng';
  }

  @override
  String get chatLocationCopied => 'Location details copied';

  @override
  String get chatSelectContactCardTitle => 'Select Contact';

  @override
  String get chatSelectContactCardSearchHint => 'Search contact';

  @override
  String get chatSelectContactCardLoading => 'Loading...';

  @override
  String get chatSelectContactCardEmpty => 'No contacts available';

  @override
  String get chatSelectContactCardLoadFailed => 'Failed to load contacts';

  @override
  String get chatSelectContactCardPlaceholder => 'Select 1 contact';

  @override
  String chatSelectContactCardSelected(Object name) {
    return 'Selected: $name';
  }

  @override
  String get chatContactCardLabel => 'Contact Card';

  @override
  String get chatContactCardUnknownName => 'Unknown Contact';

  @override
  String get chatContactCardSendSuccess => 'Contact card sent';

  @override
  String get chatContactMissing => 'The contact card target is missing';

  @override
  String get filePreviewTitle => 'File Preview';

  @override
  String get filePreviewForward => 'Forward';

  @override
  String get filePreviewPreview => 'Preview';

  @override
  String get filePreviewDownload => 'Download';

  @override
  String get filePreviewPreviewUnavailable =>
      'This file cannot be previewed right now';

  @override
  String get filePreviewDownloadStarted => 'Download started';

  @override
  String get filePreviewDownloadFailed => 'Download failed';

  @override
  String get filePreviewForwardUnsupported =>
      'This file cannot be forwarded right now';

  @override
  String get filePreviewModePdf => 'PDF Preview';

  @override
  String get filePreviewModeImage => 'Image Preview';

  @override
  String get filePreviewModeVideo => 'Video Preview';

  @override
  String get filePreviewModeAudio => 'Audio Preview';

  @override
  String get filePreviewModeText => 'Text Preview';

  @override
  String get filePreviewModeMarkdown => 'Markdown Preview';

  @override
  String get filePreviewModeServerPdf => 'Server PDF Preview';

  @override
  String get filePreviewModeServerHtml => 'Server HTML Preview';

  @override
  String get filePreviewModeOffice => 'Office Preview';

  @override
  String get filePreviewModeDownloadOnly => 'Download Only';

  @override
  String get filePreviewModeUnknown => 'File Preview';

  @override
  String get chatReadReceiptTitle => 'Read Receipt';

  @override
  String get chatReadReceiptClose => 'Close';

  @override
  String get chatReadReceiptReadLabel => 'Read';

  @override
  String get chatReadReceiptUnreadTab => 'Unread';

  @override
  String chatReadReceiptRead(Object count) {
    return 'Read $count';
  }

  @override
  String chatReadReceiptUnread(Object count) {
    return 'Unread $count';
  }

  @override
  String get chatReadReceiptVoiceHint =>
      'For voice messages, \"read\" is based on conversation read sequence and does not mean the audio was played';

  @override
  String chatReadReceiptTotal(Object count) {
    return 'Total recipients $count';
  }

  @override
  String get chatReadReceiptEmptyRead => 'No read records yet';

  @override
  String get chatReadReceiptEmptyUnread => 'No unread records';

  @override
  String get chatReadReceiptLoading => 'Loading...';

  @override
  String get chatReadReceiptNoMore => 'No more';

  @override
  String get chatReadReceiptUnreadLabel => 'Not read yet';

  @override
  String get chatReadReceiptUnknownUser => 'Unknown user';

  @override
  String get chatReadReceiptReadAtUnknown => 'Read time unavailable';

  @override
  String get chatReadReceiptPending => 'Processing';

  @override
  String get chatReadReceiptDataLoading =>
      'Read receipt data is still loading, please try again later';

  @override
  String get chatReadReceiptJustNow => 'Just now';

  @override
  String chatReadReceiptTodayAt(Object time) {
    return 'Today $time';
  }

  @override
  String chatReadReceiptYesterdayAt(Object time) {
    return 'Yesterday $time';
  }

  @override
  String get chatVoiceFileUnavailable => 'Voice file is unavailable';

  @override
  String get chatVoicePlayUrlFailed => 'Failed to get voice playback URL';

  @override
  String get chatStickerCannotAdd => 'This message cannot be added';

  @override
  String get chatStickerAdded => 'Added to stickers';

  @override
  String get chatStickerExists => 'Already in stickers';

  @override
  String get chatOtherUser => 'Other';

  @override
  String get chatReeditExpired => 'Re-edit has expired';

  @override
  String get chatReeditUnsupported =>
      'This message type does not support re-edit';

  @override
  String get chatReeditAction => 'Re-edit';

  @override
  String get chatRecordPermissionDenied =>
      'Recording failed. Please check microphone permission';

  @override
  String get chatRecordTooShort => 'Speaking time is too short';

  @override
  String get chatRecordFileCreateFailed =>
      'Failed to generate the recording file';

  @override
  String get chatUploading => 'Uploading';

  @override
  String get chatStickerAdd => 'Add';

  @override
  String get chatEmojiManage => 'Manage';

  @override
  String get chatEmojiTab => 'Emoji';

  @override
  String get chatStickerTab => 'Sticker';

  @override
  String get chatEmojiDelete => 'Delete';

  @override
  String get chatEmojiRecent => 'Recent';

  @override
  String get chatEmojiAll => 'All Emojis';

  @override
  String get backAction => 'Back';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get confirmAction => 'Confirm';
}
