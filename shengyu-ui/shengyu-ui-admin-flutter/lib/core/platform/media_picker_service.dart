import 'package:file_picker/file_picker.dart';
import 'package:shengyu_ui_admin_im/core/platform/picked_file.dart';

abstract class MediaPickerService {
  Future<PickedFile?> pickImage();

  Future<PickedFile?> captureImage();

  Future<PickedFile?> pickVideo();

  Future<PickedFile?> pickFile();
}

class FilePickerMediaPickerService implements MediaPickerService {
  const FilePickerMediaPickerService();

  @override
  Future<PickedFile?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
    );
    return _map(result);
  }

  @override
  Future<PickedFile?> captureImage() {
    // Current desktop/web debug chain has no dedicated camera plugin wiring yet.
    // Keep the page off platform plugins and degrade to image picking for now.
    return pickImage();
  }

  @override
  Future<PickedFile?> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.video,
    );
    return _map(result);
  }

  @override
  Future<PickedFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );
    return _map(result);
  }

  PickedFile? _map(FilePickerResult? result) {
    final file = result?.files.singleOrNull;
    final path = file?.path;
    if (file == null || path == null || path.isEmpty) {
      return null;
    }
    return PickedFile(
      path: path,
      name: file.name,
      mimeType: _resolveMimeType(file.extension ?? ''),
      size: file.size,
    );
  }

  String _resolveMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'm4v':
        return 'video/x-m4v';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
