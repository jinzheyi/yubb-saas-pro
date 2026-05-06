class VideoPlayerRouteArgs {
  const VideoPlayerRouteArgs({required this.url, this.fileId = '', this.title});

  final String url;
  final String fileId;
  final String? title;
}
