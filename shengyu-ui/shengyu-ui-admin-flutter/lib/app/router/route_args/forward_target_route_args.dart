class ForwardTargetRouteArgs {
  const ForwardTargetRouteArgs({
    this.messageIds = const <String>[],
    this.initialForwardType = 1,
    this.favoriteId,
  });

  final List<String> messageIds;
  final int initialForwardType;
  final String? favoriteId;

  bool get isFavoriteMode {
    final value = favoriteId?.trim() ?? '';
    return value.isNotEmpty && value != '0';
  }
}
