import 'dart:io';

import 'package:shengyu_ui_admin_im/shared/emoji/chat_emoji_catalog.dart';

Future<void> main() async {
  final created = <String>[];
  for (final entry in ChatEmojiCatalog.assetByCode.entries) {
    final source = ChatEmojiCatalog.sourceAssetByCode[entry.key];
    final target = entry.value;
    if (source == null || source.isEmpty || target.isEmpty) {
      stderr.writeln('skip ${entry.key}: missing source/target');
      continue;
    }
    final sourceFile = File(source);
    if (!sourceFile.existsSync()) {
      stderr.writeln('missing source for ${entry.key}: $source');
      continue;
    }
    final targetFile = File(target);
    targetFile.parent.createSync(recursive: true);
    sourceFile.copySync(targetFile.path);
    created.add(targetFile.path);
  }
  stdout.writeln('generated ${created.length} safe emoji assets');
}
