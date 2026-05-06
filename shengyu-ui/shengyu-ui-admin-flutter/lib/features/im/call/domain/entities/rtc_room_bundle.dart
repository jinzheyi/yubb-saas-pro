class RtcRoomBundle {
  const RtcRoomBundle({
    required this.callSessionId,
    required this.roomId,
    required this.publisherId,
    required this.displayName,
    required this.janusUrl,
    required this.turnUrls,
    required this.turnUsername,
    required this.turnCredential,
    required this.token,
  });

  final String callSessionId;
  final String roomId;
  final String publisherId;
  final String displayName;
  final String janusUrl;
  final List<String> turnUrls;
  final String turnUsername;
  final String turnCredential;
  final String token;
}
