import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/kds/kds_screen.dart';

class KDSApp extends ConsumerWidget {
  const KDSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'LaTercia Cocina',
      debugShowCheckedModeBanner: false,
      theme: buildKdsTheme(),
      home: const KdsScreen(),
    );
  }
}
