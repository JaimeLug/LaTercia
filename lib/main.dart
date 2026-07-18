import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/orders_provider.dart';
import 'core/services/kds_button_service.dart';
import 'core/services/kds_client.dart';
import 'core/utils/app_logger.dart';
import 'core/utils/backup_helper.dart';
import 'kds_app.dart';

void main(List<String> args) {
  runZonedGuarded(() async {
    await _mainImpl(args);
  }, (error, stackTrace) {
    appLogger.error('Excepción no atrapada en runZonedGuarded', error, stackTrace);
  });
}

Future<void> _mainImpl(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final previousOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    appLogger.error(
      'FlutterError: ${details.exceptionAsString()}',
      details.exception,
      details.stack,
    );
    previousOnError?.call(details);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    appLogger.error('Error no manejado en PlatformDispatcher', error, stackTrace);
    return true;
  };

  await appLogger.init();

  await windowManager.ensureInitialized();
  await initializeDateFormatting('es_MX', null);

  final isKds = args.contains('kds');

  // Apply a staged database restore, if any, before the database is opened.
  // Only the main POS process does this — the KDS shares the same file and
  // must not race to swap it.
  if (!isKds) {
    await applyPendingRestoreIfAny();
  }

  if (isKds) {
    // Parse optional screen position: kds --x=0 --y=0 --w=1920 --h=1080
    double? sx, sy, sw, sh;
    for (final a in args) {
      if (a.startsWith('--x=')) sx = double.tryParse(a.substring(4));
      if (a.startsWith('--y=')) sy = double.tryParse(a.substring(4));
      if (a.startsWith('--w=')) sw = double.tryParse(a.substring(4));
      if (a.startsWith('--h=')) sh = double.tryParse(a.substring(4));
    }

    final kdsSize = (sw != null && sh != null)
        ? Size(sw, sh)
        : const Size(1280, 800);

    final kdsOptions = WindowOptions(
      size: kdsSize,
      title: 'Cocina — LaTercia KDS',
      backgroundColor: const Color(0xFF111827),
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(kdsOptions, () async {
      if (sx != null && sy != null) {
        await windowManager.setPosition(Offset(sx, sy));
      }
      await windowManager.show();
      await windowManager.setFullScreen(true);
    });
    // FASE 5.1 — La ventana KDS separada es viewer por WebSocket: su
    // OrdersNotifier recibe un KdsClient que la conecta al servidor del proceso
    // POS. Si el WS no responde, el notifier cae al polling de BD (fallback).
    // La MISMA instancia también reenvía los botones de la botonera física
    // (3.5) — el ESP32 solo puede hablarle al proceso POS (dueño del puerto
    // 8080), así que esta ventana los recibe reenviados por el mismo canal.
    final kdsClient = KdsClient();
    runApp(ProviderScope(
      overrides: [
        ordersProvider.overrideWith(
          (ref) => OrdersNotifier(
            ref.watch(databaseProvider),
            kdsClient: kdsClient,
          ),
        ),
        kdsButtonStreamProvider.overrideWithValue(kdsClient.botonPresionado),
      ],
      child: const KDSApp(),
    ));
  } else {
    const posOptions = WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(1024, 700),
      center: true,
      title: 'LaTercia POS',
      backgroundColor: Colors.white,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(posOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.maximize();
    });
    runApp(const ProviderScope(child: LaTerciaApp()));
  }
}
