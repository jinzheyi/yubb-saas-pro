import 'package:shengyu_ui_admin_im/core/error/app_error.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/read_receipt_detail_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/read_receipt_summary.dart';

enum ReadReceiptPageStatus { initial, loading, ready, failed }

class ReadReceiptState {
  const ReadReceiptState({
    this.status = ReadReceiptPageStatus.initial,
    this.selectedTab = 'read',
    this.summary,
    this.items = const <ReadReceiptDetailItem>[],
    this.error,
  });

  final ReadReceiptPageStatus status;
  final String selectedTab;
  final ReadReceiptSummary? summary;
  final List<ReadReceiptDetailItem> items;
  final AppError? error;

  ReadReceiptState copyWith({
    ReadReceiptPageStatus? status,
    String? selectedTab,
    ReadReceiptSummary? summary,
    List<ReadReceiptDetailItem>? items,
    AppError? error,
  }) {
    return ReadReceiptState(
      status: status ?? this.status,
      selectedTab: selectedTab ?? this.selectedTab,
      summary: summary ?? this.summary,
      items: items ?? this.items,
      error: error,
    );
  }
}
