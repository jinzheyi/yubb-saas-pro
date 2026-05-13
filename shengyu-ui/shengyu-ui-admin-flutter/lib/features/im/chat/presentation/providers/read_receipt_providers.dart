import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/read_receipt_route_args.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/controllers/read_receipt_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/controllers/read_receipt_summary_store.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/states/read_receipt_state.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/states/read_receipt_summary_store_state.dart';

final readReceiptSummaryStoreProvider =
    StateNotifierProvider<
      ReadReceiptSummaryStore,
      ReadReceiptSummaryStoreState
    >((ref) {
      return ReadReceiptSummaryStore(ref.read(messageRepositoryProvider));
    });

final readReceiptControllerProvider = StateNotifierProvider.autoDispose
    .family<ReadReceiptController, ReadReceiptState, ReadReceiptRouteArgs>((
      ref,
      args,
    ) {
      return ReadReceiptController(
        ref.read(messageRepositoryProvider),
        ref.read(readReceiptSummaryStoreProvider.notifier),
        args,
      );
    });
