import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/read_receipt_route_args.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error_mapper.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/message_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/states/read_receipt_state.dart';

class ReadReceiptController extends StateNotifier<ReadReceiptState> {
  ReadReceiptController(this._messageRepository, this._args)
    : super(const ReadReceiptState());

  final MessageRepository _messageRepository;
  final ReadReceiptRouteArgs _args;

  Future<void> load() async {
    state = state.copyWith(status: ReadReceiptPageStatus.loading, error: null);
    try {
      final summary = await _messageRepository.getReadReceiptSummary(
        messageId: _args.messageId,
      );
      final selectedTab = (summary?.readCount ?? 0) > 0
          ? state.selectedTab
          : 'unread';
      final items = await _messageRepository.getReadReceiptDetail(
        messageId: _args.messageId,
        status: selectedTab,
      );
      state = state.copyWith(
        status: ReadReceiptPageStatus.ready,
        selectedTab: selectedTab,
        summary: summary,
        items: items,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        status: ReadReceiptPageStatus.failed,
        error: AppErrorMapper.map(error, stackTrace),
      );
    }
  }

  Future<void> switchTab(String status) async {
    if (state.selectedTab == status &&
        state.status == ReadReceiptPageStatus.ready) {
      return;
    }
    state = state.copyWith(
      status: ReadReceiptPageStatus.loading,
      selectedTab: status,
      error: null,
    );
    try {
      final items = await _messageRepository.getReadReceiptDetail(
        messageId: _args.messageId,
        status: status,
      );
      state = state.copyWith(status: ReadReceiptPageStatus.ready, items: items);
    } catch (error, stackTrace) {
      state = state.copyWith(
        status: ReadReceiptPageStatus.failed,
        error: AppErrorMapper.map(error, stackTrace),
      );
    }
  }
}
