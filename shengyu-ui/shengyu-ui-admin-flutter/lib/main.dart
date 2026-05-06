import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bootstrap/app_bootstrap.dart';

void main() {
  runApp(const ProviderScope(child: ShengyuImApp()));
}

class ShengyuImApp extends ConsumerWidget {
  const ShengyuImApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppBootstrap();
  }
}
