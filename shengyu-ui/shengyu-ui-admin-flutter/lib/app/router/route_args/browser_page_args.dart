class BrowserPageArgs {
  const BrowserPageArgs({
    required this.url,
    this.title,
    this.source = 'external',
    this.rawContent,
  });

  final String url;
  final String? title;
  final String source;
  final String? rawContent;
}
