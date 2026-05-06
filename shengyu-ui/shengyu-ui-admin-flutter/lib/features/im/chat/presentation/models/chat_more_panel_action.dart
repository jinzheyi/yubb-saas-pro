enum ChatMorePanelAction {
  album,
  camera,
  video,
  file,
  location,
  contact,
  favorite,
  call,
}

enum ChatMorePanelFollowUpAction { openLocationPicker, openContactPicker }

class ChatMorePanelResult {
  const ChatMorePanelResult({this.noticeMessage, this.followUpAction});

  final String? noticeMessage;
  final ChatMorePanelFollowUpAction? followUpAction;
}
