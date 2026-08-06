import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_record.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/call_history_provider.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

/// 通话记录汇总页面
/// 
/// 参考微信「通讯录 → 通话」入口，提供独立的通话记录汇总页面
class CallHistoryPage extends ConsumerStatefulWidget {
  const CallHistoryPage({super.key});

  @override
  ConsumerState<CallHistoryPage> createState() => _CallHistoryPageState();
}

class _CallHistoryPageState extends ConsumerState<CallHistoryPage> {
  int? _filterType; // null=全部，1=语音，2=视频
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final filter = CallHistoryFilter(
      filterType: _filterType,
      dateRange: _dateRange,
    );
    final callRecords = ref.watch(callHistoryProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('通话记录'),
        actions: [
          // 筛选按钮
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: callRecords.when(
        data: (records) => records.isEmpty
            ? const Center(child: Text('暂无通话记录'))
            : ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return CallHistoryItem(record: record);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('筛选条件'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 通话类型筛选
            DropdownButton<int?>(
              value: _filterType,
              hint: const Text('通话类型'),
              items: const [
                DropdownMenuItem(value: null, child: Text('全部')),
                DropdownMenuItem(value: 1, child: Text('语音通话')),
                DropdownMenuItem(value: 2, child: Text('视频通话')),
              ],
              onChanged: (value) {
                Navigator.pop(dialogContext);
                setState(() => _filterType = value);
              },
            ),
            // 时间范围筛选
            ListTile(
              title: const Text('时间范围'),
              subtitle: Text(_dateRange != null
                  ? '${_dateRange!.start.toString().split(' ')[0]} - ${_dateRange!.end.toString().split(' ')[0]}'
                  : '全部'),
              onTap: () async {
                // Store the dialog context in a local variable
                final ctx = dialogContext;
                final range = await showDateRangePicker(
                  context: ctx,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                // Check if the dialog context is still valid after the async operation
                if (range != null && ctx.mounted) {
                  Navigator.pop(ctx);
                  setState(() => _dateRange = range);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 通话记录列表项
class CallHistoryItem extends StatelessWidget {
  final CallRecord record;

  const CallHistoryItem({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AppAvatar(
        name: record.peerName ?? '未知用户',
        avatarUrl: record.peerAvatar,
        size: 48,
      ),
      title: Text(record.peerName ?? '未知用户'),
      subtitle: Row(
        children: [
          Icon(
            record.callType == 2
                ? Icons.videocam_outlined
                : Icons.call_outlined,
            size: 14,
            color: _statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            _buildSubtitle(),
            style: TextStyle(color: _statusColor, fontSize: 12),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(record.startTime),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (record.duration > 0)
            Text(
              _formatDuration(record.duration),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
        ],
      ),
      onTap: () {
        context.pushNamed(
          RouteNames.chat,
          extra: ChatEntryArgs.latest(
            chatId: record.chatId,
            conversationType: record.conversationType,
            targetId: record.peerId,
            title: record.peerName,
          ),
        );
      },
    );
  }

  /// 状态颜色（已接通绿色，未接通灰色）
  Color get _statusColor {
    if (record.status == 1) {
      return const Color(0xFF4CAF50); // 绿色
    }
    return const Color(0xFF9E9E9E); // 灰色
  }

  /// 构建副标题
  String _buildSubtitle() {
    switch (record.status) {
      case 1: // 已接通
        return '已接通';
      case 2: // 未接听
        return record.isCaller ? '已拨打' : '未接听';
      case 3: // 已拒绝
        return record.isCaller ? '已取消' : '对方已拒绝';
      case 4: // 忙线
        return '对方忙线中';
      case 5: // 已取消
        return '已取消';
      default:
        return '通话结束';
    }
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) {
      // 今天
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff == 1) {
      // 昨天
      return '昨天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff < 7) {
      // 本周
      const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return '${weekdays[time.weekday - 1]} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      // 更早
      return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
    }
  }

  /// 格式化通话时长
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '$hours小时$minutes分$secs秒';
    } else if (minutes > 0) {
      return '$minutes分$secs秒';
    } else {
      return '$secs秒';
    }
  }
}
