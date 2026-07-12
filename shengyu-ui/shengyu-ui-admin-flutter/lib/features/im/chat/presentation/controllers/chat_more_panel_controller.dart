import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/controllers/chat_media_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/models/chat_more_panel_action.dart';

class ChatMorePanelController {
  const ChatMorePanelController(this._chatMediaController);

  final ChatMediaController _chatMediaController;

  Future<ChatMorePanelResult> handleAction({
    required ChatMorePanelAction action,
    required ChatEntryArgs entryArgs,
    required String chatTitle,
  }) async {
    switch (action) {
      case ChatMorePanelAction.album:
        await _chatMediaController.pickAndUploadImage(
          entryArgs: entryArgs,
          chatTitle: chatTitle,
        );
        return const ChatMorePanelResult();
      case ChatMorePanelAction.camera:
        await _chatMediaController.captureAndUploadImage(
          entryArgs: entryArgs,
          chatTitle: chatTitle,
        );
        return const ChatMorePanelResult();
      case ChatMorePanelAction.file:
        await _chatMediaController.pickAndUploadFile(
          entryArgs: entryArgs,
          chatTitle: chatTitle,
        );
        return const ChatMorePanelResult();
      case ChatMorePanelAction.location:
        return const ChatMorePanelResult(
          followUpAction: ChatMorePanelFollowUpAction.openLocationPicker,
        );
      case ChatMorePanelAction.contact:
        return const ChatMorePanelResult(
          followUpAction: ChatMorePanelFollowUpAction.openContactPicker,
        );
      case ChatMorePanelAction.favorite:
        return const ChatMorePanelResult();
      case ChatMorePanelAction.call:
        return const ChatMorePanelResult();
    }
  }
}
