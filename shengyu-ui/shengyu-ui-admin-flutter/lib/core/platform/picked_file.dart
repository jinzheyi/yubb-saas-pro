class PickedFile {
  const PickedFile({
    required this.path,
    required this.name,
    required this.mimeType,
    required this.size,
  });

  final String path;
  final String name;
  final String mimeType;
  final int size;
}
