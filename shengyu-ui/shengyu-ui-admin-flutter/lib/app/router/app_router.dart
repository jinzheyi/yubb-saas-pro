import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/browser_page_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/contact_department_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/contact_group_members_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/contact_picker_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/favorite_detail_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/file_preview_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/forward_combine_detail_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/forward_target_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_context_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_member_detail_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_setting_detail_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/initiate_group_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/read_receipt_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/video_player_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/app/router/route_paths.dart';
import 'package:shengyu_ui_admin_im/app/shell/app_shell.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/pages/contact_group_members_page.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/pages/contact_profile_page.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/pages/contact_search_result_page.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/pages/contacts_page.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/pages/my_department_page.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/pages/my_following_page.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/pages/my_groups_page.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/pages/org_browser_page.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/pages/star_contacts_page.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/pages/chat_history_page.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/pages/browser_page.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/pages/chat_page.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/pages/forward_combine_detail_page.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/pages/forward_target_page.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/pages/chat_media_page.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/pages/read_receipt_page.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/pages/select_location_page.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/pages/select_contact_card_page.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/pages/sticker_manage_page.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/pages/video_player_page.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/pages/call_session_page.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/pages/chat_settings_page.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/pages/conversation_list_page.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/pages/initiate_group_page.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/pages/join_group_page.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/pages/scan_page.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/pages/incoming_call_page.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/pages/outgoing_call_page.dart';
import 'package:shengyu_ui_admin_im/features/im/device/presentation/pages/device_list_page.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/presentation/pages/favorites_page.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/presentation/pages/favorite_detail_page.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_args.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/presentation/pages/file_preview_page.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/pages/group_announcement_page.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/pages/group_join_requests_page.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/pages/group_member_detail_page.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/pages/group_members_page.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/pages/group_qr_code_page.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/pages/group_settings_page.dart';
import 'package:shengyu_ui_admin_im/features/im/search/presentation/pages/common_global_search_page.dart';
import 'package:shengyu_ui_admin_im/features/login/presentation/pages/login_page.dart';
import 'package:shengyu_ui_admin_im/features/profile/presentation/pages/language_settings_page.dart';
import 'package:shengyu_ui_admin_im/features/profile/presentation/pages/profile_page.dart';
import 'package:shengyu_ui_admin_im/features/profile/presentation/pages/settings_page.dart';
import 'package:shengyu_ui_admin_im/features/profile/presentation/pages/theme_settings_page.dart';
import 'package:shengyu_ui_admin_im/features/workbench/presentation/pages/workbench_page.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  ref.watch(authSessionProvider);
  return GoRouter(
    initialLocation: RoutePaths.conversations,
    redirect: (context, state) {
      final session = ref.read(authSessionProvider);
      final isLoginRoute = state.matchedLocation == RoutePaths.login;
      if (!session.isAuthenticated && !isLoginRoute) {
        return RoutePaths.login;
      }
      if (session.isAuthenticated && isLoginRoute) {
        return RoutePaths.conversations;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        pageBuilder: (context, state) =>
            _buildRoutePage(state: state, child: const LoginPage()),
      ),
      GoRoute(
        path: RoutePaths.browser,
        name: RouteNames.browser,
        pageBuilder: (context, state) {
          final args = state.extra is BrowserPageArgs
              ? state.extra! as BrowserPageArgs
              : const BrowserPageArgs(url: '');
          return _buildRoutePage(state: state, child: BrowserPage(args: args));
        },
      ),
      GoRoute(
        path: RoutePaths.callIncoming,
        name: RouteNames.callIncoming,
        pageBuilder: (context, state) {
          final args = state.extra is CallLaunchArgs
              ? state.extra! as CallLaunchArgs
              : const CallLaunchArgs.empty();
          return _buildRoutePage(
            state: state,
            child: IncomingCallPage(args: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.callOutgoing,
        name: RouteNames.callOutgoing,
        pageBuilder: (context, state) {
          final args = state.extra is CallLaunchArgs
              ? state.extra! as CallLaunchArgs
              : const CallLaunchArgs.empty();
          return _buildRoutePage(
            state: state,
            child: OutgoingCallPage(args: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.callSession,
        name: RouteNames.callSession,
        pageBuilder: (context, state) {
          final args = state.extra is CallLaunchArgs
              ? state.extra! as CallLaunchArgs
              : const CallLaunchArgs.empty();
          return _buildRoutePage(
            state: state,
            child: CallSessionPage(args: args),
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          currentLocation: state.matchedLocation,
          strings: AppLocalizations.of(context),
          child: child,
        ),
        routes: [
          GoRoute(
            path: RoutePaths.conversations,
            name: RouteNames.conversations,
            pageBuilder: (context, state) => _buildRoutePage(
              state: state,
              child: const ConversationListPage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.contacts,
            name: RouteNames.contacts,
            pageBuilder: (context, state) =>
                _buildRoutePage(state: state, child: const ContactsPage()),
          ),
          GoRoute(
            path: RoutePaths.contactsSearchResult,
            name: RouteNames.contactsSearchResult,
            pageBuilder: (context, state) {
              final keyword = state.extra is String
                  ? state.extra! as String
                  : '';
              return _buildRoutePage(
                state: state,
                child: ContactSearchResultPage(keyword: keyword),
              );
            },
          ),
          GoRoute(
            path: RoutePaths.globalChatSearch,
            name: RouteNames.globalChatSearch,
            pageBuilder: (context, state) {
              final keyword = state.extra is String
                  ? state.extra! as String
                  : state.uri.queryParameters['keyword'] ?? '';
              return _buildRoutePage(
                state: state,
                child: CommonGlobalSearchPage(initialKeyword: keyword),
              );
            },
          ),
          GoRoute(
            path: RoutePaths.scan,
            name: RouteNames.scan,
            pageBuilder: (context, state) =>
                _buildRoutePage(state: state, child: const ScanPage()),
          ),
          GoRoute(
            path: RoutePaths.joinGroup,
            name: RouteNames.joinGroup,
            pageBuilder: (context, state) {
              final payload = state.extra is String
                  ? state.extra! as String
                  : null;
              return _buildRoutePage(
                state: state,
                child: JoinGroupPage(initialPayload: payload),
              );
            },
          ),
          GoRoute(
            path: RoutePaths.workbench,
            name: RouteNames.workbench,
            pageBuilder: (context, state) =>
                _buildRoutePage(state: state, child: const WorkbenchPage()),
          ),
          GoRoute(
            path: RoutePaths.profile,
            name: RouteNames.profile,
            pageBuilder: (context, state) =>
                _buildRoutePage(state: state, child: const ProfilePage()),
          ),
          GoRoute(
            path: RoutePaths.settings,
            name: RouteNames.settings,
            pageBuilder: (context, state) =>
                _buildRoutePage(state: state, child: const SettingsPage()),
          ),
          GoRoute(
            path: RoutePaths.themeSettings,
            name: RouteNames.themeSettings,
            pageBuilder: (context, state) => _buildRoutePage(
              state: state,
              child: const ThemeSettingsPage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.languageSettings,
            name: RouteNames.languageSettings,
            pageBuilder: (context, state) => _buildRoutePage(
              state: state,
              child: const LanguageSettingsPage(),
            ),
          ),
        ],
      ),
      // favorites / initiateGroup / contactsOrg 等路由放在 ShellRoute 外部，与 chat 平级，
      // 避免从 InitiateGroupPage 等 ShellRoute 外部页面导航时出现 Hero key 冲突
      GoRoute(
        path: RoutePaths.contactsOrg,
        name: RouteNames.contactsOrg,
        pageBuilder: (context, state) {
          final args = state.extra is ContactPickerArgs
              ? state.extra! as ContactPickerArgs
              : const ContactPickerArgs();
          return _buildRoutePage(
            state: state,
            child: OrgBrowserPage(args: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.contactsMyDepartment,
        name: RouteNames.contactsMyDepartment,
        pageBuilder: (context, state) {
          final extra = state.extra;
          if (extra is ContactDepartmentArgs) {
            return _buildRoutePage(
              state: state,
              child: MyDepartmentPage(args: extra),
            );
          }
          if (extra is Map<String, String>) {
            return _buildRoutePage(
              state: state,
              child: MyDepartmentPage(
                args: ContactDepartmentArgs(
                  initialDeptId: extra['deptId'],
                  initialDeptName: extra['deptName'],
                ),
              ),
            );
          }
          return _buildRoutePage(
            state: state,
            child: const MyDepartmentPage(),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.contactsMyGroups,
        name: RouteNames.contactsMyGroups,
        pageBuilder: (context, state) {
          final args = state.extra is ContactPickerArgs
              ? state.extra! as ContactPickerArgs
              : const ContactPickerArgs();
          return _buildRoutePage(
            state: state,
            child: MyGroupsPage(args: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.contactsMyFollowing,
        name: RouteNames.contactsMyFollowing,
        pageBuilder: (context, state) {
          final args = state.extra is ContactPickerArgs
              ? state.extra! as ContactPickerArgs
              : const ContactPickerArgs();
          return _buildRoutePage(
            state: state,
            child: MyFollowingPage(args: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.contactsFavorites,
        name: RouteNames.contactsFavorites,
        pageBuilder: (context, state) => _buildRoutePage(
          state: state,
          child: const StarContactsPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.contactsGroupMembers,
        name: RouteNames.contactsGroupMembers,
        pageBuilder: (context, state) {
          final args = state.extra is ContactGroupMembersArgs
              ? state.extra! as ContactGroupMembersArgs
              : const ContactGroupMembersArgs(
                  groupId: '',
                  groupName: '群成员',
                );
          return _buildRoutePage(
            state: state,
            child: ContactGroupMembersPage(args: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.favorites,
        name: RouteNames.favorites,
        pageBuilder: (context, state) =>
            _buildRoutePage(state: state, child: const FavoritesPage()),
      ),
      GoRoute(
        path: RoutePaths.initiateGroup,
        name: RouteNames.initiateGroup,
        pageBuilder: (context, state) {
          final args = state.extra is InitiateGroupArgs
              ? state.extra! as InitiateGroupArgs
              : const InitiateGroupArgs.create();
          return _buildRoutePage(
            state: state,
            child: InitiateGroupPage(args: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.favoriteDetail,
        name: RouteNames.favoriteDetail,
        pageBuilder: (context, state) {
          final args = state.extra is FavoriteDetailRouteArgs
              ? state.extra! as FavoriteDetailRouteArgs
              : const FavoriteDetailRouteArgs(favoriteId: '');
          return _buildRoutePage(
            state: state,
            child: FavoriteDetailPage(args: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.contactsProfile,
        name: RouteNames.contactsProfile,
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          final extra = state.extra;
          if (extra is Map<String, String>) {
            return _buildRoutePage(
              state: state,
              child: ContactProfilePage(
                userId: userId,
                name: extra['name'] ?? '用户',
                departmentName: extra['departmentName'] ?? '',
              ),
            );
          }
          return _buildRoutePage(
            state: state,
            child: ContactProfilePage(
              userId: userId,
              name: '用户',
              departmentName: '',
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.chat,
        name: RouteNames.chat,
        pageBuilder: (context, state) {
          final args = state.extra is ChatEntryArgs
              ? state.extra! as ChatEntryArgs
              : const ChatEntryArgs.empty();
          return _buildRoutePage(state: state, child: ChatPage(args: args));
        },
      ),
      GoRoute(
        path: RoutePaths.chatSelectContactCard,
        name: RouteNames.chatSelectContactCard,
        pageBuilder: (context, state) => _buildRoutePage(
          state: state,
          child: const SelectContactCardPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.chatSelectLocation,
        name: RouteNames.chatSelectLocation,
        pageBuilder: (context, state) =>
            _buildRoutePage(state: state, child: const SelectLocationPage()),
      ),
      GoRoute(
        path: RoutePaths.chatStickerManage,
        name: RouteNames.chatStickerManage,
        pageBuilder: (context, state) =>
            _buildRoutePage(state: state, child: const StickerManagePage()),
      ),
      GoRoute(
        path: RoutePaths.chatSettings,
        name: RouteNames.chatSettings,
        pageBuilder: (context, state) {
          final args = state.extra is ChatEntryArgs
              ? state.extra! as ChatEntryArgs
              : const ChatEntryArgs.empty();
          return _buildRoutePage(
            state: state,
            child: ChatSettingsPage(args: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.chatMedia,
        name: RouteNames.chatMedia,
        pageBuilder: (context, state) {
          final args = state.extra is ChatEntryArgs
              ? state.extra! as ChatEntryArgs
              : const ChatEntryArgs.empty();
          return _buildRoutePage(
            state: state,
            child: ChatMediaPage(args: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.chatHistory,
        name: RouteNames.chatHistory,
        pageBuilder: (context, state) {
          final args = state.extra is ChatEntryArgs
              ? state.extra! as ChatEntryArgs
              : const ChatEntryArgs.empty();
          return _buildRoutePage(
            state: state,
            child: ChatHistoryPage(chatArgs: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.chatReadReceipt,
        name: RouteNames.chatReadReceipt,
        pageBuilder: (context, state) {
          final args = state.extra is ReadReceiptRouteArgs
              ? state.extra! as ReadReceiptRouteArgs
              : const ReadReceiptRouteArgs(
                  messageId: '',
                  chatTitle: '',
                  messagePreview: '',
                );
          return _buildRoutePage(
            state: state,
            child: ReadReceiptPage(args: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.chatForwardTarget,
        name: RouteNames.chatForwardTarget,
        pageBuilder: (context, state) {
          final args = state.extra is ForwardTargetRouteArgs
              ? state.extra! as ForwardTargetRouteArgs
              : const ForwardTargetRouteArgs(messageIds: <String>[]);
          return _buildRoutePage(
            state: state,
            child: ForwardTargetPage(args: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.chatForwardCombineDetail,
        name: RouteNames.chatForwardCombineDetail,
        pageBuilder: (context, state) {
          final args = state.extra is ForwardCombineDetailRouteArgs
              ? state.extra! as ForwardCombineDetailRouteArgs
              : const ForwardCombineDetailRouteArgs(messageId: '');
          return _buildRoutePage(
            state: state,
            child: ForwardCombineDetailPage(args: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.chatVideoPlayer,
        name: RouteNames.chatVideoPlayer,
        pageBuilder: (context, state) {
          final args = state.extra is VideoPlayerRouteArgs
              ? state.extra! as VideoPlayerRouteArgs
              : const VideoPlayerRouteArgs(url: '');
          return _buildRoutePage(
            state: state,
            child: VideoPlayerPage(args: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.filePreview,
        name: RouteNames.filePreview,
        pageBuilder: (context, state) {
          final args = state.extra is FilePreviewRouteArgs
              ? state.extra! as FilePreviewRouteArgs
              : const FilePreviewRouteArgs(
                  fileId: '',
                  fileName: '',
                  mimeType: 'application/octet-stream',
                  fileSize: 0,
                );
          return _buildRoutePage(
            state: state,
            child: FilePreviewPage(
              args: FilePreviewArgs(
                fileId: args.fileId,
                fileName: args.fileName,
                mimeType: args.mimeType,
                fileSize: args.fileSize,
                fileUrl: args.fileUrl,
                messageId: args.messageId,
                chatId: args.chatId,
                sourceType: args.sourceType,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.groupSettings,
        name: RouteNames.groupSettings,
        pageBuilder: (context, state) {
          final args = state.extra is GroupContextArgs
              ? state.extra! as GroupContextArgs
              : const GroupContextArgs(groupId: '', groupName: '群聊设置');
          return _buildRoutePage(
            state: state,
            child: GroupSettingsPage(args: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.groupMembers,
        name: RouteNames.groupMembers,
        pageBuilder: (context, state) {
          final args = state.extra is GroupContextArgs
              ? state.extra! as GroupContextArgs
              : const GroupContextArgs(groupId: '', groupName: '群成员');
          return _buildRoutePage(
            state: state,
            child: GroupMembersPage(args: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.groupQrCode,
        name: RouteNames.groupQrCode,
        pageBuilder: (context, state) {
          final args = state.extra is GroupSettingDetailArgs
              ? state.extra! as GroupSettingDetailArgs
              : const GroupSettingDetailArgs(groupId: '', groupName: '群聊设置');
          return _buildRoutePage(
            state: state,
            child: GroupQrCodePage(args: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.groupAnnouncement,
        name: RouteNames.groupAnnouncement,
        pageBuilder: (context, state) {
          final args = state.extra is GroupSettingDetailArgs
              ? state.extra! as GroupSettingDetailArgs
              : const GroupSettingDetailArgs(groupId: '', groupName: '群聊设置');
          return _buildRoutePage(
            state: state,
            child: GroupAnnouncementPage(args: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.groupChatHistory,
        name: RouteNames.groupChatHistory,
        pageBuilder: (context, state) {
          final args = state.extra is GroupSettingDetailArgs
              ? state.extra! as GroupSettingDetailArgs
              : const GroupSettingDetailArgs(groupId: '', groupName: '群聊设置');
          return _buildRoutePage(
            state: state,
            child: ChatHistoryPage(groupArgs: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.groupJoinRequests,
        name: RouteNames.groupJoinRequests,
        pageBuilder: (context, state) {
          final args = state.extra is GroupContextArgs
              ? state.extra! as GroupContextArgs
              : const GroupContextArgs(groupId: '', groupName: '群聊设置');
          return _buildRoutePage(
            state: state,
            child: GroupJoinRequestsPage(args: args),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.groupMemberDetail,
        name: RouteNames.groupMemberDetail,
        pageBuilder: (context, state) {
          final args = state.extra is GroupMemberDetailArgs
              ? state.extra! as GroupMemberDetailArgs
              : const GroupMemberDetailArgs(
                  groupContext: GroupContextArgs(
                    groupId: '',
                    groupName: '群聊设置',
                  ),
                  memberUserId: '',
                  memberName: '成员',
                  memberRoleCode: 0,
                  colorValue: 0xFF8FB8F7,
                  canTransferOwner: false,
                  canRemoveMember: false,
                  canToggleAdmin: false,
                  canToggleMute: false,
                );
          return _buildRoutePage(
            state: state,
            child: GroupMemberDetailPage(
              args: args.groupContext,
              memberUserId: args.memberUserId,
              memberName: args.memberName,
              memberRoleCode: args.memberRoleCode,
              colorValue: args.colorValue,
              avatarUrl: args.avatarUrl,
              canTransferOwner: args.canTransferOwner,
              canRemoveMember: args.canRemoveMember,
              canToggleAdmin: args.canToggleAdmin,
              canToggleMute: args.canToggleMute,
              joinTime: args.joinTime,
              muteEndTime: args.muteEndTime,
              isMuted: args.isMuted,
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.deviceList,
        name: RouteNames.deviceList,
        pageBuilder: (context, state) =>
            _buildRoutePage(state: state, child: const DeviceListPage()),
      ),
    ],
  );
});

MaterialPage<void> _buildRoutePage({
  required GoRouterState state,
  required Widget child,
}) {
  return MaterialPage<void>(
    key: state.pageKey,
    name: state.name ?? state.path,
    arguments: <String, String>{
      ...state.pathParameters,
      ...state.uri.queryParameters,
    },
    restorationId: state.pageKey.value,
    child: child,
  );
}
