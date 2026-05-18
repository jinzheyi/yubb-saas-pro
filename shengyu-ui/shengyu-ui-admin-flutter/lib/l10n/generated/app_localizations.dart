import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Shengyu IM'**
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

  /// No description provided for @conversationTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get conversationTitle;

  /// No description provided for @contactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsTitle;

  /// No description provided for @workbenchTitle.
  ///
  /// In en, this message translates to:
  /// **'Workbench'**
  String get workbenchTitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get profileTitle;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @emptyConversation.
  ///
  /// In en, this message translates to:
  /// **'No conversations'**
  String get emptyConversation;

  /// No description provided for @inputMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get inputMessage;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

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
  /// **'{count} people'**
  String contactsCountPeople(Object count);

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
  String chatMediaMonthDay(Object month, Object day);

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
  String chatHistoryTodayAt(Object time);

  /// No description provided for @chatHistoryYesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String chatHistoryYesterdayAt(Object time);

  /// No description provided for @chatHistoryDaysAgoAt.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago {time}'**
  String chatHistoryDaysAgoAt(Object count, Object time);

  /// No description provided for @chatHistoryMonthDayAt.
  ///
  /// In en, this message translates to:
  /// **'{month}-{day} {time}'**
  String chatHistoryMonthDayAt(Object month, Object day, Object time);

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

  /// No description provided for @searchMinLength.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters'**
  String get searchMinLength;

  /// No description provided for @chatTimeToday.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String chatTimeToday(Object time);

  /// No description provided for @chatTimeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String chatTimeYesterday(Object time);

  /// No description provided for @chatLoadOlder.
  ///
  /// In en, this message translates to:
  /// **'Load older messages'**
  String get chatLoadOlder;

  /// No description provided for @contactsSearchResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get contactsSearchResultTitle;

  /// No description provided for @contactsSearchKeyword.
  ///
  /// In en, this message translates to:
  /// **'Keyword: {keyword}'**
  String contactsSearchKeyword(Object keyword);

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

  /// No description provided for @profileDepartmentFallback.
  ///
  /// In en, this message translates to:
  /// **'No department assigned'**
  String get profileDepartmentFallback;

  /// No description provided for @profilePostFallback.
  ///
  /// In en, this message translates to:
  /// **'No position set'**
  String get profilePostFallback;

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
  /// **'About Shengyu IM'**
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

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

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

  /// No description provided for @languageEffectiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Current language'**
  String get languageEffectiveLabel;

  /// No description provided for @retrySend.
  ///
  /// In en, this message translates to:
  /// **'Retry sending'**
  String get retrySend;

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

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get unknownError;

  /// No description provided for @groupSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Settings'**
  String get groupSettingsTitle;

  /// No description provided for @groupMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Members'**
  String get groupMembersTitle;

  /// No description provided for @groupMembersTitleWithCount.
  ///
  /// In en, this message translates to:
  /// **'Group Members ({count})'**
  String groupMembersTitleWithCount(Object count);

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
  String groupMembersConfirmSelected(Object count);

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
  String groupMembersRemoveConfirm(Object names);

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
  String groupMembersTransferConfirm(Object name);

  /// No description provided for @groupMembersTransferredTo.
  ///
  /// In en, this message translates to:
  /// **'Transferred to {name}'**
  String groupMembersTransferredTo(Object name);

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
    Object month,
    Object day,
    Object hour,
    Object minute,
  );

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
  String groupSettingsConfirmSetAdmin(Object name);

  /// No description provided for @groupSettingsConfirmRemoveAdmin.
  ///
  /// In en, this message translates to:
  /// **'Remove admin role from {name}?'**
  String groupSettingsConfirmRemoveAdmin(Object name);

  /// No description provided for @groupSettingsConfirmMuteMember.
  ///
  /// In en, this message translates to:
  /// **'Mute {name}?'**
  String groupSettingsConfirmMuteMember(Object name);

  /// No description provided for @groupSettingsConfirmUnmuteMember.
  ///
  /// In en, this message translates to:
  /// **'Unmute {name}?'**
  String groupSettingsConfirmUnmuteMember(Object name);

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
  String groupSettingsConfirmRemoveMember(Object name);

  /// No description provided for @groupSettingsPendingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get groupSettingsPendingEmpty;

  /// No description provided for @groupSettingsPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String groupSettingsPendingCount(Object count);

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
  String groupJoinRequestsApplyTime(Object time);

  /// No description provided for @groupJoinRequestsHandleTime.
  ///
  /// In en, this message translates to:
  /// **'Handled at: {time}'**
  String groupJoinRequestsHandleTime(Object time);

  /// No description provided for @groupJoinRequestsHandleResult.
  ///
  /// In en, this message translates to:
  /// **'Result: {result}'**
  String groupJoinRequestsHandleResult(Object result);

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
  String groupJoinRequestsRejectConfirm(Object name);

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
  String groupSettingsRemoveSelected(Object count);

  /// No description provided for @groupSettingsSearchMembers.
  ///
  /// In en, this message translates to:
  /// **'Search Members'**
  String get groupSettingsSearchMembers;

  /// No description provided for @groupSettingsMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String groupSettingsMembersCount(Object count);

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

  /// No description provided for @chatOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Open failed'**
  String get chatOpenFailed;

  /// No description provided for @chatMessageDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Message Detail'**
  String get chatMessageDetailTitle;

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
  String chatGroupMutedUntil(Object time);

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
  String chatGroupOwnerTransferredTo(Object name);

  /// No description provided for @chatGroupMemberAddedOne.
  ///
  /// In en, this message translates to:
  /// **'\"{firstName}\" joined the group'**
  String chatGroupMemberAddedOne(Object firstName);

  /// No description provided for @chatGroupMemberAddedTwo.
  ///
  /// In en, this message translates to:
  /// **'\"{firstName}\" and \"{secondName}\" joined the group'**
  String chatGroupMemberAddedTwo(Object firstName, Object secondName);

  /// No description provided for @chatGroupMemberAddedMany.
  ///
  /// In en, this message translates to:
  /// **'\"{firstName}\", \"{secondName}\" and {otherCount} others joined the group'**
  String chatGroupMemberAddedMany(
    Object firstName,
    Object secondName,
    Object otherCount,
  );

  /// No description provided for @chatGroupMemberRemovedNamed.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" was removed from the group'**
  String chatGroupMemberRemovedNamed(Object name);

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
    Object operatorName,
    Object targetName,
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
    Object operatorName,
    Object targetName,
  );

  /// No description provided for @chatGroupMemberMutedNamed.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" has been muted'**
  String chatGroupMemberMutedNamed(Object name);

  /// No description provided for @chatGroupMemberMutedUntil.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" has been muted until {time}'**
  String chatGroupMemberMutedUntil(Object name, Object time);

  /// No description provided for @chatGroupMemberUnmutedNamed.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" has been unmuted'**
  String chatGroupMemberUnmutedNamed(Object name);

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
  /// **'{count} message(s)'**
  String chatForwardTargetMessageCount(Object count);

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

  /// No description provided for @chatForwardTargetForwardFailed.
  ///
  /// In en, this message translates to:
  /// **'Forward failed'**
  String get chatForwardTargetForwardFailed;

  /// No description provided for @chatForwardTargetPartialSuccess.
  ///
  /// In en, this message translates to:
  /// **'Partially succeeded {successCount}/{expectedCount}'**
  String chatForwardTargetPartialSuccess(
    Object successCount,
    Object expectedCount,
  );

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
  /// **'You can select up to {count} messages'**
  String chatMaxSelectReached(Object count);

  /// No description provided for @chatChooseDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Please select messages to delete'**
  String get chatChooseDeleteMessage;

  /// No description provided for @chatVoiceUploadRetry.
  ///
  /// In en, this message translates to:
  /// **'Voice upload failed. Tap to retry'**
  String get chatVoiceUploadRetry;

  /// No description provided for @chatMaxStickerReached.
  ///
  /// In en, this message translates to:
  /// **'You can add up to {count} stickers'**
  String chatMaxStickerReached(Object count);

  /// No description provided for @chatSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String chatSelectedCount(Object count);

  /// No description provided for @chatForwardUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This file does not support forwarding yet'**
  String get chatForwardUnsupported;

  /// No description provided for @chatForwardSuccess.
  ///
  /// In en, this message translates to:
  /// **'Forwarded to {title}'**
  String chatForwardSuccess(Object title);

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
  String chatForwardCombineDetailTodayAt(Object time);

  /// No description provided for @chatForwardCombineDetailYesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String chatForwardCombineDetailYesterdayAt(Object time);

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
  String chatRecallOtherTip(Object operatorName);

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

  /// No description provided for @chatReadOnly.
  ///
  /// In en, this message translates to:
  /// **'This conversation is read-only'**
  String get chatReadOnly;

  /// No description provided for @chatMultiDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get chatMultiDeleteTitle;

  /// No description provided for @chatMultiDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} selected messages?'**
  String chatMultiDeleteContent(Object count);

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
  /// **'Active {count} minutes ago'**
  String chatPresenceMinutesAgoActive(Object count);

  /// No description provided for @chatPresenceTodayActiveAt.
  ///
  /// In en, this message translates to:
  /// **'Active today at {time}'**
  String chatPresenceTodayActiveAt(Object time);

  /// No description provided for @chatPresenceYesterdayActiveAt.
  ///
  /// In en, this message translates to:
  /// **'Active yesterday at {time}'**
  String chatPresenceYesterdayActiveAt(Object time);

  /// No description provided for @chatPresenceWeekdayActiveAt.
  ///
  /// In en, this message translates to:
  /// **'Active on {weekday} at {time}'**
  String chatPresenceWeekdayActiveAt(Object weekday, Object time);

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
  String chatTypingNamed(Object name);

  /// No description provided for @chatTypingNamedMany.
  ///
  /// In en, this message translates to:
  /// **'{names} and others are typing...'**
  String chatTypingNamedMany(Object names);

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

  /// No description provided for @chatQuoteMessageMissing.
  ///
  /// In en, this message translates to:
  /// **'The original message no longer exists'**
  String get chatQuoteMessageMissing;

  /// No description provided for @chatAnchorFallback.
  ///
  /// In en, this message translates to:
  /// **'The original message could not be located. Latest messages are shown instead'**
  String get chatAnchorFallback;

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
  String chatPreviewFileWithName(Object name);

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

  /// No description provided for @chatActionFavoriteSticker.
  ///
  /// In en, this message translates to:
  /// **'Add to Stickers'**
  String get chatActionFavoriteSticker;

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

  /// No description provided for @chatMoreActionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get chatMoreActionLocation;

  /// No description provided for @chatMoreActionContactCard.
  ///
  /// In en, this message translates to:
  /// **'Contact Card'**
  String get chatMoreActionContactCard;

  /// No description provided for @chatMoreActionCall.
  ///
  /// In en, this message translates to:
  /// **'Audio & Video'**
  String get chatMoreActionCall;

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
  String chatLocationCoordinateFallback(Object lat, Object lng);

  /// No description provided for @chatLocationCopied.
  ///
  /// In en, this message translates to:
  /// **'Location details copied'**
  String get chatLocationCopied;

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
  String chatSelectContactCardSelected(Object name);

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
  /// **'Read {count}'**
  String chatReadReceiptRead(Object count);

  /// No description provided for @chatReadReceiptUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread {count}'**
  String chatReadReceiptUnread(Object count);

  /// No description provided for @chatReadReceiptVoiceHint.
  ///
  /// In en, this message translates to:
  /// **'For voice messages, \"read\" is based on conversation read sequence and does not mean the audio was played'**
  String get chatReadReceiptVoiceHint;

  /// No description provided for @chatReadReceiptTotal.
  ///
  /// In en, this message translates to:
  /// **'Total recipients {count}'**
  String chatReadReceiptTotal(Object count);

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
  String chatReadReceiptTodayAt(Object time);

  /// No description provided for @chatReadReceiptYesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String chatReadReceiptYesterdayAt(Object time);

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

  /// No description provided for @chatOtherUser.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get chatOtherUser;

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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
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
