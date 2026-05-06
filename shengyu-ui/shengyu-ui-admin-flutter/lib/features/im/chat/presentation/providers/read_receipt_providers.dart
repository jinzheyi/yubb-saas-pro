import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/read_receipt_route_args.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/controllers/read_receipt_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/states/read_receipt_state.dart';

final readReceiptControllerProvider = StateNotifierProvider.autoDispose
    .family<ReadReceiptController, ReadReceiptState, ReadReceiptRouteArgs>((
      ref,
      args,
    ) {
      return ReadReceiptController(ref.read(messageRepositoryProvider), args);
    });
