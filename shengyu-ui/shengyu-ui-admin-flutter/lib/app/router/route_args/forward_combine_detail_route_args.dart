class ForwardCombineDetailRouteArgs {
  const ForwardCombineDetailRouteArgs({
    required this.messageId,
    this.depth = 0,
    this.trace = const <String>[],
  });

  final String messageId;
  final int depth;
  final List<String> trace;
}
