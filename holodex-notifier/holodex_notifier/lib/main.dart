import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holodex_notifier/application/controllers/app_controller.dart';
import 'package:holodex_notifier/application/state/settings_providers.dart';
import 'package:holodex_notifier/domain/interfaces/api_service.dart';
import 'package:holodex_notifier/domain/interfaces/background_polling_service.dart';
import 'package:holodex_notifier/domain/interfaces/cache_service.dart';
import 'package:holodex_notifier/domain/interfaces/connectivity_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/interfaces/notification_action_handler.dart';
import 'package:holodex_notifier/domain/interfaces/notification_decision_service.dart';
import 'package:holodex_notifier/domain/interfaces/notification_service.dart';
import 'package:holodex_notifier/domain/interfaces/secure_storage_service.dart';
import 'package:holodex_notifier/domain/interfaces/settings_service.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart';
import 'package:holodex_notifier/infrastructure/network/dio_client.dart';
import 'package:holodex_notifier/infrastructure/services/background_poller_service.dart';
import 'package:holodex_notifier/infrastructure/services/connectivity_plus_service.dart';
import 'package:holodex_notifier/infrastructure/services/drift_cache_service.dart';
import 'package:holodex_notifier/infrastructure/services/flutter_secure_storage_service.dart';
import 'package:holodex_notifier/infrastructure/services/holodex_api_service.dart';
import 'package:holodex_notifier/infrastructure/services/local_notification_service.dart';
import 'package:holodex_notifier/infrastructure/services/logger_service.dart';
import 'package:holodex_notifier/infrastructure/services/notification_action_handler.dart';
import 'package:holodex_notifier/infrastructure/services/notification_decision_service.dart';
import 'package:holodex_notifier/infrastructure/services/shared_prefs_settings_service.dart';
import 'package:holodex_notifier/ui/screens/home_screen.dart';
import 'package:dio/dio.dart';

enum IsolateContext { main, background }

final isolateContextProvider = Provider<IsolateContext>((ref) {
  return IsolateContext.main;
}, name: 'isolateContextProvider');

final loggingServiceProvider = Provider<ILoggingService>((ref) {
  return LoggerService();
});

final secureStorageServiceProvider = Provider<ISecureStorageService>((ref) {
  return FlutterSecureStorageService();
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final log = ref.watch(loggingServiceProvider);
  final db = AppDatabase(openConnection(), log);

  ref.onDispose(() async {
    log.info("Closing database connection...");
    await db.close();
    log.info("Database connection closed.");
  });

  return db;
});

final cacheServiceProvider = Provider<ICacheService>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftCacheService(db);
});

final connectivityServiceProvider = Provider<IConnectivityService>((ref) {
  return ConnectivityPlusService();
});

final dioProvider = Provider<Dio>((ref) {
  final log = ref.watch(loggingServiceProvider);
  final settingsService = ref.watch(settingsServiceProvider);
  apiKeyGetter() async {
    return settingsService.getApiKey();
  }

  final dioClient = DioClient(apiKeyGetter: apiKeyGetter, logger: log);
  return dioClient.instance;
});

final apiServiceProvider = Provider<IApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return HolodexApiService(dio);
});

final settingsServiceFutureProvider = FutureProvider<ISettingsService>((ref) async {
  final log = ref.watch(loggingServiceProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final service = SharedPrefsSettingsService(secureStorage);
  log.info("Initializing Settings Service...");
  await service.initialize();
  log.info("Settings Service initialized.");
  return service;
}, name: 'settingsServiceFutureProvider');

final notificationServiceFutureProvider = FutureProvider<INotificationService>((ref) async {
  final log = ref.watch(loggingServiceProvider);
  final settingsService = ref.watch(settingsServiceProvider);

  final service = LocalNotificationService(log, settingsService);

  final isolateContext = ref.watch(isolateContextProvider);

  log.info("Resolving Notification Service Provider (Isolate Context: $isolateContext)");

  if (isolateContext == IsolateContext.main) {
    log.info("Initializing Notification Service (Main Isolate)...");
    try {
      await service.initialize();
      log.info("Notification Service initialized (Main Isolate).");
    } catch (e, s) {
      log.fatal("Failed Notification Service initialization in Main Isolate", e, s);
      rethrow;
    }
  } else {
    log.info("Skipping Notification Service initialization (Background Isolate). Assumes main isolate succeeded.");
  }

  return service;
}, name: 'notificationServiceFutureProvider');

final backgroundServiceFutureProvider = FutureProvider<IBackgroundPollingService>((ref) async {
  final log = ref.watch(loggingServiceProvider);
  final service = BackgroundPollerService();
  log.info("Initializing Background Service...");
  await service.initialize();
  log.info("Background Service initialized (Setup).");
  return service;
}, name: 'backgroundServiceFutureProvider');

final settingsServiceProvider = Provider<ISettingsService>((ref) {
  return ref.watch(settingsServiceFutureProvider).requireValue;
}, name: 'settingsServiceProvider');

final notificationServiceProvider = Provider<INotificationService>((ref) {
  return ref.watch(notificationServiceFutureProvider).requireValue;
}, name: 'notificationServiceProvider');

final backgroundServiceProvider = Provider<IBackgroundPollingService>((ref) {
  return ref.watch(backgroundServiceFutureProvider).requireValue;
}, name: 'backgroundServiceProvider');

final notificationDecisionServiceProvider = Provider<INotificationDecisionService>((ref) {
  final cacheService = ref.watch(cacheServiceProvider);
  final settingsService = ref.watch(settingsServiceProvider);
  final logger = ref.watch(loggingServiceProvider);
  return NotificationDecisionService(cacheService, settingsService, logger);
}, name: 'notificationDecisionServiceProvider');

final notificationActionHandlerProvider = Provider<INotificationActionHandler>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final logger = ref.watch(loggingServiceProvider);
  return NotificationActionHandler(notificationService, cacheService, logger);
}, name: 'notificationActionHandlerProvider');

final appControllerProvider = Provider<AppController>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  final loggingService = ref.watch(loggingServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final decisionService = ref.watch(notificationDecisionServiceProvider);
  final actionHandler = ref.watch(notificationActionHandlerProvider);

  return AppController(ref, settingsService, loggingService, cacheService, notificationService, decisionService, actionHandler);
}, name: 'appControllerProvider');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  ILoggingService? logger;
  ISettingsService? settingsService;
  // ignore: unused_local_variable
  INotificationService? notificationService;

  Future<String> getSystemInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    StringBuffer info = StringBuffer();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        info.writeln('--- System Info ---');

        info.writeln('Device Type: ${androidInfo.type}, Model: ${androidInfo.model}, Manufacturer: ${androidInfo.manufacturer}');
        info.writeln('Android Version: ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})');
        info.writeln('Build ID: ${androidInfo.display}');
        info.writeln('Hardware: ${androidInfo.hardware}');
        info.writeln('Board: ${androidInfo.board}');
        info.writeln('Is Physical Device: ${androidInfo.isPhysicalDevice}');
        info.writeln('Supported ABIs: ${androidInfo.supportedAbis.join(', ')}');
      } else if (Platform.isWindows) {
        WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
        info.writeln('--- System Info ---');
        info.writeln('Computer Name: ${windowsInfo.computerName}');
        info.writeln('Number of Cores: ${windowsInfo.numberOfCores}');
        info.writeln('System Memory (MB): ${windowsInfo.systemMemoryInMegabytes}');
        info.writeln('Windows Version: ${windowsInfo.displayVersion} (Build ${windowsInfo.buildNumber})');
        info.writeln('Product Name: ${windowsInfo.productName}');
        info.writeln('Registered Owner: ${windowsInfo.registeredOwner}');
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        info.writeln('--- System Info ---');
        info.writeln('Device: ${iosInfo.name} ${iosInfo.model}');
        info.writeln('OS: ${iosInfo.systemName} ${iosInfo.systemVersion}');
        info.writeln('IsPhysicalDevice: ${iosInfo.isPhysicalDevice}');
      } else if (Platform.isLinux) {
        LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
        info.writeln('--- System Info ---');
        info.writeln('Name: ${linuxInfo.name}');
        info.writeln('Version: ${linuxInfo.version}');
        info.writeln('ID: ${linuxInfo.id}');
        info.writeln('Pretty Name: ${linuxInfo.prettyName}');
      } else if (Platform.isMacOS) {
        MacOsDeviceInfo macOsInfo = await deviceInfo.macOsInfo;
        info.writeln('--- System Info ---');
        info.writeln('Model: ${macOsInfo.model}');
        info.writeln('OS Release: ${macOsInfo.osRelease}');
        info.writeln('Kernel Version: ${macOsInfo.kernelVersion}');
        info.writeln('Memory Size: ${macOsInfo.memorySize}');
        info.writeln('CPU Cores: ${macOsInfo.cpuFrequency}');
      } else {
        info.writeln('--- System Info ---');
        info.writeln('OS: Unknown Platform');
      }
    } catch (e) {
      info.writeln('--- System Info ---');
      info.writeln('Error getting device info: $e');
    }
    info.writeln('App Version: 0.1.0');
    info.writeln('-------------------');
    return info.toString();
  }

  try {
    logger = container.read(loggingServiceProvider)!;
    logger.info("Logger initialized.");

    final systemInfo = await getSystemInfo();
    if (logger is ILoggingServiceWithOutput) {
      logger.setSystemInfoString(systemInfo);
      logger.info("System Info collected and set.");
    } else {
      logger.warning("Logger service does not support setting system info string.");
    }

    logger.info("Waiting for Settings Service...");
    settingsService = await container.read(settingsServiceFutureProvider.future);
    logger.info("Settings Service resolved.");

    await settingsService!.setMainServicesReady(false);
    logger.info("Main Services Readiness Flag RESET to FALSE.");

    logger.info("Waiting for Notification Service...");
    notificationService = await container.read(notificationServiceFutureProvider.future);
    logger.info("Notification Service resolved.");

    logger.info("Waiting for Background Service...");
    final backgroundService = await container.read(backgroundServiceFutureProvider.future);
    logger.info("Background Service resolved.");

    logger.info("All core async services initialized.");

    try {
      logger.info("Starting background polling service...");
      await backgroundService.startPolling();
      logger.info("Background polling service start initiated.");
    } catch (e, s) {
      logger.error("Error starting background polling service", e, s);
    }

    await settingsService.setMainServicesReady(true);
    logger.info("Main Services Readiness Flag SET to TRUE.");

    logger.info("Loading initial state values for UI overrides...");
    final initialPollFrequency = await settingsService.getPollFrequency();
    final initialGrouping = await settingsService.getNotificationGrouping();
    final initialDelay = await settingsService.getDelayNewMedia();
    final initialReminderLeadTime = await settingsService.getReminderLeadTime();

    logger.info("Initial state values loaded.");

    logger.info("Running app...");
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: ProviderScope(
          overrides: [
            pollFrequencyProvider.overrideWith((ref) => initialPollFrequency),
            notificationGroupingProvider.overrideWith((ref) => initialGrouping),
            delayNewMediaProvider.overrideWith((ref) => initialDelay),
            reminderLeadTimeProvider.overrideWith((ref) => initialReminderLeadTime),
          ],
          child: const MainApp(),
        ),
      ),
    );
    logger.info("App started successfully.");
  } catch (e, s) {
    final initLogger = logger ?? LoggerService();
    initLogger.fatal("--- FATAL ERROR during app initialization! ---", e, s);
    try {
      if (settingsService != null) {
        await settingsService.setMainServicesReady(false);
        initLogger.warning("Reset Main Services Readiness Flag to FALSE due to initialization error.");
      } else {
        initLogger.warning("Settings service not available to reset readiness flag during initialization error.");
      }
    } catch (cleanupError, cleanupStack) {
      initLogger.error("Failed during error handling cleanup.", cleanupError, cleanupStack);
    } finally {
      container.dispose();
      initLogger.warning("ProviderContainer disposed during error handling.");
    }
    runApp(ErrorApp(error: e, stackTrace: s));
  }
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light);
    final ColorScheme darkColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark);

    return MaterialApp(
      title: 'Holodex Notifier',
      theme: ThemeData(colorScheme: lightColorScheme, useMaterial3: true),
      darkTheme: ThemeData(colorScheme: darkColorScheme, useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final Object error;
  final StackTrace stackTrace;

  const ErrorApp({super.key, required this.error, required this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Initialization Error')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Text('Fatal error during app startup:\n\n$error\n\n$stackTrace', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ),
      ),
    );
  }
}
