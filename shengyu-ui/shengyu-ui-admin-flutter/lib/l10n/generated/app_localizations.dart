import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'钰信'**
  String get appName;

  /// No description provided for @loginIntro.
  ///
  /// In en, this message translates to:
  /// **'Enterprise IM and collaboration entry'**
  String get loginIntro;

  /// No description provided for @enterConversation.
  ///
  /// In en, this message translates to:
  /// **'Enter Conversations'**
  String get enterConversation;

  /// No description provided for @backAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backAction;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmAction;

  /// No description provided for @doneAction.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneAction;

  /// No description provided for @organizeAction.
  ///
  /// In en, this message translates to:
  /// **'Organize'**
  String get organizeAction;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get unknownError;

  /// No description provided for @searchAction.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchAction;

  /// No description provided for @resetAction.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetAction;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// No description provided for @searchMinLength.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters'**
  String get searchMinLength;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @usernamePasswordLogin.
  ///
  /// In en, this message translates to:
  /// **'Account Login'**
  String get usernamePasswordLogin;

  /// No description provided for @phoneLogin.
  ///
  /// In en, this message translates to:
  /// **'Phone Login'**
  String get phoneLogin;

  /// No description provided for @loginAction.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginAction;

  /// No description provided for @conversationTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get conversationTitle;

  /// No description provided for @emptyConversation.
  ///
  /// In en, this message translates to:
  /// **'No conversations'**
  String get emptyConversation;

  /// No description provided for @conversationShortcutRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get conversationShortcutRecent;

  /// No description provided for @conversationShortcutUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get conversationShortcutUsers;

  /// No description provided for @conversationShortcutGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get conversationShortcutGroups;

  /// No description provided for @conversationShortcutMention.
  ///
  /// In en, this message translates to:
  /// **'Mentions'**
  String get conversationShortcutMention;

  /// No description provided for @conversationShortcutMute.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get conversationShortcutMute;

  /// No description provided for @chatPageReadOnlyBannerKicked.
  ///
  /// In en, this message translates to:
  /// **'You have been removed from the group chat and cannot send or receive messages'**
  String get chatPageReadOnlyBannerKicked;

  /// No description provided for @chatPageReadOnlyBannerLeft.
  ///
  /// In en, this message translates to:
  /// **'You have left the group chat and cannot send or receive messages'**
  String get chatPageReadOnlyBannerLeft;

  /// No description provided for @chatPageReadOnlyBannerDisbanded.
  ///
  /// In en, this message translates to:
  /// **'This group chat has been dissolved and cannot send or receive messages'**
  String get chatPageReadOnlyBannerDisbanded;

  /// No description provided for @chatPageBackToConversations.
  ///
  /// In en, this message translates to:
  /// **'Back to Conversations'**
  String get chatPageBackToConversations;

  /// No description provided for @contactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsTitle;

  /// No description provided for @contactsMyGroups.
  ///
  /// In en, this message translates to:
  /// **'My Groups'**
  String get contactsMyGroups;

  /// No description provided for @contactsFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get contactsFavorites;

  /// No description provided for @contactsOrganization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get contactsOrganization;

  /// No description provided for @contactsDepartments.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get contactsDepartments;

  /// No description provided for @contactsDepartmentDataConnected.
  ///
  /// In en, this message translates to:
  /// **'This page is now wired to the formal department and member endpoints.'**
  String get contactsDepartmentDataConnected;

  /// No description provided for @contactsOrganizationDataConnected.
  ///
  /// In en, this message translates to:
  /// **'This page is now wired to the formal organization tree endpoint.'**
  String get contactsOrganizationDataConnected;

  /// No description provided for @contactsCountPeople.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No people} =1{1 person} other{{count} people}}'**
  String contactsCountPeople(int count);

  /// No description provided for @contactsProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'User Details'**
  String get contactsProfileTitle;

  /// No description provided for @contactsPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get contactsPhoneLabel;

  /// No description provided for @contactsEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get contactsEmailLabel;

  /// No description provided for @contactsPostLabel.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get contactsPostLabel;

  /// No description provided for @contactsDetailMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get contactsDetailMore;

  /// No description provided for @contactsDetailFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get contactsDetailFollow;

  /// No description provided for @contactsDetailUnfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get contactsDetailUnfollow;

  /// No description provided for @contactsDetailShareCard.
  ///
  /// In en, this message translates to:
  /// **'Share Contact Card'**
  String get contactsDetailShareCard;

  /// No description provided for @contactsDetailName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get contactsDetailName;

  /// No description provided for @contactsDetailMobile.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get contactsDetailMobile;

  /// No description provided for @contactsDetailEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get contactsDetailEmail;

  /// No description provided for @contactsDetailPost.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get contactsDetailPost;

  /// No description provided for @contactsDetailDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get contactsDetailDepartment;

  /// No description provided for @contactsDetailUnset.
  ///
  /// In en, this message translates to:
  /// **'Unset'**
  String get contactsDetailUnset;

  /// No description provided for @contactsDetailMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get contactsDetailMessage;

  /// No description provided for @contactsDetailCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get contactsDetailCall;

  /// No description provided for @contactsDetailInvalidUser.
  ///
  /// In en, this message translates to:
  /// **'Invalid user'**
  String get contactsDetailInvalidUser;

  /// No description provided for @contactsDetailFollowSuccess.
  ///
  /// In en, this message translates to:
  /// **'Followed'**
  String get contactsDetailFollowSuccess;

  /// No description provided for @contactsDetailUnfollowSuccess.
  ///
  /// In en, this message translates to:
  /// **'Unfollowed'**
  String get contactsDetailUnfollowSuccess;

  /// No description provided for @contactsDetailActionFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Action failed, please retry'**
  String get contactsDetailActionFailedRetry;

  /// No description provided for @contactsDetailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load user details'**
  String get contactsDetailLoadFailed;

  /// No description provided for @contactsDetailCallInDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Calling is under development'**
  String get contactsDetailCallInDevelopment;

  /// No description provided for @contactsDetailShareUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Contact card sharing is not wired yet'**
  String get contactsDetailShareUnsupported;

  /// No description provided for @contactsSearchResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get contactsSearchResultTitle;

  /// No description provided for @contactsSearchKeyword.
  ///
  /// In en, this message translates to:
  /// **'Keyword: {keyword}'**
  String contactsSearchKeyword(String keyword);

  /// No description provided for @contactsSearchInputHint.
  ///
  /// In en, this message translates to:
  /// **'Search contacts or departments'**
  String get contactsSearchInputHint;

  /// No description provided for @contactsPeopleSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsPeopleSectionTitle;

  /// No description provided for @contactsDepartmentSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get contactsDepartmentSectionTitle;

  /// No description provided for @contactsSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get contactsSearchEmpty;

  /// No description provided for @contactsFavoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorite contacts yet'**
  String get contactsFavoritesEmpty;

  /// No description provided for @messagePreviewImage.
  ///
  /// In en, this message translates to:
  /// **'[Image]'**
  String get messagePreviewImage;

  /// No description provided for @messagePreviewVoice.
  ///
  /// In en, this message translates to:
  /// **'[Voice]'**
  String get messagePreviewVoice;

  /// No description provided for @messagePreviewVideo.
  ///
  /// In en, this message translates to:
  /// **'[Video]'**
  String get messagePreviewVideo;

  /// No description provided for @messagePreviewFile.
  ///
  /// In en, this message translates to:
  /// **'[File]'**
  String get messagePreviewFile;

  /// File message preview with filename
  ///
  /// In en, this message translates to:
  /// **'[File] {fileName}'**
  String messagePreviewFileWithName(String fileName);

  /// No description provided for @messagePreviewLocation.
  ///
  /// In en, this message translates to:
  /// **'[Location]'**
  String get messagePreviewLocation;

  /// No description provided for @messagePreviewEmoji.
  ///
  /// In en, this message translates to:
  /// **'[Emoji]'**
  String get messagePreviewEmoji;

  /// No description provided for @messagePreviewSticker.
  ///
  /// In en, this message translates to:
  /// **'[Sticker]'**
  String get messagePreviewSticker;

  /// No description provided for @messagePreviewContactCard.
  ///
  /// In en, this message translates to:
  /// **'[Contact Card]'**
  String get messagePreviewContactCard;

  /// No description provided for @messagePreviewForward.
  ///
  /// In en, this message translates to:
  /// **'[Chat History]'**
  String get messagePreviewForward;

  /// No description provided for @messagePreviewSystem.
  ///
  /// In en, this message translates to:
  /// **'[System]'**
  String get messagePreviewSystem;

  /// No description provided for @messagePreviewCallRecord.
  ///
  /// In en, this message translates to:
  /// **'[Call Record]'**
  String get messagePreviewCallRecord;

  /// No description provided for @messagePreviewMePrefix.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get messagePreviewMePrefix;

  /// Prefix for self-sent message in conversation list
  ///
  /// In en, this message translates to:
  /// **'Me:{summary}'**
  String messagePreviewMePrefixColon(String summary);

  /// No description provided for @messagePreviewUnknownSender.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get messagePreviewUnknownSender;

  /// Prefix for other-sent message in conversation list
  ///
  /// In en, this message translates to:
  /// **'{sender}:{summary}'**
  String messagePreviewSenderColon(String sender, String summary);

  /// No description provided for @conversationPinnedNotice.
  ///
  /// In en, this message translates to:
  /// **'Conversation pinned'**
  String get conversationPinnedNotice;

  /// No description provided for @conversationUnpinnedNotice.
  ///
  /// In en, this message translates to:
  /// **'Conversation unpinned'**
  String get conversationUnpinnedNotice;

  /// No description provided for @conversationMarkedReadNotice.
  ///
  /// In en, this message translates to:
  /// **'Marked as read'**
  String get conversationMarkedReadNotice;

  /// No description provided for @conversationMarkedUnreadNotice.
  ///
  /// In en, this message translates to:
  /// **'Marked as unread'**
  String get conversationMarkedUnreadNotice;

  /// No description provided for @conversationDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation'**
  String get conversationDeleteDialogTitle;

  /// No description provided for @conversationDeleteDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This will remove the conversation from your list.'**
  String get conversationDeleteDialogContent;

  /// No description provided for @conversationDeletedNotice.
  ///
  /// In en, this message translates to:
  /// **'Conversation deleted'**
  String get conversationDeletedNotice;

  /// Generic error toast message with technical detail
  ///
  /// In en, this message translates to:
  /// **'Operation failed: {error}'**
  String operationFailed(String error);

  /// No description provided for @systemEventGroupNoticeUpdated.
  ///
  /// In en, this message translates to:
  /// **'The group notice has been updated'**
  String get systemEventGroupNoticeUpdated;

  /// No description provided for @systemEventGroupMuteAllEnabled.
  ///
  /// In en, this message translates to:
  /// **'This group has muted all members'**
  String get systemEventGroupMuteAllEnabled;

  /// No description provided for @systemEventGroupMuteAllDisabled.
  ///
  /// In en, this message translates to:
  /// **'This group has turned off mute-all'**
  String get systemEventGroupMuteAllDisabled;

  /// No description provided for @systemEventGroupMemberAdded.
  ///
  /// In en, this message translates to:
  /// **'A new member joined the group'**
  String get systemEventGroupMemberAdded;

  /// No description provided for @systemEventGroupMemberRemoved.
  ///
  /// In en, this message translates to:
  /// **'A member was removed from the group'**
  String get systemEventGroupMemberRemoved;

  /// No description provided for @systemEventGroupOwnerTransferred.
  ///
  /// In en, this message translates to:
  /// **'Group ownership has been transferred'**
  String get systemEventGroupOwnerTransferred;

  /// No description provided for @systemEventGroupMemberRoleSetAdmin.
  ///
  /// In en, this message translates to:
  /// **'A group member was set as admin'**
  String get systemEventGroupMemberRoleSetAdmin;

  /// No description provided for @systemEventGroupMemberRoleSetMember.
  ///
  /// In en, this message translates to:
  /// **'A group member was set as member'**
  String get systemEventGroupMemberRoleSetMember;

  /// No description provided for @systemEventGroupMemberMuted.
  ///
  /// In en, this message translates to:
  /// **'A group member has been muted'**
  String get systemEventGroupMemberMuted;

  /// No description provided for @systemEventGroupMemberUnmuted.
  ///
  /// In en, this message translates to:
  /// **'A group member has been unmuted'**
  String get systemEventGroupMemberUnmuted;

  /// No description provided for @systemEventGroupMemberAddedWithName.
  ///
  /// In en, this message translates to:
  /// **'\"{firstName}\" joined the group'**
  String systemEventGroupMemberAddedWithName(String firstName);

  /// No description provided for @systemEventGroupMemberRemovedWithName.
  ///
  /// In en, this message translates to:
  /// **'\"{firstName}\" was removed from the group'**
  String systemEventGroupMemberRemovedWithName(String firstName);

  /// No description provided for @systemEventGroupOwnerTransferredTo.
  ///
  /// In en, this message translates to:
  /// **'Group ownership has been transferred to \"{firstName}\"'**
  String systemEventGroupOwnerTransferredTo(String firstName);

  /// No description provided for @systemEventGroupMemberRoleSetAdminWithName.
  ///
  /// In en, this message translates to:
  /// **'\"{firstName}\" was set as admin'**
  String systemEventGroupMemberRoleSetAdminWithName(String firstName);

  /// No description provided for @systemEventGroupMemberRoleSetMemberWithName.
  ///
  /// In en, this message translates to:
  /// **'\"{firstName}\" was set as member'**
  String systemEventGroupMemberRoleSetMemberWithName(String firstName);

  /// No description provided for @systemEventGroupMemberMutedWithName.
  ///
  /// In en, this message translates to:
  /// **'\"{firstName}\" has been muted'**
  String systemEventGroupMemberMutedWithName(String firstName);

  /// No description provided for @systemEventGroupMemberUnmutedWithName.
  ///
  /// In en, this message translates to:
  /// **'\"{firstName}\" has been unmuted'**
  String systemEventGroupMemberUnmutedWithName(String firstName);

  /// No description provided for @contactsListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get contactsListEmpty;

  /// No description provided for @contactsMyGroupsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get contactsMyGroupsEmpty;

  /// No description provided for @contactsDepartmentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No department members yet'**
  String get contactsDepartmentsEmpty;

  /// No description provided for @contactsOrganizationEmpty.
  ///
  /// In en, this message translates to:
  /// **'No organization data yet'**
  String get contactsOrganizationEmpty;

  /// No description provided for @contactsSectionRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent Contacts'**
  String get contactsSectionRecent;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @inputMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get inputMessage;

  /// No description provided for @chatTimeToday.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String chatTimeToday(String time);

  /// No description provided for @chatTimeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String chatTimeYesterday(String time);

  /// No description provided for @chatLoadOlder.
  ///
  /// In en, this message translates to:
  /// **'Load older messages'**
  String get chatLoadOlder;

  /// No description provided for @chatReadOnly.
  ///
  /// In en, this message translates to:
  /// **'This conversation is read-only'**
  String get chatReadOnly;

  /// No description provided for @chatReadOnlyClosed.
  ///
  /// In en, this message translates to:
  /// **'This conversation has been closed'**
  String get chatReadOnlyClosed;

  /// No description provided for @chatGroupRemovedCannotSend.
  ///
  /// In en, this message translates to:
  /// **'You were removed from the group and cannot send messages'**
  String get chatGroupRemovedCannotSend;

  /// No description provided for @chatGroupMuteAllEnabled.
  ///
  /// In en, this message translates to:
  /// **'This group has muted all members'**
  String get chatGroupMuteAllEnabled;

  /// No description provided for @chatGroupMuteAllDisabled.
  ///
  /// In en, this message translates to:
  /// **'This group has turned off mute-all'**
  String get chatGroupMuteAllDisabled;

  /// No description provided for @chatGroupMutedUntil.
  ///
  /// In en, this message translates to:
  /// **'Muted until {time}'**
  String chatGroupMutedUntil(String time);

  /// No description provided for @chatGroupMutedNoSend.
  ///
  /// In en, this message translates to:
  /// **'You are muted and cannot send messages'**
  String get chatGroupMutedNoSend;

  /// No description provided for @chatGroupYouUnmuted.
  ///
  /// In en, this message translates to:
  /// **'You have been unmuted'**
  String get chatGroupYouUnmuted;

  /// No description provided for @chatGroupMemberMutedGeneric.
  ///
  /// In en, this message translates to:
  /// **'A group member has been muted'**
  String get chatGroupMemberMutedGeneric;

  /// No description provided for @chatGroupMemberUnmutedGeneric.
  ///
  /// In en, this message translates to:
  /// **'A group member has been unmuted'**
  String get chatGroupMemberUnmutedGeneric;

  /// No description provided for @chatGroupMemberAdded.
  ///
  /// In en, this message translates to:
  /// **'A new member joined the group'**
  String get chatGroupMemberAdded;

  /// No description provided for @chatGroupMemberRemoved.
  ///
  /// In en, this message translates to:
  /// **'A member was removed from the group'**
  String get chatGroupMemberRemoved;

  /// No description provided for @chatGroupOwnerTransferred.
  ///
  /// In en, this message translates to:
  /// **'Group ownership has been transferred'**
  String get chatGroupOwnerTransferred;

  /// No description provided for @chatGroupOwnerTransferredTo.
  ///
  /// In en, this message translates to:
  /// **'Group ownership has been transferred to \"{name}\"'**
  String chatGroupOwnerTransferredTo(String name);

  /// No description provided for @chatGroupMemberAddedOne.
  ///
  /// In en, this message translates to:
  /// **'\"{firstName}\" joined the group'**
  String chatGroupMemberAddedOne(String firstName);

  /// No description provided for @chatGroupMemberAddedTwo.
  ///
  /// In en, this message translates to:
  /// **'\"{firstName}\" and \"{secondName}\" joined the group'**
  String chatGroupMemberAddedTwo(String firstName, String secondName);

  /// No description provided for @chatGroupMemberAddedMany.
  ///
  /// In en, this message translates to:
  /// **'\"{firstName}\", \"{secondName}\" and {otherCount, plural, =0{} =1{1 other} other{{otherCount} others}} joined the group'**
  String chatGroupMemberAddedMany(
    String firstName,
    String secondName,
    int otherCount,
  );

  /// No description provided for @chatGroupMemberRemovedNamed.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" was removed from the group'**
  String chatGroupMemberRemovedNamed(String name);

  /// No description provided for @chatGroupMemberRoleSetAdmin.
  ///
  /// In en, this message translates to:
  /// **'A group member was set as admin'**
  String get chatGroupMemberRoleSetAdmin;

  /// No description provided for @chatGroupMemberRoleSetAdminNamed.
  ///
  /// In en, this message translates to:
  /// **'\"{operatorName}\" set \"{targetName}\" as admin'**
  String chatGroupMemberRoleSetAdminNamed(
    String operatorName,
    String targetName,
  );

  /// No description provided for @chatGroupMemberRoleSetMember.
  ///
  /// In en, this message translates to:
  /// **'A group member was set as member'**
  String get chatGroupMemberRoleSetMember;

  /// No description provided for @chatGroupMemberRoleSetMemberNamed.
  ///
  /// In en, this message translates to:
  /// **'\"{operatorName}\" set \"{targetName}\" as member'**
  String chatGroupMemberRoleSetMemberNamed(
    String operatorName,
    String targetName,
  );

  /// No description provided for @chatGroupMemberMutedNamed.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" has been muted'**
  String chatGroupMemberMutedNamed(String name);

  /// No description provided for @chatGroupMemberMutedUntil.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" has been muted until {time}'**
  String chatGroupMemberMutedUntil(String name, String time);

  /// No description provided for @chatGroupMemberUnmutedNamed.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" has been unmuted'**
  String chatGroupMemberUnmutedNamed(String name);

  /// No description provided for @chatGroupYouAreNewOwner.
  ///
  /// In en, this message translates to:
  /// **'You are now the group owner'**
  String get chatGroupYouAreNewOwner;

  /// No description provided for @chatGroupYouTransferredOwner.
  ///
  /// In en, this message translates to:
  /// **'You transferred the group owner role'**
  String get chatGroupYouTransferredOwner;

  /// No description provided for @chatGroupSystemSender.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get chatGroupSystemSender;

  /// No description provided for @chatGroupNoticeUpdated.
  ///
  /// In en, this message translates to:
  /// **'The group notice has been updated'**
  String get chatGroupNoticeUpdated;

  /// No description provided for @messageSending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get messageSending;

  /// No description provided for @messageSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get messageSent;

  /// No description provided for @messageDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get messageDelivered;

  /// No description provided for @messageRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get messageRead;

  /// No description provided for @messageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get messageFailed;

  /// No description provided for @retrySend.
  ///
  /// In en, this message translates to:
  /// **'Retry sending'**
  String get retrySend;

  /// No description provided for @attachImageAction.
  ///
  /// In en, this message translates to:
  /// **'Send image'**
  String get attachImageAction;

  /// No description provided for @attachFileAction.
  ///
  /// In en, this message translates to:
  /// **'Send file'**
  String get attachFileAction;

  /// No description provided for @attachmentCapabilityPending.
  ///
  /// In en, this message translates to:
  /// **'Attachment picker is being wired'**
  String get attachmentCapabilityPending;

  /// No description provided for @chatOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Open failed'**
  String get chatOpenFailed;

  /// No description provided for @chatNoMoreMessages.
  ///
  /// In en, this message translates to:
  /// **'No more messages'**
  String get chatNoMoreMessages;

  /// No description provided for @chatPreviewUnknownSender.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get chatPreviewUnknownSender;

  /// No description provided for @chatPreviewMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get chatPreviewMessage;

  /// No description provided for @chatPreviewMessageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Original message deleted'**
  String get chatPreviewMessageDeleted;

  /// No description provided for @chatPreviewImage.
  ///
  /// In en, this message translates to:
  /// **'[Image]'**
  String get chatPreviewImage;

  /// No description provided for @chatPreviewEmoji.
  ///
  /// In en, this message translates to:
  /// **'[Emoji]'**
  String get chatPreviewEmoji;

  /// No description provided for @chatPreviewSticker.
  ///
  /// In en, this message translates to:
  /// **'[Sticker]'**
  String get chatPreviewSticker;

  /// No description provided for @chatPreviewVoice.
  ///
  /// In en, this message translates to:
  /// **'[Voice]'**
  String get chatPreviewVoice;

  /// No description provided for @chatPreviewVideo.
  ///
  /// In en, this message translates to:
  /// **'[Video]'**
  String get chatPreviewVideo;

  /// No description provided for @chatPreviewFile.
  ///
  /// In en, this message translates to:
  /// **'[File]'**
  String get chatPreviewFile;

  /// No description provided for @chatPreviewFileWithName.
  ///
  /// In en, this message translates to:
  /// **'[File] {name}'**
  String chatPreviewFileWithName(String name);

  /// No description provided for @chatPreviewLocation.
  ///
  /// In en, this message translates to:
  /// **'[Location]'**
  String get chatPreviewLocation;

  /// No description provided for @chatPreviewContactCard.
  ///
  /// In en, this message translates to:
  /// **'[Contact Card]'**
  String get chatPreviewContactCard;

  /// No description provided for @chatPreviewChatHistory.
  ///
  /// In en, this message translates to:
  /// **'[Chat History]'**
  String get chatPreviewChatHistory;

  /// No description provided for @chatPreviewRecalled.
  ///
  /// In en, this message translates to:
  /// **'[Message recalled]'**
  String get chatPreviewRecalled;

  /// No description provided for @chatCustomMessage.
  ///
  /// In en, this message translates to:
  /// **'[Custom Message]'**
  String get chatCustomMessage;

  /// No description provided for @chatClickToViewDetail.
  ///
  /// In en, this message translates to:
  /// **'Tap to view details'**
  String get chatClickToViewDetail;

  /// No description provided for @chatRecallSuccess.
  ///
  /// In en, this message translates to:
  /// **'Recalled'**
  String get chatRecallSuccess;

  /// No description provided for @chatRecallConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get chatRecallConfirmTitle;

  /// No description provided for @chatRecallConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Recall this message?'**
  String get chatRecallConfirmContent;

  /// No description provided for @chatRecallFailed.
  ///
  /// In en, this message translates to:
  /// **'Recall failed'**
  String get chatRecallFailed;

  /// No description provided for @chatRecallSelfTip.
  ///
  /// In en, this message translates to:
  /// **'You recalled a message'**
  String get chatRecallSelfTip;

  /// No description provided for @chatRecallOtherTip.
  ///
  /// In en, this message translates to:
  /// **'{operatorName} recalled a message'**
  String chatRecallOtherTip(String operatorName);

  /// No description provided for @chatCopySuccess.
  ///
  /// In en, this message translates to:
  /// **'Message copied'**
  String get chatCopySuccess;

  /// No description provided for @chatFavoriteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Message favorited'**
  String get chatFavoriteSuccess;

  /// No description provided for @chatDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get chatDeleteSuccess;

  /// No description provided for @chatDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get chatDeleteFailed;

  /// No description provided for @chatDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Message'**
  String get chatDeleteConfirmTitle;

  /// No description provided for @chatDeleteConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Delete this message?'**
  String get chatDeleteConfirmContent;

  /// No description provided for @chatRetryingMessage.
  ///
  /// In en, this message translates to:
  /// **'Retrying message'**
  String get chatRetryingMessage;

  /// No description provided for @chatHeaderGroupNotice.
  ///
  /// In en, this message translates to:
  /// **'Group Notice'**
  String get chatHeaderGroupNotice;

  /// No description provided for @chatMultiDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get chatMultiDeleteTitle;

  /// No description provided for @chatMultiDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count, plural, =1{1 selected message} other{{count} selected messages}}?'**
  String chatMultiDeleteContent(int count);

  /// No description provided for @chatVoiceUploadRetry.
  ///
  /// In en, this message translates to:
  /// **'Voice upload failed. Tap to retry'**
  String get chatVoiceUploadRetry;

  /// No description provided for @chatSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{None selected} =1{1 selected} other{{count} selected}}'**
  String chatSelectedCount(int count);

  /// No description provided for @chatForwardUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This file does not support forwarding yet'**
  String get chatForwardUnsupported;

  /// No description provided for @chatForwardSuccess.
  ///
  /// In en, this message translates to:
  /// **'Forwarded to {title}'**
  String chatForwardSuccess(String title);

  /// No description provided for @chatReeditExpired.
  ///
  /// In en, this message translates to:
  /// **'Re-edit has expired'**
  String get chatReeditExpired;

  /// No description provided for @chatReeditUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This message type does not support re-edit'**
  String get chatReeditUnsupported;

  /// No description provided for @chatReeditAction.
  ///
  /// In en, this message translates to:
  /// **'Re-edit'**
  String get chatReeditAction;

  /// No description provided for @chatRecordPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Recording failed. Please check microphone permission'**
  String get chatRecordPermissionDenied;

  /// No description provided for @chatRecordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Speaking time is too short'**
  String get chatRecordTooShort;

  /// No description provided for @chatRecordFileCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate the recording file'**
  String get chatRecordFileCreateFailed;

  /// No description provided for @chatUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get chatUploading;

  /// No description provided for @chatOtherUser.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get chatOtherUser;

  /// No description provided for @chatAnchorFallback.
  ///
  /// In en, this message translates to:
  /// **'The original message could not be located. Latest messages are shown instead'**
  String get chatAnchorFallback;

  /// No description provided for @chatQuoteMessageMissing.
  ///
  /// In en, this message translates to:
  /// **'The original message no longer exists'**
  String get chatQuoteMessageMissing;

  /// No description provided for @chatVoiceFileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice file is unavailable'**
  String get chatVoiceFileUnavailable;

  /// No description provided for @chatVoicePlayUrlFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get voice playback URL'**
  String get chatVoicePlayUrlFailed;

  /// No description provided for @chatFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File exceeds size limit (max {maxSize})'**
  String chatFileTooLarge(String maxSize);

  /// No description provided for @chatCameraPhotoLimit.
  ///
  /// In en, this message translates to:
  /// **'Photo exceeds size limit (max {maxSize})'**
  String chatCameraPhotoLimit(String maxSize);

  /// No description provided for @chatCameraVideoLimit.
  ///
  /// In en, this message translates to:
  /// **'Video exceeds size limit (max {maxSize})'**
  String chatCameraVideoLimit(String maxSize);

  /// No description provided for @chatCameraInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Camera initialization failed'**
  String get chatCameraInitFailed;

  /// No description provided for @chatCameraNotFound.
  ///
  /// In en, this message translates to:
  /// **'No camera available'**
  String get chatCameraNotFound;

  /// No description provided for @chatCameraTakePhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to take photo'**
  String get chatCameraTakePhotoFailed;

  /// No description provided for @chatCameraStartRecordFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start recording'**
  String get chatCameraStartRecordFailed;

  /// No description provided for @chatCameraStopRecordFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to stop recording'**
  String get chatCameraStopRecordFailed;

  /// No description provided for @chatScanHint.
  ///
  /// In en, this message translates to:
  /// **'Place the QR code inside the frame to scan automatically'**
  String get chatScanHint;

  /// No description provided for @chatActionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chatActionCopy;

  /// No description provided for @chatActionQuote.
  ///
  /// In en, this message translates to:
  /// **'Quote Reply'**
  String get chatActionQuote;

  /// No description provided for @chatActionFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get chatActionFavorite;

  /// No description provided for @chatActionRecall.
  ///
  /// In en, this message translates to:
  /// **'Recall'**
  String get chatActionRecall;

  /// No description provided for @chatActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chatActionDelete;

  /// No description provided for @chatActionMultiSelect.
  ///
  /// In en, this message translates to:
  /// **'Multi-select'**
  String get chatActionMultiSelect;

  /// No description provided for @chatMoreActionCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get chatMoreActionCamera;

  /// No description provided for @chatMoreActionCall.
  ///
  /// In en, this message translates to:
  /// **'Audio & Video'**
  String get chatMoreActionCall;

  /// No description provided for @chatMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat Media'**
  String get chatMediaTitle;

  /// No description provided for @chatMediaEmpty.
  ///
  /// In en, this message translates to:
  /// **'No media records'**
  String get chatMediaEmpty;

  /// No description provided for @chatMediaToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatMediaToday;

  /// No description provided for @chatMediaYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatMediaYesterday;

  /// No description provided for @chatMediaMonthDay.
  ///
  /// In en, this message translates to:
  /// **'{month}-{day}'**
  String chatMediaMonthDay(String month, String day);

  /// No description provided for @chatMediaLoadingMore.
  ///
  /// In en, this message translates to:
  /// **'Loading more...'**
  String get chatMediaLoadingMore;

  /// No description provided for @chatMediaNoMore.
  ///
  /// In en, this message translates to:
  /// **'No more items'**
  String get chatMediaNoMore;

  /// No description provided for @chatMediaPullMore.
  ///
  /// In en, this message translates to:
  /// **'Pull up to load more'**
  String get chatMediaPullMore;

  /// No description provided for @chatMediaFilterVideo.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get chatMediaFilterVideo;

  /// No description provided for @chatMediaImageFallback.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get chatMediaImageFallback;

  /// No description provided for @chatImagePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get chatImagePlaceholder;

  /// No description provided for @chatMediaFileFallback.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get chatMediaFileFallback;

  /// No description provided for @chatVideoPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get chatVideoPlayerTitle;

  /// No description provided for @chatVideoPlayerLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load video'**
  String get chatVideoPlayerLoadFailed;

  /// No description provided for @chatVideoPlayerFallbackHint.
  ///
  /// In en, this message translates to:
  /// **'Try again, or open this video in an external app.'**
  String get chatVideoPlayerFallbackHint;

  /// No description provided for @chatVideoPlayerOpenExternally.
  ///
  /// In en, this message translates to:
  /// **'Open Externally'**
  String get chatVideoPlayerOpenExternally;

  /// No description provided for @chatVideoPlayerOpenExternalFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open externally'**
  String get chatVideoPlayerOpenExternalFailed;

  /// No description provided for @chatHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat History'**
  String get chatHistoryTitle;

  /// No description provided for @chatHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No chat history'**
  String get chatHistoryEmpty;

  /// No description provided for @chatMessageDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Message Details'**
  String get chatMessageDetailTitle;

  /// No description provided for @chatHistorySearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search chat history'**
  String get chatHistorySearchPlaceholder;

  /// No description provided for @chatHistoryStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get chatHistoryStartTime;

  /// No description provided for @chatHistoryEndTime.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get chatHistoryEndTime;

  /// No description provided for @chatHistoryUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get chatHistoryUnlimited;

  /// No description provided for @chatHistoryEnterKeyword.
  ///
  /// In en, this message translates to:
  /// **'Enter a search keyword'**
  String get chatHistoryEnterKeyword;

  /// No description provided for @chatHistoryEmptySearched.
  ///
  /// In en, this message translates to:
  /// **'No matching chat history'**
  String get chatHistoryEmptySearched;

  /// No description provided for @chatHistoryEmptyIdle.
  ///
  /// In en, this message translates to:
  /// **'Enter a keyword to search chat history'**
  String get chatHistoryEmptyIdle;

  /// No description provided for @chatHistorySearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to search chat history'**
  String get chatHistorySearchFailed;

  /// No description provided for @chatHistoryNoMore.
  ///
  /// In en, this message translates to:
  /// **'No more items'**
  String get chatHistoryNoMore;

  /// No description provided for @chatHistoryLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get chatHistoryLoading;

  /// No description provided for @chatHistoryLocateFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to locate this message'**
  String get chatHistoryLocateFailed;

  /// No description provided for @chatHistoryUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get chatHistoryUnknownUser;

  /// No description provided for @chatHistoryStartAfterEnd.
  ///
  /// In en, this message translates to:
  /// **'Start time cannot be later than end time'**
  String get chatHistoryStartAfterEnd;

  /// No description provided for @chatHistoryEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End time cannot be earlier than start time'**
  String get chatHistoryEndBeforeStart;

  /// No description provided for @chatHistoryTodayAt.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String chatHistoryTodayAt(String time);

  /// No description provided for @chatHistoryYesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String chatHistoryYesterdayAt(String time);

  /// No description provided for @chatHistoryDaysAgoAt.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Today {time}} =1{Yesterday {time}} other{{count} days ago {time}}}'**
  String chatHistoryDaysAgoAt(int count, String time);

  /// No description provided for @chatHistoryMonthDayAt.
  ///
  /// In en, this message translates to:
  /// **'{month}-{day} {time}'**
  String chatHistoryMonthDayAt(int month, int day, String time);

  /// No description provided for @chatHistoryPreviewImage.
  ///
  /// In en, this message translates to:
  /// **'[Image]'**
  String get chatHistoryPreviewImage;

  /// No description provided for @chatHistoryPreviewVoice.
  ///
  /// In en, this message translates to:
  /// **'[Voice]'**
  String get chatHistoryPreviewVoice;

  /// No description provided for @chatHistoryPreviewVideo.
  ///
  /// In en, this message translates to:
  /// **'[Video]'**
  String get chatHistoryPreviewVideo;

  /// No description provided for @chatHistoryPreviewFile.
  ///
  /// In en, this message translates to:
  /// **'[File]'**
  String get chatHistoryPreviewFile;

  /// No description provided for @chatHistoryPreviewLocation.
  ///
  /// In en, this message translates to:
  /// **'[Location]'**
  String get chatHistoryPreviewLocation;

  /// No description provided for @chatHistoryPreviewEmoji.
  ///
  /// In en, this message translates to:
  /// **'[Emoji]'**
  String get chatHistoryPreviewEmoji;

  /// No description provided for @chatHistoryPreviewSticker.
  ///
  /// In en, this message translates to:
  /// **'[Animated Sticker]'**
  String get chatHistoryPreviewSticker;

  /// No description provided for @chatHistoryPreviewSystem.
  ///
  /// In en, this message translates to:
  /// **'[System Message]'**
  String get chatHistoryPreviewSystem;

  /// No description provided for @chatHistoryPreviewMessage.
  ///
  /// In en, this message translates to:
  /// **'[Message]'**
  String get chatHistoryPreviewMessage;

  /// No description provided for @globalChatSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Chat History'**
  String get globalChatSearchTitle;

  /// No description provided for @globalChatSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search chat history'**
  String get globalChatSearchPlaceholder;

  /// No description provided for @globalChatSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters to search'**
  String get globalChatSearchHint;

  /// No description provided for @globalChatSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching chat history'**
  String get globalChatSearchEmpty;

  /// No description provided for @globalChatSearchLoading.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get globalChatSearchLoading;

  /// No description provided for @globalChatSearchLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Pull up to load more'**
  String get globalChatSearchLoadMore;

  /// No description provided for @chatSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat Settings'**
  String get chatSettingsTitle;

  /// No description provided for @chatSettingsNoRoleInfo.
  ///
  /// In en, this message translates to:
  /// **'No role information'**
  String get chatSettingsNoRoleInfo;

  /// No description provided for @chatSettingsTop.
  ///
  /// In en, this message translates to:
  /// **'Pin Chat'**
  String get chatSettingsTop;

  /// No description provided for @chatSettingsNotify.
  ///
  /// In en, this message translates to:
  /// **'Mute Notifications'**
  String get chatSettingsNotify;

  /// No description provided for @chatSettingsChatFilesSingle.
  ///
  /// In en, this message translates to:
  /// **'Chat Files'**
  String get chatSettingsChatFilesSingle;

  /// No description provided for @chatSettingsClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat History'**
  String get chatSettingsClearHistory;

  /// No description provided for @chatSettingsClearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear the current chat history?'**
  String get chatSettingsClearHistoryConfirm;

  /// No description provided for @chatSettingsSubordinateTip.
  ///
  /// In en, this message translates to:
  /// **'Note: manage subordinate relationships from the matching contact detail page.'**
  String get chatSettingsSubordinateTip;

  /// No description provided for @chatSettingsPinned.
  ///
  /// In en, this message translates to:
  /// **'Chat pinned'**
  String get chatSettingsPinned;

  /// No description provided for @chatSettingsUnpinned.
  ///
  /// In en, this message translates to:
  /// **'Chat unpinned'**
  String get chatSettingsUnpinned;

  /// No description provided for @chatSettingsNotifyEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get chatSettingsNotifyEnabled;

  /// No description provided for @chatSettingsNotifyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Mute enabled'**
  String get chatSettingsNotifyDisabled;

  /// No description provided for @chatSettingsCleared.
  ///
  /// In en, this message translates to:
  /// **'Chat history cleared'**
  String get chatSettingsCleared;

  /// No description provided for @chatSettingsClearHistoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear chat history'**
  String get chatSettingsClearHistoryFailed;

  /// No description provided for @chatForwardEmptyTarget.
  ///
  /// In en, this message translates to:
  /// **'No conversation available for forwarding'**
  String get chatForwardEmptyTarget;

  /// No description provided for @chatForwardTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Conversation'**
  String get chatForwardTargetTitle;

  /// No description provided for @chatForwardTargetSummarySend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatForwardTargetSummarySend;

  /// No description provided for @chatForwardTargetSummaryForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get chatForwardTargetSummaryForward;

  /// No description provided for @chatForwardTargetSummaryTo.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get chatForwardTargetSummaryTo;

  /// No description provided for @chatForwardTargetMessageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No messages} =1{1 message} other{{count} messages}}'**
  String chatForwardTargetMessageCount(int count);

  /// No description provided for @chatForwardTargetSingleForward.
  ///
  /// In en, this message translates to:
  /// **'Forward Individually'**
  String get chatForwardTargetSingleForward;

  /// No description provided for @chatForwardTargetCombineForward.
  ///
  /// In en, this message translates to:
  /// **'Forward as Merge'**
  String get chatForwardTargetCombineForward;

  /// No description provided for @chatForwardTargetSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get chatForwardTargetSending;

  /// No description provided for @chatForwardTargetSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get chatForwardTargetSent;

  /// No description provided for @chatForwardTargetForwarded.
  ///
  /// In en, this message translates to:
  /// **'Forwarded'**
  String get chatForwardTargetForwarded;

  /// No description provided for @chatForwardTargetForwardFailed.
  ///
  /// In en, this message translates to:
  /// **'Forward failed'**
  String get chatForwardTargetForwardFailed;

  /// No description provided for @chatForwardTargetPartialSuccess.
  ///
  /// In en, this message translates to:
  /// **'Partially succeeded {successCount}/{expectedCount}'**
  String chatForwardTargetPartialSuccess(int successCount, int expectedCount);

  /// No description provided for @chatForwardSingle.
  ///
  /// In en, this message translates to:
  /// **'Forward Individually'**
  String get chatForwardSingle;

  /// No description provided for @chatForwardCombine.
  ///
  /// In en, this message translates to:
  /// **'Forward as Merge'**
  String get chatForwardCombine;

  /// No description provided for @chatForwardMenu.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get chatForwardMenu;

  /// No description provided for @chatForwardSelectTarget.
  ///
  /// In en, this message translates to:
  /// **'Choose Conversation'**
  String get chatForwardSelectTarget;

  /// No description provided for @chatForwardDialogSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatForwardDialogSend;

  /// No description provided for @chatChooseForwardMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose messages to forward'**
  String get chatChooseForwardMessage;

  /// No description provided for @chatMaxSelectReached.
  ///
  /// In en, this message translates to:
  /// **'You can select up to {count, plural, =1{1 message} other{{count} messages}}'**
  String chatMaxSelectReached(int count);

  /// No description provided for @chatChooseDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Please select messages to delete'**
  String get chatChooseDeleteMessage;

  /// No description provided for @chatForwardCombineDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Forward Merge Detail'**
  String get chatForwardCombineDetailTitle;

  /// No description provided for @chatForwardCombineDetailInvalidParams.
  ///
  /// In en, this message translates to:
  /// **'Invalid parameters'**
  String get chatForwardCombineDetailInvalidParams;

  /// No description provided for @chatForwardCombineDetailLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get chatForwardCombineDetailLoading;

  /// No description provided for @chatForwardCombineDetailContentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Content unavailable'**
  String get chatForwardCombineDetailContentUnavailable;

  /// No description provided for @chatForwardCombineDetailQuoteTooDeep.
  ///
  /// In en, this message translates to:
  /// **'Quote depth exceeded'**
  String get chatForwardCombineDetailQuoteTooDeep;

  /// No description provided for @chatForwardCombineDetailCircularReference.
  ///
  /// In en, this message translates to:
  /// **'Circular reference detected'**
  String get chatForwardCombineDetailCircularReference;

  /// No description provided for @chatForwardCombineDetailTodayAt.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String chatForwardCombineDetailTodayAt(String time);

  /// No description provided for @chatForwardCombineDetailYesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String chatForwardCombineDetailYesterdayAt(String time);

  /// No description provided for @chatForwardCombineDetailEmpty.
  ///
  /// In en, this message translates to:
  /// **'No content'**
  String get chatForwardCombineDetailEmpty;

  /// No description provided for @chatForwardCombineDetailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed'**
  String get chatForwardCombineDetailLoadFailed;

  /// No description provided for @chatReadReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Read Receipt'**
  String get chatReadReceiptTitle;

  /// No description provided for @chatReadReceiptClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get chatReadReceiptClose;

  /// No description provided for @chatReadReceiptReadLabel.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get chatReadReceiptReadLabel;

  /// No description provided for @chatReadReceiptUnreadTab.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get chatReadReceiptUnreadTab;

  /// No description provided for @chatReadReceiptRead.
  ///
  /// In en, this message translates to:
  /// **'Read {count, plural, =0{} =1{1 person} other{{count} people}}'**
  String chatReadReceiptRead(int count);

  /// No description provided for @chatReadReceiptUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread {count, plural, =0{} =1{1 person} other{{count} people}}'**
  String chatReadReceiptUnread(int count);

  /// No description provided for @chatReadReceiptVoiceHint.
  ///
  /// In en, this message translates to:
  /// **'For voice messages, \"read\" is based on conversation read sequence and does not mean the audio was played'**
  String get chatReadReceiptVoiceHint;

  /// No description provided for @chatReadReceiptTotal.
  ///
  /// In en, this message translates to:
  /// **'Total recipients {count, plural, =0{} =1{1 person} other{{count} people}}'**
  String chatReadReceiptTotal(int count);

  /// No description provided for @chatReadReceiptEmptyRead.
  ///
  /// In en, this message translates to:
  /// **'No read records yet'**
  String get chatReadReceiptEmptyRead;

  /// No description provided for @chatReadReceiptEmptyUnread.
  ///
  /// In en, this message translates to:
  /// **'No unread records'**
  String get chatReadReceiptEmptyUnread;

  /// No description provided for @chatReadReceiptLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get chatReadReceiptLoading;

  /// No description provided for @chatReadReceiptNoMore.
  ///
  /// In en, this message translates to:
  /// **'No more'**
  String get chatReadReceiptNoMore;

  /// No description provided for @chatReadReceiptUnreadLabel.
  ///
  /// In en, this message translates to:
  /// **'Not read yet'**
  String get chatReadReceiptUnreadLabel;

  /// No description provided for @chatReadReceiptUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get chatReadReceiptUnknownUser;

  /// No description provided for @chatReadReceiptReadAtUnknown.
  ///
  /// In en, this message translates to:
  /// **'Read time unavailable'**
  String get chatReadReceiptReadAtUnknown;

  /// No description provided for @chatReadReceiptPending.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get chatReadReceiptPending;

  /// No description provided for @chatReadReceiptDataLoading.
  ///
  /// In en, this message translates to:
  /// **'Read receipt data is still loading, please try again later'**
  String get chatReadReceiptDataLoading;

  /// No description provided for @chatReadReceiptJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get chatReadReceiptJustNow;

  /// No description provided for @chatReadReceiptTodayAt.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String chatReadReceiptTodayAt(String time);

  /// No description provided for @chatReadReceiptYesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String chatReadReceiptYesterdayAt(String time);

  /// No description provided for @chatPresenceOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get chatPresenceOffline;

  /// No description provided for @chatPresenceOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get chatPresenceOnline;

  /// No description provided for @chatPresenceMobileOnline.
  ///
  /// In en, this message translates to:
  /// **'Mobile Online'**
  String get chatPresenceMobileOnline;

  /// No description provided for @chatPresenceWebOnline.
  ///
  /// In en, this message translates to:
  /// **'Web Online'**
  String get chatPresenceWebOnline;

  /// No description provided for @chatPresenceMultiDeviceOnline.
  ///
  /// In en, this message translates to:
  /// **'Multi-device Online'**
  String get chatPresenceMultiDeviceOnline;

  /// No description provided for @chatPresenceJustNowActive.
  ///
  /// In en, this message translates to:
  /// **'Just active'**
  String get chatPresenceJustNowActive;

  /// No description provided for @chatPresenceMinutesAgoActive.
  ///
  /// In en, this message translates to:
  /// **'Active {count, plural, =0{just now} =1{1 minute ago} other{{count} minutes ago}}'**
  String chatPresenceMinutesAgoActive(int count);

  /// No description provided for @chatPresenceTodayActiveAt.
  ///
  /// In en, this message translates to:
  /// **'Active today at {time}'**
  String chatPresenceTodayActiveAt(String time);

  /// No description provided for @chatPresenceYesterdayActiveAt.
  ///
  /// In en, this message translates to:
  /// **'Active yesterday at {time}'**
  String chatPresenceYesterdayActiveAt(String time);

  /// No description provided for @chatPresenceWeekdayActiveAt.
  ///
  /// In en, this message translates to:
  /// **'Active on {weekday} at {time}'**
  String chatPresenceWeekdayActiveAt(String weekday, String time);

  /// No description provided for @chatPresenceRecentlyActive.
  ///
  /// In en, this message translates to:
  /// **'Recently active'**
  String get chatPresenceRecentlyActive;

  /// No description provided for @chatPresenceSunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get chatPresenceSunday;

  /// No description provided for @chatPresenceMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get chatPresenceMonday;

  /// No description provided for @chatPresenceTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get chatPresenceTuesday;

  /// No description provided for @chatPresenceWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get chatPresenceWednesday;

  /// No description provided for @chatPresenceThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get chatPresenceThursday;

  /// No description provided for @chatPresenceFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get chatPresenceFriday;

  /// No description provided for @chatPresenceSaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get chatPresenceSaturday;

  /// No description provided for @chatTypingDirect.
  ///
  /// In en, this message translates to:
  /// **'Typing...'**
  String get chatTypingDirect;

  /// No description provided for @chatTypingNamed.
  ///
  /// In en, this message translates to:
  /// **'{name} is typing...'**
  String chatTypingNamed(String name);

  /// No description provided for @chatTypingNamedMany.
  ///
  /// In en, this message translates to:
  /// **'{names} and others are typing...'**
  String chatTypingNamedMany(String names);

  /// No description provided for @chatRecordingSlideToCancel.
  ///
  /// In en, this message translates to:
  /// **'Slide up to cancel'**
  String get chatRecordingSlideToCancel;

  /// No description provided for @chatRecordingReleaseToCancelShort.
  ///
  /// In en, this message translates to:
  /// **'Release to cancel'**
  String get chatRecordingReleaseToCancelShort;

  /// No description provided for @chatActionFavoriteSticker.
  ///
  /// In en, this message translates to:
  /// **'Add to Stickers'**
  String get chatActionFavoriteSticker;

  /// No description provided for @chatStickerCannotAdd.
  ///
  /// In en, this message translates to:
  /// **'This message cannot be added'**
  String get chatStickerCannotAdd;

  /// No description provided for @chatStickerAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to stickers'**
  String get chatStickerAdded;

  /// No description provided for @chatStickerExists.
  ///
  /// In en, this message translates to:
  /// **'Already in stickers'**
  String get chatStickerExists;

  /// No description provided for @chatMaxStickerReached.
  ///
  /// In en, this message translates to:
  /// **'You can add up to {count, plural, =1{1 sticker} other{{count} stickers}}'**
  String chatMaxStickerReached(int count);

  /// No description provided for @chatStickerAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get chatStickerAdd;

  /// No description provided for @chatEmojiManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get chatEmojiManage;

  /// No description provided for @chatEmojiTab.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get chatEmojiTab;

  /// No description provided for @chatStickerTab.
  ///
  /// In en, this message translates to:
  /// **'Sticker'**
  String get chatStickerTab;

  /// No description provided for @chatEmojiDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chatEmojiDelete;

  /// No description provided for @chatEmojiRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get chatEmojiRecent;

  /// No description provided for @chatEmojiAll.
  ///
  /// In en, this message translates to:
  /// **'All Emojis'**
  String get chatEmojiAll;

  /// No description provided for @chatMoreActionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get chatMoreActionLocation;

  /// No description provided for @chatSelectLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get chatSelectLocationTitle;

  /// No description provided for @chatSelectLocationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search location'**
  String get chatSelectLocationSearchHint;

  /// No description provided for @chatSelectLocationSearchEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Search by place name to pick a location'**
  String get chatSelectLocationSearchEmptyHint;

  /// No description provided for @chatSelectLocationSendCurrent.
  ///
  /// In en, this message translates to:
  /// **'Send current location'**
  String get chatSelectLocationSendCurrent;

  /// No description provided for @chatSelectLocationTapToLocate.
  ///
  /// In en, this message translates to:
  /// **'Tap to send current location'**
  String get chatSelectLocationTapToLocate;

  /// No description provided for @chatSelectLocationNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby places'**
  String get chatSelectLocationNearbyTitle;

  /// No description provided for @chatSelectLocationSearchResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get chatSelectLocationSearchResultTitle;

  /// No description provided for @chatSelectLocationNoNearbyResult.
  ///
  /// In en, this message translates to:
  /// **'No nearby places'**
  String get chatSelectLocationNoNearbyResult;

  /// No description provided for @chatSelectLocationNoSearchResult.
  ///
  /// In en, this message translates to:
  /// **'No search results'**
  String get chatSelectLocationNoSearchResult;

  /// No description provided for @chatSelectLocationQuotaTitle.
  ///
  /// In en, this message translates to:
  /// **'Location search quota exhausted'**
  String get chatSelectLocationQuotaTitle;

  /// No description provided for @chatSelectLocationQuotaDesc.
  ///
  /// In en, this message translates to:
  /// **'Location lookup is temporarily unavailable, please try again later'**
  String get chatSelectLocationQuotaDesc;

  /// No description provided for @chatSelectLocationQuotaTip.
  ///
  /// In en, this message translates to:
  /// **'You can switch to another way to send a location first'**
  String get chatSelectLocationQuotaTip;

  /// No description provided for @chatSelectLocationServiceDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Location service disabled'**
  String get chatSelectLocationServiceDisabledTitle;

  /// No description provided for @chatSelectLocationServiceDisabledDesc.
  ///
  /// In en, this message translates to:
  /// **'Location lookup service is not enabled in the current environment'**
  String get chatSelectLocationServiceDisabledDesc;

  /// No description provided for @chatSelectLocationChoose.
  ///
  /// In en, this message translates to:
  /// **'Please choose a location'**
  String get chatSelectLocationChoose;

  /// No description provided for @chatSelectLocationCurrentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Current location is unavailable'**
  String get chatSelectLocationCurrentUnavailable;

  /// No description provided for @chatCurrentLocationName.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get chatCurrentLocationName;

  /// No description provided for @chatLocationUnknownName.
  ///
  /// In en, this message translates to:
  /// **'Unknown Location'**
  String get chatLocationUnknownName;

  /// No description provided for @chatLocationSendSuccess.
  ///
  /// In en, this message translates to:
  /// **'Location sent'**
  String get chatLocationSendSuccess;

  /// No description provided for @chatLocationMissing.
  ///
  /// In en, this message translates to:
  /// **'Location coordinates are missing'**
  String get chatLocationMissing;

  /// No description provided for @chatLocationOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open this location right now'**
  String get chatLocationOpenFailed;

  /// No description provided for @chatLocationNavigateAction.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get chatLocationNavigateAction;

  /// No description provided for @chatLocationCopyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy Location'**
  String get chatLocationCopyAction;

  /// No description provided for @chatLocationOpenUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This device cannot open maps directly right now. Copy the location details instead.'**
  String get chatLocationOpenUnsupported;

  /// No description provided for @chatLocationDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get chatLocationDefaultTitle;

  /// No description provided for @chatLocationCoordinateFallback.
  ///
  /// In en, this message translates to:
  /// **'Coordinates: {lat}, {lng}'**
  String chatLocationCoordinateFallback(String lat, String lng);

  /// No description provided for @chatLocationCopied.
  ///
  /// In en, this message translates to:
  /// **'Location details copied'**
  String get chatLocationCopied;

  /// No description provided for @chatLocationDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Details'**
  String get chatLocationDetailTitle;

  /// No description provided for @chatMoreActionContactCard.
  ///
  /// In en, this message translates to:
  /// **'Contact Card'**
  String get chatMoreActionContactCard;

  /// No description provided for @chatSelectContactCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Contact'**
  String get chatSelectContactCardTitle;

  /// No description provided for @chatSelectContactCardSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search contact'**
  String get chatSelectContactCardSearchHint;

  /// No description provided for @chatSelectContactCardLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get chatSelectContactCardLoading;

  /// No description provided for @chatSelectContactCardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No contacts available'**
  String get chatSelectContactCardEmpty;

  /// No description provided for @chatSelectContactCardLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load contacts'**
  String get chatSelectContactCardLoadFailed;

  /// No description provided for @chatSelectContactCardPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select 1 contact'**
  String get chatSelectContactCardPlaceholder;

  /// No description provided for @chatSelectContactCardSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected: {name}'**
  String chatSelectContactCardSelected(String name);

  /// No description provided for @chatContactCardLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Card'**
  String get chatContactCardLabel;

  /// No description provided for @chatContactCardUnknownName.
  ///
  /// In en, this message translates to:
  /// **'Unknown Contact'**
  String get chatContactCardUnknownName;

  /// No description provided for @chatContactCardSendSuccess.
  ///
  /// In en, this message translates to:
  /// **'Contact card sent'**
  String get chatContactCardSendSuccess;

  /// No description provided for @chatContactMissing.
  ///
  /// In en, this message translates to:
  /// **'The contact card target is missing'**
  String get chatContactMissing;

  /// No description provided for @filePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'File Preview'**
  String get filePreviewTitle;

  /// No description provided for @filePreviewForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get filePreviewForward;

  /// No description provided for @filePreviewPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get filePreviewPreview;

  /// No description provided for @filePreviewDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get filePreviewDownload;

  /// No description provided for @filePreviewPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This file cannot be previewed right now'**
  String get filePreviewPreviewUnavailable;

  /// No description provided for @filePreviewDownloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Download started'**
  String get filePreviewDownloadStarted;

  /// No description provided for @filePreviewDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get filePreviewDownloadFailed;

  /// No description provided for @filePreviewForwardUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This file cannot be forwarded right now'**
  String get filePreviewForwardUnsupported;

  /// No description provided for @filePreviewModePdf.
  ///
  /// In en, this message translates to:
  /// **'PDF Preview'**
  String get filePreviewModePdf;

  /// No description provided for @filePreviewModeImage.
  ///
  /// In en, this message translates to:
  /// **'Image Preview'**
  String get filePreviewModeImage;

  /// No description provided for @filePreviewModeVideo.
  ///
  /// In en, this message translates to:
  /// **'Video Preview'**
  String get filePreviewModeVideo;

  /// No description provided for @filePreviewModeAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio Preview'**
  String get filePreviewModeAudio;

  /// No description provided for @filePreviewModeText.
  ///
  /// In en, this message translates to:
  /// **'Text Preview'**
  String get filePreviewModeText;

  /// No description provided for @filePreviewModeMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Markdown Preview'**
  String get filePreviewModeMarkdown;

  /// No description provided for @filePreviewModeServerPdf.
  ///
  /// In en, this message translates to:
  /// **'Server PDF Preview'**
  String get filePreviewModeServerPdf;

  /// No description provided for @filePreviewModeServerHtml.
  ///
  /// In en, this message translates to:
  /// **'Server HTML Preview'**
  String get filePreviewModeServerHtml;

  /// No description provided for @filePreviewModeOffice.
  ///
  /// In en, this message translates to:
  /// **'Office Preview'**
  String get filePreviewModeOffice;

  /// No description provided for @filePreviewModeDownloadOnly.
  ///
  /// In en, this message translates to:
  /// **'Download Only'**
  String get filePreviewModeDownloadOnly;

  /// No description provided for @filePreviewModeUnknown.
  ///
  /// In en, this message translates to:
  /// **'File Preview'**
  String get filePreviewModeUnknown;

  /// No description provided for @browserTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure Browser'**
  String get browserTitle;

  /// No description provided for @browserSourceScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get browserSourceScan;

  /// No description provided for @browserSourceMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get browserSourceMessage;

  /// No description provided for @browserSourceFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get browserSourceFile;

  /// No description provided for @browserSourceExternal.
  ///
  /// In en, this message translates to:
  /// **'External'**
  String get browserSourceExternal;

  /// No description provided for @browserUnknownSafeLink.
  ///
  /// In en, this message translates to:
  /// **'Unknown safe link'**
  String get browserUnknownSafeLink;

  /// No description provided for @browserBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'This content cannot be opened directly'**
  String get browserBlockedTitle;

  /// No description provided for @browserBlockedDesc.
  ///
  /// In en, this message translates to:
  /// **'This content is not a safe web link that can be opened directly. You can still copy it and handle it yourself.'**
  String get browserBlockedDesc;

  /// No description provided for @browserBlockedLabel.
  ///
  /// In en, this message translates to:
  /// **'Raw Content'**
  String get browserBlockedLabel;

  /// No description provided for @browserEmptyContent.
  ///
  /// In en, this message translates to:
  /// **'No content'**
  String get browserEmptyContent;

  /// No description provided for @browserCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get browserCopyLink;

  /// No description provided for @browserCopyContent.
  ///
  /// In en, this message translates to:
  /// **'Copy Content'**
  String get browserCopyContent;

  /// No description provided for @browserOpenExternally.
  ///
  /// In en, this message translates to:
  /// **'Open Externally'**
  String get browserOpenExternally;

  /// No description provided for @browserNothingToCopy.
  ///
  /// In en, this message translates to:
  /// **'Nothing to copy'**
  String get browserNothingToCopy;

  /// No description provided for @browserCopySuccess.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get browserCopySuccess;

  /// No description provided for @browserOpenExternalFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open externally'**
  String get browserOpenExternalFailed;

  /// No description provided for @browserFileLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing document preview'**
  String get browserFileLoadingTitle;

  /// No description provided for @browserFileLoadingDesc.
  ///
  /// In en, this message translates to:
  /// **'Document conversion or loading may take a moment.'**
  String get browserFileLoadingDesc;

  /// No description provided for @browserFileFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Document preview failed'**
  String get browserFileFailedTitle;

  /// No description provided for @browserFileFailedDesc.
  ///
  /// In en, this message translates to:
  /// **'This document cannot be previewed in-app right now. You can retry or open it externally.'**
  String get browserFileFailedDesc;

  /// No description provided for @favoriteStatusDeleted.
  ///
  /// In en, this message translates to:
  /// **'Original message deleted'**
  String get favoriteStatusDeleted;

  /// No description provided for @favoriteStatusRecalled.
  ///
  /// In en, this message translates to:
  /// **'Original message recalled'**
  String get favoriteStatusRecalled;

  /// No description provided for @favoriteStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Original message unavailable'**
  String get favoriteStatusUnavailable;

  /// No description provided for @chatMentionSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search group members'**
  String get chatMentionSearchPlaceholder;

  /// No description provided for @chatMentionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get chatMentionClose;

  /// No description provided for @chatMentionLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading members...'**
  String get chatMentionLoading;

  /// No description provided for @chatMentionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No members available'**
  String get chatMentionEmpty;

  /// No description provided for @chatMentionAllMembers.
  ///
  /// In en, this message translates to:
  /// **'All Members'**
  String get chatMentionAllMembers;

  /// No description provided for @chatMentionAllMembersHint.
  ///
  /// In en, this message translates to:
  /// **'Only the owner or admins can use this'**
  String get chatMentionAllMembersHint;

  /// No description provided for @groupMemberAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This member is already in the group'**
  String get groupMemberAlreadyExists;

  /// No description provided for @groupMemberFull.
  ///
  /// In en, this message translates to:
  /// **'Group member limit reached'**
  String get groupMemberFull;

  /// No description provided for @groupMemberNotExists.
  ///
  /// In en, this message translates to:
  /// **'This member is no longer in the group'**
  String get groupMemberNotExists;

  /// No description provided for @groupMembersMute24h.
  ///
  /// In en, this message translates to:
  /// **'Mute for 24 hours'**
  String get groupMembersMute24h;

  /// No description provided for @groupMembersMutedUntil.
  ///
  /// In en, this message translates to:
  /// **'Muted until {month}-{day} {hour}:{minute}'**
  String groupMembersMutedUntil(
    String month,
    String day,
    String hour,
    String minute,
  );

  /// No description provided for @groupJoinApplySubmitted.
  ///
  /// In en, this message translates to:
  /// **'Join request submitted'**
  String get groupJoinApplySubmitted;

  /// No description provided for @groupJoinWaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for admin approval'**
  String get groupJoinWaitingApproval;

  /// No description provided for @groupJoinApproved.
  ///
  /// In en, this message translates to:
  /// **'Join request approved'**
  String get groupJoinApproved;

  /// No description provided for @groupJoinRejected.
  ///
  /// In en, this message translates to:
  /// **'Join request rejected'**
  String get groupJoinRejected;

  /// No description provided for @groupJoinWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Join request withdrawn'**
  String get groupJoinWithdrawn;

  /// No description provided for @groupJoinWithdrawFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to withdraw request'**
  String get groupJoinWithdrawFailed;

  /// No description provided for @groupInviteCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid invite code'**
  String get groupInviteCodeInvalid;

  /// No description provided for @groupInviteCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'Invite code expired'**
  String get groupInviteCodeExpired;

  /// No description provided for @groupInviteCodeUsageLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Invite code usage limit reached'**
  String get groupInviteCodeUsageLimitReached;

  /// No description provided for @groupDissolved.
  ///
  /// In en, this message translates to:
  /// **'Group dissolved'**
  String get groupDissolved;

  /// No description provided for @groupLeftStatus.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get groupLeftStatus;

  /// No description provided for @groupKickedStatus.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get groupKickedStatus;

  /// No description provided for @groupDisbandedStatus.
  ///
  /// In en, this message translates to:
  /// **'Dissolved'**
  String get groupDisbandedStatus;

  /// No description provided for @groupLeftCannotSend.
  ///
  /// In en, this message translates to:
  /// **'You have left this group and cannot send messages'**
  String get groupLeftCannotSend;

  /// No description provided for @groupKickedCannotSend.
  ///
  /// In en, this message translates to:
  /// **'You have been removed from the group and cannot send messages'**
  String get groupKickedCannotSend;

  /// No description provided for @groupDisbandedCannotSend.
  ///
  /// In en, this message translates to:
  /// **'This group has been dissolved and cannot send messages'**
  String get groupDisbandedCannotSend;

  /// No description provided for @groupSettingsLeftPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Left Group'**
  String get groupSettingsLeftPageTitle;

  /// No description provided for @groupSettingsKickedPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Removed from Group'**
  String get groupSettingsKickedPageTitle;

  /// No description provided for @groupSettingsDisbandedPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Dissolved'**
  String get groupSettingsDisbandedPageTitle;

  /// No description provided for @groupSettingsLeftHint.
  ///
  /// In en, this message translates to:
  /// **'You have left this group and cannot view group settings'**
  String get groupSettingsLeftHint;

  /// No description provided for @groupSettingsKickedHint.
  ///
  /// In en, this message translates to:
  /// **'You have been removed from the group by an admin and cannot view group settings'**
  String get groupSettingsKickedHint;

  /// No description provided for @groupSettingsDisbandedHint.
  ///
  /// In en, this message translates to:
  /// **'The group owner has dissolved this group and cannot view group settings'**
  String get groupSettingsDisbandedHint;

  /// No description provided for @groupSettingsBackToConversations.
  ///
  /// In en, this message translates to:
  /// **'Back to Conversations'**
  String get groupSettingsBackToConversations;

  /// No description provided for @groupSettingsReadOnlyBannerKicked.
  ///
  /// In en, this message translates to:
  /// **'You have been removed from the group chat and can only view historical information'**
  String get groupSettingsReadOnlyBannerKicked;

  /// No description provided for @groupSettingsReadOnlyBannerLeft.
  ///
  /// In en, this message translates to:
  /// **'You have left the group chat and can only view historical information'**
  String get groupSettingsReadOnlyBannerLeft;

  /// No description provided for @groupSettingsReadOnlyBannerDisbanded.
  ///
  /// In en, this message translates to:
  /// **'This group chat has been dissolved'**
  String get groupSettingsReadOnlyBannerDisbanded;

  /// No description provided for @groupSettingsReadOnlyBannerDefault.
  ///
  /// In en, this message translates to:
  /// **'You are no longer in the group'**
  String get groupSettingsReadOnlyBannerDefault;

  /// No description provided for @groupSettingsSnapshotTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Snapshot Time'**
  String get groupSettingsSnapshotTimeLabel;

  /// No description provided for @groupSettingsLeftTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Left Time'**
  String get groupSettingsLeftTimeLabel;

  /// No description provided for @groupSettingsCannotViewQrCode.
  ///
  /// In en, this message translates to:
  /// **'You cannot view this group QR code'**
  String get groupSettingsCannotViewQrCode;

  /// No description provided for @groupSettingsCannotViewQrCodeHint.
  ///
  /// In en, this message translates to:
  /// **'You are no longer in this group and cannot retrieve the group QR code'**
  String get groupSettingsCannotViewQrCodeHint;

  /// No description provided for @groupSettingsReadOnlyMembersHint.
  ///
  /// In en, this message translates to:
  /// **'You are no longer in this group and can only view the member list'**
  String get groupSettingsReadOnlyMembersHint;

  /// No description provided for @groupInviteCodeTenantMismatch.
  ///
  /// In en, this message translates to:
  /// **'This invite code does not belong to the current organization'**
  String get groupInviteCodeTenantMismatch;

  /// No description provided for @groupJoinRequestRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Requests are too frequent, please try again later'**
  String get groupJoinRequestRateLimited;

  /// No description provided for @groupMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Members'**
  String get groupMembersTitle;

  /// No description provided for @groupMembersTitleWithCount.
  ///
  /// In en, this message translates to:
  /// **'Group Members ({count})'**
  String groupMembersTitleWithCount(int count);

  /// No description provided for @groupMembersRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Members'**
  String get groupMembersRemoveTitle;

  /// No description provided for @groupMembersTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer Owner'**
  String get groupMembersTransferTitle;

  /// No description provided for @groupMembersConfirmSelected.
  ///
  /// In en, this message translates to:
  /// **'Confirm ({count})'**
  String groupMembersConfirmSelected(int count);

  /// No description provided for @groupMembersCannotRemoveOwner.
  ///
  /// In en, this message translates to:
  /// **'The owner cannot be removed'**
  String get groupMembersCannotRemoveOwner;

  /// No description provided for @groupMembersCannotRemoveSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot remove yourself'**
  String get groupMembersCannotRemoveSelf;

  /// No description provided for @groupMembersSelectMembersToRemove.
  ///
  /// In en, this message translates to:
  /// **'Select members to remove'**
  String get groupMembersSelectMembersToRemove;

  /// No description provided for @groupMembersRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove the following members: {names}?'**
  String groupMembersRemoveConfirm(String names);

  /// No description provided for @groupMembersAlreadyOwner.
  ///
  /// In en, this message translates to:
  /// **'This member is already the owner'**
  String get groupMembersAlreadyOwner;

  /// No description provided for @groupMembersSelectOtherMember.
  ///
  /// In en, this message translates to:
  /// **'Select another group member'**
  String get groupMembersSelectOtherMember;

  /// No description provided for @groupMembersThisMember.
  ///
  /// In en, this message translates to:
  /// **'this member'**
  String get groupMembersThisMember;

  /// No description provided for @groupMembersTransferConfirm.
  ///
  /// In en, this message translates to:
  /// **'Transfer group owner to {name}?'**
  String groupMembersTransferConfirm(String name);

  /// No description provided for @groupMembersTransferredTo.
  ///
  /// In en, this message translates to:
  /// **'Transferred to {name}'**
  String groupMembersTransferredTo(String name);

  /// No description provided for @groupMembersTransferFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to transfer group owner'**
  String get groupMembersTransferFailed;

  /// No description provided for @groupMembersActionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Action completed'**
  String get groupMembersActionSuccess;

  /// No description provided for @groupSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Settings'**
  String get groupSettingsTitle;

  /// No description provided for @groupSettingsViewAllMembers.
  ///
  /// In en, this message translates to:
  /// **'View All Members'**
  String get groupSettingsViewAllMembers;

  /// No description provided for @groupSettingsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get groupSettingsAdd;

  /// No description provided for @groupSettingsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get groupSettingsRemove;

  /// No description provided for @groupSettingsGroupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupSettingsGroupName;

  /// No description provided for @groupSettingsGroupQrCode.
  ///
  /// In en, this message translates to:
  /// **'Group QR Code'**
  String get groupSettingsGroupQrCode;

  /// No description provided for @groupSettingsGroupNotice.
  ///
  /// In en, this message translates to:
  /// **'Group Notice'**
  String get groupSettingsGroupNotice;

  /// No description provided for @groupSettingsGroupFiles.
  ///
  /// In en, this message translates to:
  /// **'Group Files'**
  String get groupSettingsGroupFiles;

  /// No description provided for @groupSettingsChatHistory.
  ///
  /// In en, this message translates to:
  /// **'Chat History'**
  String get groupSettingsChatHistory;

  /// No description provided for @groupSettingsMute.
  ///
  /// In en, this message translates to:
  /// **'Mute Notifications'**
  String get groupSettingsMute;

  /// No description provided for @groupSettingsPin.
  ///
  /// In en, this message translates to:
  /// **'Pin Chat'**
  String get groupSettingsPin;

  /// No description provided for @groupSettingsMuteAll.
  ///
  /// In en, this message translates to:
  /// **'Mute All Members'**
  String get groupSettingsMuteAll;

  /// No description provided for @groupSettingsAllowInvite.
  ///
  /// In en, this message translates to:
  /// **'Allow Member Invites'**
  String get groupSettingsAllowInvite;

  /// No description provided for @groupSettingsInviteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Invite Confirmation'**
  String get groupSettingsInviteConfirm;

  /// No description provided for @groupSettingsJoinRequests.
  ///
  /// In en, this message translates to:
  /// **'Join Requests'**
  String get groupSettingsJoinRequests;

  /// No description provided for @groupSettingsNickname.
  ///
  /// In en, this message translates to:
  /// **'My Group Nickname'**
  String get groupSettingsNickname;

  /// No description provided for @groupSettingsTransferOwner.
  ///
  /// In en, this message translates to:
  /// **'Transfer Owner'**
  String get groupSettingsTransferOwner;

  /// No description provided for @groupSettingsDissolve.
  ///
  /// In en, this message translates to:
  /// **'Dissolve Group'**
  String get groupSettingsDissolve;

  /// No description provided for @groupSettingsQuitGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave Group'**
  String get groupSettingsQuitGroup;

  /// No description provided for @groupSettingsClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat History'**
  String get groupSettingsClearHistory;

  /// No description provided for @groupSettingsOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get groupSettingsOwner;

  /// No description provided for @groupSettingsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get groupSettingsAdmin;

  /// No description provided for @groupSettingsMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get groupSettingsMember;

  /// No description provided for @groupSettingsSetAdmin.
  ///
  /// In en, this message translates to:
  /// **'Set as Admin'**
  String get groupSettingsSetAdmin;

  /// No description provided for @groupSettingsRemoveAdmin.
  ///
  /// In en, this message translates to:
  /// **'Remove Admin'**
  String get groupSettingsRemoveAdmin;

  /// No description provided for @groupSettingsMuteMember.
  ///
  /// In en, this message translates to:
  /// **'Mute Member'**
  String get groupSettingsMuteMember;

  /// No description provided for @groupSettingsUnmuteMember.
  ///
  /// In en, this message translates to:
  /// **'Unmute Member'**
  String get groupSettingsUnmuteMember;

  /// No description provided for @groupSettingsMutedMember.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get groupSettingsMutedMember;

  /// No description provided for @groupSettingsEditGroupName.
  ///
  /// In en, this message translates to:
  /// **'Edit Group Name'**
  String get groupSettingsEditGroupName;

  /// No description provided for @groupSettingsEditNickname.
  ///
  /// In en, this message translates to:
  /// **'Edit My Nickname'**
  String get groupSettingsEditNickname;

  /// No description provided for @groupSettingsInputHint.
  ///
  /// In en, this message translates to:
  /// **'Enter content'**
  String get groupSettingsInputHint;

  /// No description provided for @groupSettingsConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Action'**
  String get groupSettingsConfirmAction;

  /// No description provided for @groupSettingsConfirmClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear current chat history?'**
  String get groupSettingsConfirmClearHistory;

  /// No description provided for @groupSettingsClearHistorySuccess.
  ///
  /// In en, this message translates to:
  /// **'Chat history cleared'**
  String get groupSettingsClearHistorySuccess;

  /// No description provided for @groupSettingsConfirmTransferOwner.
  ///
  /// In en, this message translates to:
  /// **'Enter transfer owner flow?'**
  String get groupSettingsConfirmTransferOwner;

  /// No description provided for @groupSettingsTransferOwnerSuccess.
  ///
  /// In en, this message translates to:
  /// **'Owner transferred'**
  String get groupSettingsTransferOwnerSuccess;

  /// No description provided for @groupSettingsConfirmSetAdmin.
  ///
  /// In en, this message translates to:
  /// **'Set {name} as admin?'**
  String groupSettingsConfirmSetAdmin(String name);

  /// No description provided for @groupSettingsConfirmRemoveAdmin.
  ///
  /// In en, this message translates to:
  /// **'Remove admin role from {name}?'**
  String groupSettingsConfirmRemoveAdmin(String name);

  /// No description provided for @groupSettingsConfirmMuteMember.
  ///
  /// In en, this message translates to:
  /// **'Mute {name}?'**
  String groupSettingsConfirmMuteMember(String name);

  /// No description provided for @groupSettingsConfirmUnmuteMember.
  ///
  /// In en, this message translates to:
  /// **'Unmute {name}?'**
  String groupSettingsConfirmUnmuteMember(String name);

  /// No description provided for @groupSettingsSetAdminSuccess.
  ///
  /// In en, this message translates to:
  /// **'Admin assigned'**
  String get groupSettingsSetAdminSuccess;

  /// No description provided for @groupSettingsRemoveAdminSuccess.
  ///
  /// In en, this message translates to:
  /// **'Admin removed'**
  String get groupSettingsRemoveAdminSuccess;

  /// No description provided for @groupSettingsMuteMemberSuccess.
  ///
  /// In en, this message translates to:
  /// **'Member muted'**
  String get groupSettingsMuteMemberSuccess;

  /// No description provided for @groupSettingsUnmuteMemberSuccess.
  ///
  /// In en, this message translates to:
  /// **'Member unmuted'**
  String get groupSettingsUnmuteMemberSuccess;

  /// No description provided for @groupSettingsConfirmDissolve.
  ///
  /// In en, this message translates to:
  /// **'Dissolve this group?'**
  String get groupSettingsConfirmDissolve;

  /// No description provided for @groupSettingsDissolveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Group dissolved'**
  String get groupSettingsDissolveSuccess;

  /// No description provided for @groupSettingsConfirmQuitGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave this group?'**
  String get groupSettingsConfirmQuitGroup;

  /// No description provided for @groupSettingsQuitGroupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Left the group'**
  String get groupSettingsQuitGroupSuccess;

  /// No description provided for @groupSettingsRemoveMember.
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get groupSettingsRemoveMember;

  /// No description provided for @groupSettingsRemoveMemberSuccess.
  ///
  /// In en, this message translates to:
  /// **'Member removed'**
  String get groupSettingsRemoveMemberSuccess;

  /// No description provided for @groupSettingsConfirmRemoveMember.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the group?'**
  String groupSettingsConfirmRemoveMember(String name);

  /// No description provided for @groupSettingsPendingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get groupSettingsPendingEmpty;

  /// No description provided for @groupSettingsPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No pending} =1{1 pending} other{{count} pending}}'**
  String groupSettingsPendingCount(int count);

  /// No description provided for @groupSettingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get groupSettingsSave;

  /// No description provided for @groupSettingsDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get groupSettingsDone;

  /// No description provided for @groupSettingsManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get groupSettingsManage;

  /// No description provided for @groupSettingsRemoveSelected.
  ///
  /// In en, this message translates to:
  /// **'Remove Selected ({count})'**
  String groupSettingsRemoveSelected(int count);

  /// No description provided for @groupSettingsSearchMembers.
  ///
  /// In en, this message translates to:
  /// **'Search Members'**
  String get groupSettingsSearchMembers;

  /// No description provided for @groupSettingsMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No members} =1{1 member} other{{count} members}}'**
  String groupSettingsMembersCount(int count);

  /// No description provided for @groupSettingsMemberDetail.
  ///
  /// In en, this message translates to:
  /// **'Member Details'**
  String get groupSettingsMemberDetail;

  /// No description provided for @groupSettingsJoinTime.
  ///
  /// In en, this message translates to:
  /// **'Joined At'**
  String get groupSettingsJoinTime;

  /// No description provided for @groupSettingsJoinTimeUnknown.
  ///
  /// In en, this message translates to:
  /// **'No join time yet'**
  String get groupSettingsJoinTimeUnknown;

  /// No description provided for @groupSettingsMuteUntil.
  ///
  /// In en, this message translates to:
  /// **'Muted Until'**
  String get groupSettingsMuteUntil;

  /// No description provided for @groupSettingsMuteUntilUnknown.
  ///
  /// In en, this message translates to:
  /// **'No mute end time yet'**
  String get groupSettingsMuteUntilUnknown;

  /// No description provided for @groupSettingsSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get groupSettingsSendMessage;

  /// No description provided for @groupSettingsViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get groupSettingsViewProfile;

  /// No description provided for @groupSettingsSetRole.
  ///
  /// In en, this message translates to:
  /// **'Set Role'**
  String get groupSettingsSetRole;

  /// No description provided for @groupQrCodeSave.
  ///
  /// In en, this message translates to:
  /// **'Save QR Code'**
  String get groupQrCodeSave;

  /// No description provided for @groupQrCodeShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get groupQrCodeShare;

  /// No description provided for @groupQrCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Scan to preview group info and join the group. Actual join rules and expiry follow server configuration.'**
  String get groupQrCodeHint;

  /// No description provided for @groupQrCodeNeedApproval.
  ///
  /// In en, this message translates to:
  /// **'Approval required'**
  String get groupQrCodeNeedApproval;

  /// No description provided for @groupQrCodeNeedApprovalHint.
  ///
  /// In en, this message translates to:
  /// **'This invite code requires admin approval before joining the group'**
  String get groupQrCodeNeedApprovalHint;

  /// No description provided for @groupQrCodePermanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent'**
  String get groupQrCodePermanent;

  /// No description provided for @groupQrCodeCopySuccess.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied'**
  String get groupQrCodeCopySuccess;

  /// No description provided for @groupQrCodeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Invite code is unavailable'**
  String get groupQrCodeUnavailable;

  /// No description provided for @groupQrCodeRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh QR Code'**
  String get groupQrCodeRefresh;

  /// No description provided for @groupQrCodeRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get groupQrCodeRefreshing;

  /// No description provided for @groupQrCodeRefreshSuccess.
  ///
  /// In en, this message translates to:
  /// **'Refreshed successfully'**
  String get groupQrCodeRefreshSuccess;

  /// No description provided for @groupQrCodeRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Refresh failed'**
  String get groupQrCodeRefreshFailed;

  /// No description provided for @groupQrCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get groupQrCodeExpired;

  /// No description provided for @groupQrCodeLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading QR code...'**
  String get groupQrCodeLoading;

  /// No description provided for @groupJoinRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Requests'**
  String get groupJoinRequestsTitle;

  /// No description provided for @groupJoinRequestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get groupJoinRequestsEmpty;

  /// No description provided for @groupJoinRequestsTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get groupJoinRequestsTabPending;

  /// No description provided for @groupJoinRequestsTabProcessed.
  ///
  /// In en, this message translates to:
  /// **'Processed'**
  String get groupJoinRequestsTabProcessed;

  /// No description provided for @groupJoinRequestsEmptyPending.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get groupJoinRequestsEmptyPending;

  /// No description provided for @groupJoinRequestsEmptyProcessed.
  ///
  /// In en, this message translates to:
  /// **'No processed requests'**
  String get groupJoinRequestsEmptyProcessed;

  /// No description provided for @groupJoinRequestsStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get groupJoinRequestsStatusPending;

  /// No description provided for @groupJoinRequestsStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get groupJoinRequestsStatusApproved;

  /// No description provided for @groupJoinRequestsStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get groupJoinRequestsStatusRejected;

  /// No description provided for @groupJoinRequestsApplyTime.
  ///
  /// In en, this message translates to:
  /// **'Applied at: {time}'**
  String groupJoinRequestsApplyTime(String time);

  /// No description provided for @groupJoinRequestsHandleTime.
  ///
  /// In en, this message translates to:
  /// **'Handled at: {time}'**
  String groupJoinRequestsHandleTime(String time);

  /// No description provided for @groupJoinRequestsHandleResult.
  ///
  /// In en, this message translates to:
  /// **'Result: {result}'**
  String groupJoinRequestsHandleResult(String result);

  /// No description provided for @groupJoinRequestsReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get groupJoinRequestsReject;

  /// No description provided for @groupJoinRequestsApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get groupJoinRequestsApprove;

  /// No description provided for @groupJoinRequestsApproved.
  ///
  /// In en, this message translates to:
  /// **'Request approved'**
  String get groupJoinRequestsApproved;

  /// No description provided for @groupJoinRequestsRejected.
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get groupJoinRequestsRejected;

  /// No description provided for @groupJoinRequestsRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Request'**
  String get groupJoinRequestsRejectTitle;

  /// No description provided for @groupJoinRequestsRejectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reject {name}\'s request to join the group?'**
  String groupJoinRequestsRejectConfirm(String name);

  /// No description provided for @groupJoinRequestsRejectedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Rejected by admin'**
  String get groupJoinRequestsRejectedByAdmin;

  /// No description provided for @groupJoinRequestsUnknownMember.
  ///
  /// In en, this message translates to:
  /// **'Unknown Member'**
  String get groupJoinRequestsUnknownMember;

  /// No description provided for @groupJoinRequestsTimeUnknown.
  ///
  /// In en, this message translates to:
  /// **'No processing time yet'**
  String get groupJoinRequestsTimeUnknown;

  /// No description provided for @groupAnnouncementEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get groupAnnouncementEdit;

  /// No description provided for @groupAnnouncementContent.
  ///
  /// In en, this message translates to:
  /// **'Notice Content'**
  String get groupAnnouncementContent;

  /// No description provided for @groupAnnouncementEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Group Notice'**
  String get groupAnnouncementEditTitle;

  /// No description provided for @groupAnnouncementPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter group notice'**
  String get groupAnnouncementPlaceholder;

  /// No description provided for @groupAnnouncementEmpty.
  ///
  /// In en, this message translates to:
  /// **'No group notice yet'**
  String get groupAnnouncementEmpty;

  /// No description provided for @groupAnnouncementEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'After editing, it can be shown as a pinned announcement to members'**
  String get groupAnnouncementEmptyHint;

  /// No description provided for @groupAnnouncementPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned Notice'**
  String get groupAnnouncementPinned;

  /// No description provided for @groupAnnouncementPublisher.
  ///
  /// In en, this message translates to:
  /// **'Publisher'**
  String get groupAnnouncementPublisher;

  /// No description provided for @groupAnnouncementPublishTime.
  ///
  /// In en, this message translates to:
  /// **'Published At'**
  String get groupAnnouncementPublishTime;

  /// No description provided for @groupAnnouncementOwnerFallback.
  ///
  /// In en, this message translates to:
  /// **'Group Owner'**
  String get groupAnnouncementOwnerFallback;

  /// No description provided for @groupAnnouncementNotifyMembers.
  ///
  /// In en, this message translates to:
  /// **'Notify Members'**
  String get groupAnnouncementNotifyMembers;

  /// No description provided for @groupAnnouncementNotifyMembersHint.
  ///
  /// In en, this message translates to:
  /// **'Publishing will send a notice update to group members'**
  String get groupAnnouncementNotifyMembersHint;

  /// No description provided for @groupAnnouncementPinNotice.
  ///
  /// In en, this message translates to:
  /// **'Pin Notice'**
  String get groupAnnouncementPinNotice;

  /// No description provided for @groupAnnouncementPinNoticeHint.
  ///
  /// In en, this message translates to:
  /// **'When pinned, it will appear in the chat page top banner'**
  String get groupAnnouncementPinNoticeHint;

  /// No description provided for @groupAnnouncementPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get groupAnnouncementPublish;

  /// No description provided for @groupAnnouncementTooLong.
  ///
  /// In en, this message translates to:
  /// **'The group notice cannot exceed 500 characters'**
  String get groupAnnouncementTooLong;

  /// No description provided for @groupAnnouncementPublishSuccess.
  ///
  /// In en, this message translates to:
  /// **'Group notice published'**
  String get groupAnnouncementPublishSuccess;

  /// No description provided for @groupAnnouncementPublishNotifySuccess.
  ///
  /// In en, this message translates to:
  /// **'Group notice published and members notified'**
  String get groupAnnouncementPublishNotifySuccess;

  /// No description provided for @groupAnnouncementCleared.
  ///
  /// In en, this message translates to:
  /// **'Group notice cleared'**
  String get groupAnnouncementCleared;

  /// No description provided for @groupAnnouncementPublishFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to publish group notice'**
  String get groupAnnouncementPublishFailed;

  /// No description provided for @groupAnnouncementDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this edit?'**
  String get groupAnnouncementDiscardTitle;

  /// No description provided for @groupAnnouncementDiscardContent.
  ///
  /// In en, this message translates to:
  /// **'Your current changes are not saved. Leave editing anyway?'**
  String get groupAnnouncementDiscardContent;

  /// No description provided for @groupFilesSearch.
  ///
  /// In en, this message translates to:
  /// **'Search Group Files'**
  String get groupFilesSearch;

  /// No description provided for @groupFilesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No group files yet'**
  String get groupFilesEmpty;

  /// No description provided for @groupFilesActionDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get groupFilesActionDownload;

  /// No description provided for @groupFilesActionForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get groupFilesActionForward;

  /// No description provided for @groupFilesDownloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Download started'**
  String get groupFilesDownloadStarted;

  /// No description provided for @groupFilesDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get groupFilesDownloadFailed;

  /// No description provided for @groupFilesForwardUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This file cannot be forwarded right now'**
  String get groupFilesForwardUnsupported;

  /// No description provided for @groupHistorySearch.
  ///
  /// In en, this message translates to:
  /// **'Search Chat History'**
  String get groupHistorySearch;

  /// No description provided for @groupHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No related chat history'**
  String get groupHistoryEmpty;

  /// No description provided for @groupHistoryTimeUnknown.
  ///
  /// In en, this message translates to:
  /// **'No sent time yet'**
  String get groupHistoryTimeUnknown;

  /// No description provided for @groupHistorySenderUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown member'**
  String get groupHistorySenderUnknown;

  /// No description provided for @groupHistoryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get groupHistoryFilterAll;

  /// No description provided for @groupHistoryFilterText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get groupHistoryFilterText;

  /// No description provided for @groupHistoryFilterFile.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get groupHistoryFilterFile;

  /// No description provided for @groupHistoryFilterImage.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get groupHistoryFilterImage;

  /// No description provided for @groupHistoryFilterVideo.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get groupHistoryFilterVideo;

  /// No description provided for @groupHistoryFilterLink.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get groupHistoryFilterLink;

  /// No description provided for @favoritePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Message Favorites'**
  String get favoritePageTitle;

  /// No description provided for @favoritePageEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorite messages'**
  String get favoritePageEmpty;

  /// No description provided for @favoriteSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search favorites'**
  String get favoriteSearchPlaceholder;

  /// No description provided for @favoriteDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorite Detail'**
  String get favoriteDetailTitle;

  /// No description provided for @favoriteDetailLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get favoriteDetailLoading;

  /// No description provided for @favoriteDetailEmpty.
  ///
  /// In en, this message translates to:
  /// **'No detail available'**
  String get favoriteDetailEmpty;

  /// No description provided for @favoriteDetailSendToChat.
  ///
  /// In en, this message translates to:
  /// **'Send to Chat'**
  String get favoriteDetailSendToChat;

  /// No description provided for @favoriteDetailTypeLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get favoriteDetailTypeLink;

  /// No description provided for @favoriteDetailTypeNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get favoriteDetailTypeNote;

  /// No description provided for @favoriteDetailTypeImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get favoriteDetailTypeImage;

  /// No description provided for @favoriteDetailTypeVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get favoriteDetailTypeVideo;

  /// No description provided for @favoriteDetailTypeFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get favoriteDetailTypeFile;

  /// No description provided for @favoriteDetailTypeDefault.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get favoriteDetailTypeDefault;

  /// No description provided for @favoriteDetailInvalidId.
  ///
  /// In en, this message translates to:
  /// **'Invalid favorite id'**
  String get favoriteDetailInvalidId;

  /// No description provided for @favoriteDetailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load detail'**
  String get favoriteDetailLoadFailed;

  /// No description provided for @favoriteDetailVideoUrlEmpty.
  ///
  /// In en, this message translates to:
  /// **'Video URL is empty'**
  String get favoriteDetailVideoUrlEmpty;

  /// No description provided for @favoriteDetailFileUrlEmpty.
  ///
  /// In en, this message translates to:
  /// **'File URL is empty'**
  String get favoriteDetailFileUrlEmpty;

  /// No description provided for @favoriteTabDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get favoriteTabDefault;

  /// No description provided for @favoriteTabNormal.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get favoriteTabNormal;

  /// No description provided for @favoriteTabMedia.
  ///
  /// In en, this message translates to:
  /// **'Images & Videos'**
  String get favoriteTabMedia;

  /// No description provided for @favoriteTabFile.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get favoriteTabFile;

  /// No description provided for @favoriteCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Unfavorite'**
  String get favoriteCancelAction;

  /// No description provided for @favoriteCancelSuccess.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get favoriteCancelSuccess;

  /// No description provided for @favoriteOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open favorite detail'**
  String get favoriteOpenFailed;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeMode;

  /// No description provided for @settingsThemeModeSummary.
  ///
  /// In en, this message translates to:
  /// **'System / Light / Dark'**
  String get settingsThemeModeSummary;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSummary.
  ///
  /// In en, this message translates to:
  /// **'System / Simplified Chinese / English'**
  String get settingsLanguageSummary;

  /// No description provided for @settingsAboutApp.
  ///
  /// In en, this message translates to:
  /// **'About 钰信'**
  String get settingsAboutApp;

  /// No description provided for @settingsVersionValue.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get settingsVersionValue;

  /// No description provided for @themeSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSettingsTitle;

  /// No description provided for @themeModeLightTitle.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get themeModeLightTitle;

  /// No description provided for @themeModeLightDescription.
  ///
  /// In en, this message translates to:
  /// **'Always use light pages and chat backgrounds'**
  String get themeModeLightDescription;

  /// No description provided for @themeModeDarkTitle.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get themeModeDarkTitle;

  /// No description provided for @themeModeDarkDescription.
  ///
  /// In en, this message translates to:
  /// **'Always use dark pages and chat backgrounds'**
  String get themeModeDarkDescription;

  /// No description provided for @themeModeSystemTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get themeModeSystemTitle;

  /// No description provided for @themeModeSystemDescription.
  ///
  /// In en, this message translates to:
  /// **'Follow the device system appearance setting'**
  String get themeModeSystemDescription;

  /// No description provided for @themePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get themePreviewTitle;

  /// No description provided for @themePreviewMessage.
  ///
  /// In en, this message translates to:
  /// **'Primary flow preview close to the legacy product style'**
  String get themePreviewMessage;

  /// No description provided for @themePreviewApplyBtn.
  ///
  /// In en, this message translates to:
  /// **'Apply Immediately'**
  String get themePreviewApplyBtn;

  /// No description provided for @languageSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettingsTitle;

  /// No description provided for @languageModeSystemTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get languageModeSystemTitle;

  /// No description provided for @languageModeSystemDescription.
  ///
  /// In en, this message translates to:
  /// **'Use the device language'**
  String get languageModeSystemDescription;

  /// No description provided for @languageModeZhCnTitle.
  ///
  /// In en, this message translates to:
  /// **'Simplified Chinese'**
  String get languageModeZhCnTitle;

  /// No description provided for @languageModeZhCnDescription.
  ///
  /// In en, this message translates to:
  /// **'Force Chinese (zh-CN)'**
  String get languageModeZhCnDescription;

  /// No description provided for @languageModeEnTitle.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageModeEnTitle;

  /// No description provided for @languageModeEnDescription.
  ///
  /// In en, this message translates to:
  /// **'Force English'**
  String get languageModeEnDescription;

  /// No description provided for @languageModeJaTitle.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageModeJaTitle;

  /// No description provided for @languageModeJaDescription.
  ///
  /// In en, this message translates to:
  /// **'Force Japanese'**
  String get languageModeJaDescription;

  /// No description provided for @languageModeKoTitle.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get languageModeKoTitle;

  /// No description provided for @languageModeKoDescription.
  ///
  /// In en, this message translates to:
  /// **'Force Korean'**
  String get languageModeKoDescription;

  /// No description provided for @languageEffectiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Current language'**
  String get languageEffectiveLabel;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get profileTitle;

  /// No description provided for @profileUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get profileUnknownUser;

  /// No description provided for @profileCompanyLabel.
  ///
  /// In en, this message translates to:
  /// **'Shengyu Tech'**
  String get profileCompanyLabel;

  /// No description provided for @profileSectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSectionSettings;

  /// No description provided for @profileSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileSectionAbout;

  /// No description provided for @profileNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotifications;

  /// No description provided for @profilePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get profilePrivacy;

  /// No description provided for @profileVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Version'**
  String get profileVersionLabel;

  /// No description provided for @profileThemeSwitch.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get profileThemeSwitch;

  /// No description provided for @profileFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get profileFavorites;

  /// No description provided for @profileScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get profileScan;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profileLogout;

  /// No description provided for @profileAvatarHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to change or remove avatar'**
  String get profileAvatarHint;

  /// No description provided for @profileUploadAvatar.
  ///
  /// In en, this message translates to:
  /// **'Upload Avatar'**
  String get profileUploadAvatar;

  /// No description provided for @profileReuploadAvatar.
  ///
  /// In en, this message translates to:
  /// **'Reupload Avatar'**
  String get profileReuploadAvatar;

  /// No description provided for @profileRemoveCustomAvatar.
  ///
  /// In en, this message translates to:
  /// **'Remove Custom Avatar'**
  String get profileRemoveCustomAvatar;

  /// No description provided for @profileConfirmRemoveAvatar.
  ///
  /// In en, this message translates to:
  /// **'Confirm removing custom avatar'**
  String get profileConfirmRemoveAvatar;

  /// No description provided for @profileAvatarUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Avatar uploaded successfully'**
  String get profileAvatarUploadSuccess;

  /// No description provided for @profileAvatarUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload avatar'**
  String get profileAvatarUploadFailed;

  /// No description provided for @profileAvatarRemoveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Avatar removed'**
  String get profileAvatarRemoveSuccess;

  /// No description provided for @profileAvatarRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove avatar'**
  String get profileAvatarRemoveFailed;

  /// No description provided for @profileAvatarUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading avatar...'**
  String get profileAvatarUploading;

  /// No description provided for @profileUploadFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Upload failed, please retry'**
  String get profileUploadFailedRetry;

  /// No description provided for @departmentFallback.
  ///
  /// In en, this message translates to:
  /// **'No department assigned'**
  String get departmentFallback;

  /// No description provided for @profilePostFallback.
  ///
  /// In en, this message translates to:
  /// **'No position set'**
  String get profilePostFallback;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Load failed, pull down to retry'**
  String get profileLoadError;

  /// No description provided for @workbenchTitle.
  ///
  /// In en, this message translates to:
  /// **'Workbench'**
  String get workbenchTitle;

  /// No description provided for @workbenchIntro.
  ///
  /// In en, this message translates to:
  /// **'Common collaboration and business entries live here.'**
  String get workbenchIntro;

  /// No description provided for @workbenchApproval.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get workbenchApproval;

  /// No description provided for @workbenchTodo.
  ///
  /// In en, this message translates to:
  /// **'To-do'**
  String get workbenchTodo;

  /// No description provided for @workbenchCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get workbenchCalendar;

  /// No description provided for @workbenchFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get workbenchFiles;

  /// No description provided for @workbenchMeeting.
  ///
  /// In en, this message translates to:
  /// **'Meetings'**
  String get workbenchMeeting;

  /// No description provided for @workbenchAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get workbenchAnnouncements;

  /// No description provided for @workbenchEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get workbenchEdit;

  /// No description provided for @workbenchOfficeFlow.
  ///
  /// In en, this message translates to:
  /// **'Office Flow'**
  String get workbenchOfficeFlow;

  /// No description provided for @workbenchCommonFeatures.
  ///
  /// In en, this message translates to:
  /// **'Common Features'**
  String get workbenchCommonFeatures;

  /// No description provided for @workbenchMail.
  ///
  /// In en, this message translates to:
  /// **'Mail'**
  String get workbenchMail;

  /// No description provided for @workbenchDelegation.
  ///
  /// In en, this message translates to:
  /// **'Delegation'**
  String get workbenchDelegation;

  /// No description provided for @workbenchAccountSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch Account'**
  String get workbenchAccountSwitch;

  /// No description provided for @workbenchAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get workbenchAttendance;

  /// No description provided for @workbenchFieldWork.
  ///
  /// In en, this message translates to:
  /// **'Field Work'**
  String get workbenchFieldWork;

  /// No description provided for @workbenchMetricPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'--'**
  String get workbenchMetricPlaceholder;

  /// No description provided for @tabConversations.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get tabConversations;

  /// No description provided for @tabContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get tabContacts;

  /// No description provided for @tabWorkbench.
  ///
  /// In en, this message translates to:
  /// **'Workbench'**
  String get tabWorkbench;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get tabProfile;

  /// No description provided for @stickerManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Sticker Management'**
  String get stickerManageTitle;

  /// No description provided for @stickerPin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get stickerPin;

  /// No description provided for @stickerMoveLeft.
  ///
  /// In en, this message translates to:
  /// **'Move Left'**
  String get stickerMoveLeft;

  /// No description provided for @stickerMoveRight.
  ///
  /// In en, this message translates to:
  /// **'Move Right'**
  String get stickerMoveRight;

  /// No description provided for @stickerMoveBottom.
  ///
  /// In en, this message translates to:
  /// **'Move to Bottom'**
  String get stickerMoveBottom;

  /// No description provided for @stickerDeleted.
  ///
  /// In en, this message translates to:
  /// **'Sticker deleted'**
  String get stickerDeleted;

  /// No description provided for @deleteStickerAction.
  ///
  /// In en, this message translates to:
  /// **'Delete Sticker'**
  String get deleteStickerAction;

  /// No description provided for @pinConversation.
  ///
  /// In en, this message translates to:
  /// **'Pin Conversation'**
  String get pinConversation;

  /// No description provided for @unpinConversation.
  ///
  /// In en, this message translates to:
  /// **'Unpin Conversation'**
  String get unpinConversation;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get markAsRead;

  /// No description provided for @markAsUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark as Unread'**
  String get markAsUnread;

  /// No description provided for @deleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation'**
  String get deleteConversation;

  /// No description provided for @groupSettingsReadOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Settings (Read-only)'**
  String get groupSettingsReadOnlyTitle;

  /// No description provided for @groupKickedHint.
  ///
  /// In en, this message translates to:
  /// **'You have been removed from the group. You can only view history.'**
  String get groupKickedHint;

  /// No description provided for @groupLeftHint.
  ///
  /// In en, this message translates to:
  /// **'You have left the group. You can only view history.'**
  String get groupLeftHint;

  /// No description provided for @groupDisbandedHint.
  ///
  /// In en, this message translates to:
  /// **'This group has been dissolved.'**
  String get groupDisbandedHint;

  /// No description provided for @groupNotInGroupHint.
  ///
  /// In en, this message translates to:
  /// **'You are not in the group.'**
  String get groupNotInGroupHint;

  /// No description provided for @groupMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String groupMemberCount(Object count);

  /// No description provided for @myGroups.
  ///
  /// In en, this message translates to:
  /// **'My Groups'**
  String get myGroups;

  /// No description provided for @myFollows.
  ///
  /// In en, this message translates to:
  /// **'My Follows'**
  String get myFollows;

  /// No description provided for @organization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organization;

  /// No description provided for @myDepartments.
  ///
  /// In en, this message translates to:
  /// **'My Departments'**
  String get myDepartments;

  /// No description provided for @groupMemberAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Member added successfully'**
  String get groupMemberAddedSuccess;

  /// No description provided for @addMemberAction.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMemberAction;

  /// No description provided for @createGroupAction.
  ///
  /// In en, this message translates to:
  /// **'Create Group Chat'**
  String get createGroupAction;

  /// No description provided for @searchMemberHint.
  ///
  /// In en, this message translates to:
  /// **'Search members'**
  String get searchMemberHint;

  /// No description provided for @atLeastTwoMembers.
  ///
  /// In en, this message translates to:
  /// **'A group chat needs at least 2 other members'**
  String get atLeastTwoMembers;

  /// No description provided for @atLeastOneMember.
  ///
  /// In en, this message translates to:
  /// **'Select at least 1 member'**
  String get atLeastOneMember;

  /// No description provided for @groupNotAllowedAddMember.
  ///
  /// In en, this message translates to:
  /// **'This group does not allow adding members'**
  String get groupNotAllowedAddMember;

  /// No description provided for @mustRetainCurrentUserInGroup.
  ///
  /// In en, this message translates to:
  /// **'The current logged-in account must be retained in the group'**
  String get mustRetainCurrentUserInGroup;

  /// No description provided for @groupInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite Code'**
  String get groupInviteCode;

  /// No description provided for @groupExpireTime.
  ///
  /// In en, this message translates to:
  /// **'Expiration'**
  String get groupExpireTime;

  /// No description provided for @groupJoinMethod.
  ///
  /// In en, this message translates to:
  /// **'Join Method'**
  String get groupJoinMethod;

  /// No description provided for @groupJoinRequiresApproval.
  ///
  /// In en, this message translates to:
  /// **'Requires admin approval'**
  String get groupJoinRequiresApproval;

  /// No description provided for @scanPlatformNotSupported.
  ///
  /// In en, this message translates to:
  /// **'QR scanning is not supported on this platform'**
  String get scanPlatformNotSupported;

  /// No description provided for @scanManualJoinHint.
  ///
  /// In en, this message translates to:
  /// **'You can still join the group manually below.'**
  String get scanManualJoinHint;

  /// No description provided for @callSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get callSwitch;

  /// No description provided for @callIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming Call'**
  String get callIncoming;

  /// No description provided for @callOutgoing.
  ///
  /// In en, this message translates to:
  /// **'Outgoing Call'**
  String get callOutgoing;

  /// No description provided for @callVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice Call'**
  String get callVoice;

  /// No description provided for @callVideo.
  ///
  /// In en, this message translates to:
  /// **'Video Call'**
  String get callVideo;

  /// No description provided for @callAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get callAccept;

  /// No description provided for @callReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get callReject;

  /// No description provided for @callHangup.
  ///
  /// In en, this message translates to:
  /// **'Hang Up'**
  String get callHangup;

  /// No description provided for @callCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get callCancel;

  /// No description provided for @callBusy.
  ///
  /// In en, this message translates to:
  /// **'Line Busy'**
  String get callBusy;

  /// No description provided for @callNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'No Answer'**
  String get callNoAnswer;

  /// No description provided for @callRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get callRejected;

  /// No description provided for @callCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get callCancelled;

  /// No description provided for @callDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration {duration}'**
  String callDuration(String duration);

  /// No description provided for @callMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed Call'**
  String get callMissed;

  /// No description provided for @callEnded.
  ///
  /// In en, this message translates to:
  /// **'Call Ended'**
  String get callEnded;

  /// No description provided for @callConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get callConnecting;

  /// No description provided for @callReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get callReconnecting;

  /// No description provided for @callNetworkPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor Network Quality'**
  String get callNetworkPoor;

  /// No description provided for @callEncryptionEnabled.
  ///
  /// In en, this message translates to:
  /// **'End-to-End Encrypted'**
  String get callEncryptionEnabled;

  /// No description provided for @callScreenShare.
  ///
  /// In en, this message translates to:
  /// **'Screen Share'**
  String get callScreenShare;

  /// No description provided for @callSwitchCamera.
  ///
  /// In en, this message translates to:
  /// **'Switch Camera'**
  String get callSwitchCamera;

  /// No description provided for @callMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get callMute;

  /// No description provided for @callUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get callUnmute;

  /// No description provided for @callSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get callSpeaker;

  /// No description provided for @callEarpiece.
  ///
  /// In en, this message translates to:
  /// **'Earpiece'**
  String get callEarpiece;

  /// No description provided for @callCameraOn.
  ///
  /// In en, this message translates to:
  /// **'Camera On'**
  String get callCameraOn;

  /// No description provided for @callCameraOff.
  ///
  /// In en, this message translates to:
  /// **'Camera Off'**
  String get callCameraOff;

  /// No description provided for @callHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Call History'**
  String get callHistoryTitle;

  /// No description provided for @callHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No call history'**
  String get callHistoryEmpty;

  /// No description provided for @callHistoryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get callHistoryFilterAll;

  /// No description provided for @callHistoryFilterVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice Call'**
  String get callHistoryFilterVoice;

  /// No description provided for @callHistoryFilterVideo.
  ///
  /// In en, this message translates to:
  /// **'Video Call'**
  String get callHistoryFilterVideo;

  /// No description provided for @callRecordCompleted.
  ///
  /// In en, this message translates to:
  /// **'Duration {duration}'**
  String callRecordCompleted(String duration);

  /// No description provided for @callRecordMissed.
  ///
  /// In en, this message translates to:
  /// **'No Answer'**
  String get callRecordMissed;

  /// No description provided for @callRecordRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get callRecordRejected;

  /// No description provided for @callRecordBusy.
  ///
  /// In en, this message translates to:
  /// **'Line Busy'**
  String get callRecordBusy;

  /// No description provided for @callRecordCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get callRecordCancelled;

  /// No description provided for @callRecordOutgoing.
  ///
  /// In en, this message translates to:
  /// **'Outgoing'**
  String get callRecordOutgoing;

  /// No description provided for @callRecordIncoming.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get callRecordIncoming;

  /// No description provided for @torchToggleFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to toggle flashlight: {error}'**
  String torchToggleFailed(Object error);

  /// No description provided for @searchTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get searchTabAll;

  /// No description provided for @searchTabMessage.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get searchTabMessage;

  /// No description provided for @searchTabContact.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get searchTabContact;

  /// No description provided for @searchTabGroup.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get searchTabGroup;

  /// No description provided for @searchTabMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get searchTabMedia;

  /// No description provided for @joinGroupAction.
  ///
  /// In en, this message translates to:
  /// **'Join Group'**
  String get joinGroupAction;

  /// No description provided for @viewGroupAction.
  ///
  /// In en, this message translates to:
  /// **'View Group Chat'**
  String get viewGroupAction;

  /// No description provided for @invalidInviteExpired.
  ///
  /// In en, this message translates to:
  /// **'Invite code is invalid or expired'**
  String get invalidInviteExpired;

  /// No description provided for @manualEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get manualEntryTitle;

  /// No description provided for @inputInviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter invite code or group invite link'**
  String get inputInviteCodeHint;

  /// No description provided for @pasteAction.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get pasteAction;

  /// No description provided for @verifyingAction.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get verifyingAction;

  /// No description provided for @verifyAction.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyAction;

  /// No description provided for @invitePasteHint.
  ///
  /// In en, this message translates to:
  /// **'Supports pasting QR links, invite code text or scan results.'**
  String get invitePasteHint;

  /// No description provided for @waitingForInput.
  ///
  /// In en, this message translates to:
  /// **'Waiting for input'**
  String get waitingForInput;

  /// No description provided for @clipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Clipboard is empty'**
  String get clipboardEmpty;

  /// No description provided for @unrecognizedInvite.
  ///
  /// In en, this message translates to:
  /// **'Unable to recognize invite code or link'**
  String get unrecognizedInvite;

  /// No description provided for @unnamedGroup.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Group'**
  String get unnamedGroup;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @hoursMinutesExpire.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m until expired'**
  String hoursMinutesExpire(Object hours, Object minutes);

  /// No description provided for @minutesExpire.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m until expired'**
  String minutesExpire(Object minutes);

  /// No description provided for @applicationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Application submitted'**
  String get applicationSubmitted;

  /// No description provided for @joinedGroup.
  ///
  /// In en, this message translates to:
  /// **'Joined the group'**
  String get joinedGroup;

  /// No description provided for @submittingAction.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submittingAction;

  /// No description provided for @submitApplication.
  ///
  /// In en, this message translates to:
  /// **'Submit Application'**
  String get submitApplication;

  /// No description provided for @reEnterAction.
  ///
  /// In en, this message translates to:
  /// **'Re-enter'**
  String get reEnterAction;

  /// No description provided for @reEnterHint.
  ///
  /// In en, this message translates to:
  /// **'Please re-enter a valid invite code or link.'**
  String get reEnterHint;

  /// No description provided for @expireTime.
  ///
  /// In en, this message translates to:
  /// **'Expiration'**
  String get expireTime;

  /// No description provided for @groupChatNotExist.
  ///
  /// In en, this message translates to:
  /// **'Group chat does not exist'**
  String get groupChatNotExist;

  /// No description provided for @searchMinLengthHint.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters to search'**
  String get searchMinLengthHint;

  /// No description provided for @searchingAction.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searchingAction;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noResultsFound(Object query);

  /// No description provided for @loadMoreAction.
  ///
  /// In en, this message translates to:
  /// **'Load more...'**
  String get loadMoreAction;

  /// No description provided for @noMoreData.
  ///
  /// In en, this message translates to:
  /// **'No more data'**
  String get noMoreData;

  /// No description provided for @clearHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear search history'**
  String get clearHistoryTitle;

  /// No description provided for @clearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all search history?'**
  String get clearHistoryConfirm;

  /// No description provided for @deleteHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete search history'**
  String get deleteHistoryTitle;

  /// No description provided for @deleteHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{keyword}\"?'**
  String deleteHistoryConfirm(Object keyword);

  /// No description provided for @searchHistory.
  ///
  /// In en, this message translates to:
  /// **'Search history'**
  String get searchHistory;

  /// No description provided for @hotSearches.
  ///
  /// In en, this message translates to:
  /// **'Hot searches'**
  String get hotSearches;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @groupMessages.
  ///
  /// In en, this message translates to:
  /// **'Group messages'**
  String get groupMessages;

  /// No description provided for @directMessages.
  ///
  /// In en, this message translates to:
  /// **'Direct messages'**
  String get directMessages;

  /// No description provided for @contactType.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactType;

  /// No description provided for @groupType.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupType;

  /// No description provided for @mediaType.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get mediaType;

  /// No description provided for @memberCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String memberCountLabel(Object count);

  /// No description provided for @discardChangesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard language changes?'**
  String get discardChangesConfirm;

  /// No description provided for @continueEditAction.
  ///
  /// In en, this message translates to:
  /// **'Keep Editing'**
  String get continueEditAction;

  /// No description provided for @discardAction.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardAction;

  /// No description provided for @tenantSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch Organization'**
  String get tenantSwitchTitle;

  /// No description provided for @tenantCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get tenantCurrent;

  /// No description provided for @tenantSwitching.
  ///
  /// In en, this message translates to:
  /// **'Switching...'**
  String get tenantSwitching;

  /// No description provided for @tenantSwitchSuccess.
  ///
  /// In en, this message translates to:
  /// **'Switched successfully'**
  String get tenantSwitchSuccess;

  /// No description provided for @tenantSwitchFailed.
  ///
  /// In en, this message translates to:
  /// **'Switch failed'**
  String get tenantSwitchFailed;

  /// No description provided for @tenantAlreadyCurrent.
  ///
  /// In en, this message translates to:
  /// **'Already in current organization'**
  String get tenantAlreadyCurrent;

  /// No description provided for @tenantNotSwitchable.
  ///
  /// In en, this message translates to:
  /// **'This organization is not switchable'**
  String get tenantNotSwitchable;

  /// No description provided for @tenantLoadingFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load tenant list'**
  String get tenantLoadingFailed;

  /// No description provided for @tenantSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search organization'**
  String get tenantSearchHint;

  /// No description provided for @tenantNoTenants.
  ///
  /// In en, this message translates to:
  /// **'No organizations'**
  String get tenantNoTenants;

  /// No description provided for @tenantNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No matching organizations found'**
  String get tenantNoSearchResults;

  /// No description provided for @tenantCreateOrJoin.
  ///
  /// In en, this message translates to:
  /// **'Create/Join Organization'**
  String get tenantCreateOrJoin;

  /// No description provided for @tenantCreateOrJoinComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Create/Join organization feature coming soon'**
  String get tenantCreateOrJoinComingSoon;

  /// No description provided for @tenantLastLogin.
  ///
  /// In en, this message translates to:
  /// **'Last login: {time}'**
  String tenantLastLogin(String time);

  /// No description provided for @tenantTimeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get tenantTimeJustNow;

  /// No description provided for @tenantTimeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String tenantTimeMinutesAgo(int count);

  /// No description provided for @tenantTimeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String tenantTimeHoursAgo(int count);

  /// No description provided for @tenantTimeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String tenantTimeDaysAgo(int count);

  /// No description provided for @deviceManagementBanner.
  ///
  /// In en, this message translates to:
  /// **'Logged in on {count} other devices'**
  String deviceManagementBanner(Object count);

  /// No description provided for @deviceListTitle.
  ///
  /// In en, this message translates to:
  /// **'Login Devices'**
  String get deviceListTitle;

  /// No description provided for @deviceListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No logged-in devices'**
  String get deviceListEmpty;

  /// No description provided for @deviceListCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get deviceListCurrent;

  /// No description provided for @deviceListKick.
  ///
  /// In en, this message translates to:
  /// **'Kick'**
  String get deviceListKick;

  /// No description provided for @deviceKickConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Kick Device'**
  String get deviceKickConfirmTitle;

  /// No description provided for @deviceKickConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to kick out 「{deviceName}」? This device will need to log in again to continue using.'**
  String deviceKickConfirmMessage(Object deviceName);

  /// No description provided for @deviceKickAction.
  ///
  /// In en, this message translates to:
  /// **'Kick'**
  String get deviceKickAction;

  /// No description provided for @deviceKickedSuccess.
  ///
  /// In en, this message translates to:
  /// **'「{deviceName}」 has been kicked'**
  String deviceKickedSuccess(Object deviceName);

  /// No description provided for @refreshAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshAction;

  /// No description provided for @deviceTimeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get deviceTimeJustNow;

  /// No description provided for @deviceTimeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String deviceTimeMinutesAgo(Object minutes);

  /// No description provided for @deviceTimeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String deviceTimeHoursAgo(Object hours);

  /// No description provided for @deviceTimeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String deviceTimeDaysAgo(Object days);

  /// No description provided for @callRecordOutgoingNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'No answer'**
  String get callRecordOutgoingNoAnswer;

  /// No description provided for @callRecordIncomingMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed call'**
  String get callRecordIncomingMissed;

  /// No description provided for @callRecordOutgoingRejected.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get callRecordOutgoingRejected;

  /// No description provided for @callRecordIncomingRejected.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get callRecordIncomingRejected;

  /// No description provided for @callRecordOutgoingBusy.
  ///
  /// In en, this message translates to:
  /// **'Line busy'**
  String get callRecordOutgoingBusy;

  /// No description provided for @callRecordIncomingBusy.
  ///
  /// In en, this message translates to:
  /// **'Missed due to busy line'**
  String get callRecordIncomingBusy;

  /// No description provided for @callRecordOutgoingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get callRecordOutgoingCancelled;

  /// No description provided for @callRecordIncomingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Caller cancelled'**
  String get callRecordIncomingCancelled;

  /// No description provided for @callRecordGroupCompleted.
  ///
  /// In en, this message translates to:
  /// **'Group {type} call ended · {duration}'**
  String callRecordGroupCompleted(String type, String duration);

  /// No description provided for @callRecordGroupMissed.
  ///
  /// In en, this message translates to:
  /// **'{callerName} started a group {type} call. No one answered.'**
  String callRecordGroupMissed(String callerName, String type);

  /// No description provided for @callRecordGroupRejected.
  ///
  /// In en, this message translates to:
  /// **'{callerName}\'s group {type} call was declined'**
  String callRecordGroupRejected(String callerName, String type);

  /// No description provided for @callRecordGroupBusy.
  ///
  /// In en, this message translates to:
  /// **'{callerName}\'s group {type} call: members are busy'**
  String callRecordGroupBusy(String callerName, String type);

  /// No description provided for @callRecordGroupCancelled.
  ///
  /// In en, this message translates to:
  /// **'{callerName} cancelled the group {type} call'**
  String callRecordGroupCancelled(String callerName, String type);

  /// No description provided for @callTypeVoiceShort.
  ///
  /// In en, this message translates to:
  /// **'voice'**
  String get callTypeVoiceShort;

  /// No description provided for @callTypeVideoShort.
  ///
  /// In en, this message translates to:
  /// **'video'**
  String get callTypeVideoShort;

  /// No description provided for @callPeerFallback.
  ///
  /// In en, this message translates to:
  /// **'the other person'**
  String get callPeerFallback;

  /// No description provided for @callMemberFallback.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get callMemberFallback;

  /// No description provided for @callSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose call type'**
  String get callSheetTitle;

  /// No description provided for @callSheetWithName.
  ///
  /// In en, this message translates to:
  /// **'Call {name}'**
  String callSheetWithName(String name);

  /// No description provided for @callVideoConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting video…'**
  String get callVideoConnecting;

  /// No description provided for @callStartingCamera.
  ///
  /// In en, this message translates to:
  /// **'Starting camera…'**
  String get callStartingCamera;

  /// No description provided for @callWaitingForAnswer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for an answer…'**
  String get callWaitingForAnswer;

  /// No description provided for @callMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get callMe;

  /// No description provided for @callIncomingGroupInvite.
  ///
  /// In en, this message translates to:
  /// **'{name} invited you to a group {type} call'**
  String callIncomingGroupInvite(String name, String type);

  /// No description provided for @callIncomingInvite.
  ///
  /// In en, this message translates to:
  /// **'Invited you to a {type} call'**
  String callIncomingInvite(String type);

  /// No description provided for @callAccepting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get callAccepting;

  /// No description provided for @callDialing.
  ///
  /// In en, this message translates to:
  /// **'Calling…'**
  String get callDialing;

  /// No description provided for @callWaitingForMembers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for members to join…'**
  String get callWaitingForMembers;

  /// No description provided for @callRestoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring call…'**
  String get callRestoring;

  /// No description provided for @callGroupParticipants.
  ///
  /// In en, this message translates to:
  /// **'{count} in call · {elapsed}'**
  String callGroupParticipants(int count, String elapsed);

  /// No description provided for @callNetworkRestoring.
  ///
  /// In en, this message translates to:
  /// **'Network is unstable. Reconnecting…'**
  String get callNetworkRestoring;

  /// No description provided for @callGroupFallback.
  ///
  /// In en, this message translates to:
  /// **'Group {type} call'**
  String callGroupFallback(String type);

  /// No description provided for @callGenericFallback.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callGenericFallback;

  /// No description provided for @callRemoteHangup.
  ///
  /// In en, this message translates to:
  /// **'The other person ended the call'**
  String get callRemoteHangup;

  /// No description provided for @callOtherDeviceAnswered.
  ///
  /// In en, this message translates to:
  /// **'Answered on another device'**
  String get callOtherDeviceAnswered;

  /// No description provided for @callNetworkLostEnded.
  ///
  /// In en, this message translates to:
  /// **'Network connection lost. Call ended'**
  String get callNetworkLostEnded;

  /// No description provided for @callMaxDurationEnded.
  ///
  /// In en, this message translates to:
  /// **'Maximum call duration reached. Call ended'**
  String get callMaxDurationEnded;

  /// No description provided for @callRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore call'**
  String get callRestoreFailed;

  /// No description provided for @callAcceptFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to answer'**
  String get callAcceptFailed;

  /// No description provided for @callMicrophonePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required for calls'**
  String get callMicrophonePermissionRequired;

  /// No description provided for @callMediaPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera and microphone permissions are required for video calls'**
  String get callMediaPermissionRequired;

  /// No description provided for @callConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect call. Please try again'**
  String get callConnectFailed;

  /// No description provided for @callEndGroup.
  ///
  /// In en, this message translates to:
  /// **'End call'**
  String get callEndGroup;

  /// No description provided for @callLeaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave call'**
  String get callLeaveGroup;

  /// No description provided for @networkDisconnectedOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Network disconnected. Tap to open settings'**
  String get networkDisconnectedOpenSettings;

  /// No description provided for @serverConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to server…'**
  String get serverConnecting;

  /// No description provided for @serverReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting to server ({current}/{maximum})…'**
  String serverReconnecting(int current, int maximum);

  /// No description provided for @serverDisconnectedRetry.
  ///
  /// In en, this message translates to:
  /// **'Connection lost. Tap to retry'**
  String get serverDisconnectedRetry;

  /// No description provided for @accountSecurityAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Account security alert'**
  String get accountSecurityAlertTitle;

  /// No description provided for @accountSecurityPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'If this wasn\'t you, change your password immediately.'**
  String get accountSecurityPasswordHint;

  /// No description provided for @accountKickedWithTimeAndDevice.
  ///
  /// In en, this message translates to:
  /// **'Your account signed in on {device} at {time}. You have been signed out.'**
  String accountKickedWithTimeAndDevice(String device, String time);

  /// No description provided for @accountKickedWithDevice.
  ///
  /// In en, this message translates to:
  /// **'Your account signed in on {device}. You have been signed out.'**
  String accountKickedWithDevice(String device);

  /// No description provided for @accountKickedWithTime.
  ///
  /// In en, this message translates to:
  /// **'Your account signed in on another device at {time}. You have been signed out.'**
  String accountKickedWithTime(String time);

  /// No description provided for @accountKicked.
  ///
  /// In en, this message translates to:
  /// **'Your account has been signed out.'**
  String get accountKicked;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
