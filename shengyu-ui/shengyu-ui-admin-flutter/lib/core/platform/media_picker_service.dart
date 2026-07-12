import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' hide PickedFile;
import 'package:shengyu_ui_admin_im/app/router/route_args/camera_capture_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/core/platform/picked_file.dart';

abstract class MediaPickerService {
  Future<PickedFile?> pickImage();

  Future<PickedFile?> captureImage();

  /// 使用自定义相机页面进行拍摄（支持拍照+录像）。
  ///
  /// 返回拍摄文件的本地路径，用户取消时返回 null。
  Future<String?> captureWithCustomCamera(BuildContext context);

  Future<PickedFile?> pickFile();
}

class FilePickerMediaPickerService implements MediaPickerService {
  FilePickerMediaPickerService();

  final ImagePicker _imagePicker = ImagePicker();

  @override
  Future<PickedFile?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
    );
    return _map(result);
  }

  @override
  Future<PickedFile?> captureImage() async {
    final xFile = await _imagePicker.pickImage(source: ImageSource.camera);
    if (xFile == null) {
      return null;
    }
    final bytes = await xFile.readAsBytes();
    return PickedFile(
      path: xFile.path,
      name: _fileNameFromPath(xFile.path),
      mimeType: _resolveMimeType(_extensionFromPath(xFile.path), bytes: bytes),
      size: bytes.lengthInBytes,
      bytes: bytes,
    );
  }

  @override
  Future<String?> captureWithCustomCamera(BuildContext context) async {
    return context.pushNamed<String>(RouteNames.chatCameraCapture);
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
    if (file == null) {
      return null;
    }
    final bytes = file.bytes;
    final path = file.path ?? '';
    if (path.isEmpty && (bytes == null || bytes.isEmpty)) {
      return null;
    }
    return PickedFile(
      path: path,
      name: file.name,
      mimeType: _resolveMimeType(file.extension ?? '', bytes: bytes),
      size: file.size > 0 ? file.size : (bytes?.lengthInBytes ?? 0),
      bytes: bytes,
    );
  }

  String _fileNameFromPath(String path) {
    final index = path.lastIndexOf('/');
    if (index >= 0 && index < path.length - 1) {
      return path.substring(index + 1);
    }
    return path;
  }

  String _extensionFromPath(String path) {
    final index = path.lastIndexOf('.');
    if (index >= 0 && index < path.length - 1) {
      return path.substring(index + 1);
    }
    return '';
  }

  String _resolveMimeType(String extension, {Uint8List? bytes}) {
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
        return bytes != null && bytes.isNotEmpty
            ? 'application/octet-stream'
            : 'application/octet-stream';
    }
  }
}
