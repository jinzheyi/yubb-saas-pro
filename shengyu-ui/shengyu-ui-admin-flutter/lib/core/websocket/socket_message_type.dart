abstract final class SocketMessageType {
  static const heartbeatReq = 1;
  static const heartbeatResp = 2;
  static const authReq = 3;
  static const authResp = 4;
  static const close = 5;
  static const probe = 6;
  static const probeResp = 7;

  static const text = 100;
  static const image = 101;
  static const voice = 102;
  static const video = 103;
  static const file = 104;
  static const location = 105;
  static const custom = 106;

  static const systemNotify = 200;
  static const readReceipt = 201;
  static const recall = 202;
  static const typing = 203;
  static const badgeUpdate = 204;
  static const quoteReply = 205;
  static const callRecord = 209;
}
