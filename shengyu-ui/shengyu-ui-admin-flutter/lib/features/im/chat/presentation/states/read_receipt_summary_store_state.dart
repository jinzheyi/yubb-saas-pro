import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/read_receipt_summary.dart';

class ReadReceiptSummaryStoreState {
  const ReadReceiptSummaryStoreState({
    this.entries = const <String, ReadReceiptSummaryCacheEntry>{},
  });

  final Map<String, ReadReceiptSummaryCacheEntry> entries;

  ReadReceiptSummaryStoreState copyWith({
    Map<String, ReadReceiptSummaryCacheEntry>? entries,
  }) {
    return ReadReceiptSummaryStoreState(entries: entries ?? this.entries);
  }
}

class ReadReceiptSummaryCacheEntry {
  const ReadReceiptSummaryCacheEntry({
    required this.summary,
    required this.fetchedAt,
  });

  final ReadReceiptSummary? summary;
  final DateTime fetchedAt;
}
