import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bootstrap/app_bootstrap.dart';

void main() async {
  // 初始化 Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: ShengyuImApp()));
}

class ShengyuImApp extends ConsumerStatefulWidget {
  const ShengyuImApp({super.key});

  @override
  ConsumerState<ShengyuImApp> createState() => _ShengyuImAppState();
}

class _ShengyuImAppState extends ConsumerState<ShengyuImApp> {
  @override
  void initState() {
    super.initState();
    // 在 initState 中配置图片缓存，确保 binding 已完全初始化
    PaintingBinding.instance.imageCache.maximumSize = 200;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024; // 100MB
  }

  @override
  Widget build(BuildContext context) {
    return const AppBootstrap();
  }
}
