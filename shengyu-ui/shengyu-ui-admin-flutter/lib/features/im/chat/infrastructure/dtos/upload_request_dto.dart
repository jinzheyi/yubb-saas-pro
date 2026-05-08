import 'dart:typed_data';

class UploadRequestDto {
  const UploadRequestDto({
    required this.localUri,
    required this.fileName,
    required this.directory,
    required this.fieldName,
    required this.mimeType,
    this.bytes,
    this.maxSize,
  });

  final String localUri;
  final String fileName;
  final String directory;
  final String fieldName;
  final String mimeType;
  final Uint8List? bytes;
  final int? maxSize;
}
