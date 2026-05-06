import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_strings.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/read_receipt_route_args.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/read_receipt_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/states/read_receipt_state.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_error_view.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_loading_view.dart';

class ReadReceiptPage extends ConsumerStatefulWidget {
  const ReadReceiptPage({super.key, required this.args});

  final ReadReceiptRouteArgs args;

  @override
  ConsumerState<ReadReceiptPage> createState() => _ReadReceiptPageState();
}

class _ReadReceiptPageState extends ConsumerState<ReadReceiptPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          ref.read(readReceiptControllerProvider(widget.args).notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final state = ref.watch(readReceiptControllerProvider(widget.args));
    final summary = state.summary;
    final readCount = summary?.readCount ?? 0;
    final unreadCount = summary?.unreadCount ?? 0;
    return DefaultTabController(
      length: 2,
      initialIndex: state.selectedTab == 'unread' ? 1 : 0,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: Text(strings.chatReadReceiptTitle),
          bottom: TabBar(
            onTap: (index) {
              ref
                  .read(readReceiptControllerProvider(widget.args).notifier)
                  .switchTab(index == 0 ? 'read' : 'unread');
            },
            tabs: [
              Tab(text: strings.chatReadReceiptRead(readCount)),
              Tab(text: strings.chatReadReceiptUnread(unreadCount)),
            ],
          ),
        ),
        body: switch (state.status) {
          ReadReceiptPageStatus.initial ||
          ReadReceiptPageStatus.loading => const AppLoadingView(),
          ReadReceiptPageStatus.failed => AppErrorView(
            error: state.error,
            onRetry: () => ref
                .read(readReceiptControllerProvider(widget.args).notifier)
                .load(),
          ),
          ReadReceiptPageStatus.ready => Column(
            children: [
              _SummaryCard(
                chatTitle: widget.args.chatTitle,
                preview: widget.args.messagePreview,
                totalCount: summary?.totalCount ?? 0,
              ),
              Expanded(
                child: state.items.isEmpty
                    ? Center(
                        child: Text(
                          state.selectedTab == 'read'
                              ? strings.chatReadReceiptEmptyRead
                              : strings.chatReadReceiptEmptyUnread,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8F96A3),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          final subtitle = state.selectedTab == 'read'
                              ? _formatReadTime(context, item.readTime)
                              : strings.chatReadReceiptUnreadLabel;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: ContactsInitialAvatar(
                              name: item.userName,
                              color: const Color(0xFF246BFD),
                              avatarUrl: item.avatar,
                              size: 40,
                              borderRadius: 20,
                            ),
                            title: Text(
                              item.userName.isEmpty
                                  ? strings.chatReadReceiptUnknownUser
                                  : item.userName,
                            ),
                            subtitle: Text(subtitle),
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemCount: state.items.length,
                      ),
              ),
            ],
          ),
        },
      ),
    );
  }

  String _formatReadTime(BuildContext context, DateTime? value) {
    if (value == null) {
      return ref.read(appStringsProvider).chatReadReceiptReadAtUnknown;
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMd(locale).add_Hm().format(value);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.chatTitle,
    required this.preview,
    required this.totalCount,
  });

  final String chatTitle;
  final String preview;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chatTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202531),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7380)),
          ),
          const SizedBox(height: 10),
          Text(
            strings.chatReadReceiptTotal(totalCount),
            style: const TextStyle(fontSize: 12, color: Color(0xFF98A1B2)),
          ),
        ],
      ),
    );
  }
}
