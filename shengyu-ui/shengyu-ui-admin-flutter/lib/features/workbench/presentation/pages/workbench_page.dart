import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_strings.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/primary_page_scaffold.dart';

class WorkbenchPage extends ConsumerWidget {
  const WorkbenchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final processItems = [
      PrimaryIconGridItem(
        title: strings.workbenchApproval,
        icon: AppIconKind.widgetsOutline,
        color: const Color(0xFFFF8F2C),
      ),
      PrimaryIconGridItem(
        title: strings.workbenchTodo,
        icon: AppIconKind.personFill,
        color: const Color(0xFF2BC98F),
      ),
      PrimaryIconGridItem(
        title: strings.workbenchCalendar,
        icon: AppIconKind.widgetsFill,
        color: const Color(0xFFFF5E79),
      ),
      PrimaryIconGridItem(
        title: strings.workbenchMeeting,
        icon: AppIconKind.contactsOutline,
        color: const Color(0xFF32A8F3),
      ),
      PrimaryIconGridItem(
        title: strings.workbenchFiles,
        icon: AppIconKind.chatFill,
        color: const Color(0xFF3D75F6),
      ),
    ];
    final commonItems = [
      PrimaryIconGridItem(
        title: strings.workbenchAnnouncements,
        icon: AppIconKind.muteOff,
        color: const Color(0xFFFF8F2C),
      ),
      PrimaryIconGridItem(
        title: strings.workbenchFiles,
        icon: AppIconKind.chatOutline,
        color: const Color(0xFF2BC98F),
      ),
      PrimaryIconGridItem(
        title: strings.workbenchMeeting,
        icon: AppIconKind.groupsOutline,
        color: const Color(0xFF23C5B5),
      ),
      PrimaryIconGridItem(
        title: strings.workbenchCalendar,
        icon: AppIconKind.history,
        color: const Color(0xFF32A8F3),
      ),
      PrimaryIconGridItem(
        title: strings.workbenchMail,
        icon: AppIconKind.muteOff,
        color: const Color(0xFFFFB41E),
      ),
      PrimaryIconGridItem(
        title: strings.workbenchDelegation,
        icon: AppIconKind.chevronRight,
        color: const Color(0xFF5A93F8),
      ),
      PrimaryIconGridItem(
        title: strings.workbenchAccountSwitch,
        icon: AppIconKind.sync,
        color: const Color(0xFF6F72F4),
      ),
      PrimaryIconGridItem(
        title: strings.workbenchAttendance,
        icon: AppIconKind.personFill,
        color: const Color(0xFF4779F5),
      ),
      PrimaryIconGridItem(
        title: strings.workbenchFieldWork,
        icon: AppIconKind.search,
        color: const Color(0xFFFFA12C),
      ),
    ];

    return PrimaryPageScaffold(
      title: strings.workbenchTitle,
      actions: [
        TextButton(
          onPressed: () => _showComingSoon(context, '工作台编辑骨架继续推进中'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF246BFD),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(strings.workbenchEdit),
        ),
      ],
      searchBar: PrimarySearchBar(
        hintText: strings.searchHint,
        onTap: () => _showComingSoon(context, '工作台搜索骨架继续推进中'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _WorkbenchSummaryStrip(
            pendingApprovalLabel: strings.workbenchApproval,
            pendingTodoLabel: strings.workbenchTodo,
            meetingLabel: strings.workbenchMeeting,
            metricValue: strings.workbenchMetricPlaceholder,
          ),
          const SizedBox(height: 14),
          PrimaryIconGridSection(
            title: strings.workbenchOfficeFlow,
            items: processItems,
            trailing: const AppIcon(
              AppIconKind.chevronUp,
              color: Color(0xFF8F96A3),
              size: 16,
            ),
            onTapItem: (item) =>
                _showComingSoon(context, '${item.title}骨架继续推进中'),
          ),
          const SizedBox(height: 14),
          PrimaryIconGridSection(
            title: strings.workbenchCommonFeatures,
            items: commonItems,
            trailing: const AppIcon(
              AppIconKind.chevronUp,
              color: Color(0xFF8F96A3),
              size: 16,
            ),
            onTapItem: (item) =>
                _showComingSoon(context, '${item.title}骨架继续推进中'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _WorkbenchSummaryStrip extends StatelessWidget {
  const _WorkbenchSummaryStrip({
    required this.pendingApprovalLabel,
    required this.pendingTodoLabel,
    required this.meetingLabel,
    required this.metricValue,
  });

  final String pendingApprovalLabel;
  final String pendingTodoLabel;
  final String meetingLabel;
  final String metricValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF246BFD),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              label: pendingApprovalLabel,
              value: metricValue,
            ),
          ),
          Expanded(
            child: _SummaryMetric(label: pendingTodoLabel, value: metricValue),
          ),
          Expanded(
            child: _SummaryMetric(label: meetingLabel, value: metricValue),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFDDE7FF),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
