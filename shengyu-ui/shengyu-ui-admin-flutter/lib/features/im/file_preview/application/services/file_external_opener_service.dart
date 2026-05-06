import 'package:url_launcher/url_launcher.dart';

abstract class FileExternalOpenerService {
  Future<void> open(Uri uri);
}

class UrlLauncherFileExternalOpenerService
    implements FileExternalOpenerService {
  const UrlLauncherFileExternalOpenerService();

  @override
  Future<void> open(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
