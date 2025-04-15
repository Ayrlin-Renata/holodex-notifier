// f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\main.dart
import 'dart:async';
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

// --- Foundational Services ---

final loggingServiceProvider = Provider<ILoggingService>((ref) {
  return LoggerService();
});

final secureStorageServiceProvider = Provider<ISecureStorageService>((ref) {
  return FlutterSecureStorageService();
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(openConnection());
  final log = ref.watch(loggingServiceProvider);

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

// --- API & Background Services ---

final dioProvider = Provider<Dio>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  apiKeyGetter() async {
    return settingsService.getApiKey();
  }

  final dioClient = DioClient(apiKeyGetter: apiKeyGetter);
  return dioClient.instance;
});

final apiServiceProvider = Provider<IApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return HolodexApiService(dio);
});

// --- Async Initialization ---

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
  final settingsService = ref.watch(settingsServiceProvider); // Get settings service via sync provider

  final service = LocalNotificationService(log, settingsService);

  final isolateContext = ref.watch(isolateContextProvider);

  log.info("Resolving Notification Service Provider (Isolate Context: $isolateContext)");

  if (isolateContext == IsolateContext.main) {
    // Check the context
    // Only run full initialization in the main isolate
    log.info("Initializing Notification Service (Main Isolate)...");
    try {
      await service.initialize(); // Perform full initialization
      log.info("Notification Service initialized (Main Isolate).");
    } catch (e, s) {
      log.fatal("Failed Notification Service initialization in Main Isolate", e, s);
      rethrow;
    }
  } else {
    // context == IsolateContext.background
    // In background isolate, DO NOT call initialize().
    log.info("Skipping Notification Service initialization (Background Isolate). Assumes main isolate succeeded.");
  }

  return service; // Return the service instance
}, name: 'notificationServiceFutureProvider');

final backgroundServiceFutureProvider = FutureProvider<IBackgroundPollingService>((ref) async {
  final log = ref.watch(loggingServiceProvider);
  final service = BackgroundPollerService();
  log.info("Initializing Background Service...");
  await service.initialize();
  log.info("Background Service initialized (Setup).");
  return service;
}, name: 'backgroundServiceFutureProvider');

// --- Synchronous Access to Initialized Services ---

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
  // Depends on cache, settings, and logger
  final cacheService = ref.watch(cacheServiceProvider);
  final settingsService = ref.watch(settingsServiceProvider);
  final logger = ref.watch(loggingServiceProvider);
  return NotificationDecisionService(cacheService, settingsService, logger);
}, name: 'notificationDecisionServiceProvider');

final notificationActionHandlerProvider = Provider<INotificationActionHandler>((ref) {
  // Depends on notification service, cache, and logger
  final notificationService = ref.watch(notificationServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final logger = ref.watch(loggingServiceProvider);
  return NotificationActionHandler(notificationService, cacheService, logger);
}, name: 'notificationActionHandlerProvider');

// --- AppController ---
final appControllerProvider = Provider<AppController>((ref) {
  // Get all required services
  final settingsService = ref.watch(settingsServiceProvider);
  final loggingService = ref.watch(loggingServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider); // Get Cache Service
  final notificationService = ref.watch(notificationServiceProvider); // Get Notification Service
  final decisionService = ref.watch(notificationDecisionServiceProvider);
  final actionHandler = ref.watch(notificationActionHandlerProvider);

  // Pass them to the constructor
  return AppController(ref, settingsService, loggingService, cacheService, notificationService, decisionService, actionHandler);
}, name: 'appControllerProvider');

// --- Main Function ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  ILoggingService? logger;
  ISettingsService? settingsService;
  // ignore: unused_local_variable
  INotificationService? notificationService;

  try {
    // Initialize Logger first
    logger = container.read(loggingServiceProvider)!; // Use read directly, assume non-null after this line
    logger.info("Logger initialized.");

    // --- Step 1: Initialize Settings Service ---
    logger.info("Waiting for Settings Service FutureProvider...");
    settingsService = await container.read(settingsServiceFutureProvider.future);
    logger.info("Settings Service resolved.");

    // --- Step 2: Reset Readiness Flag ---
    // Null Assertion OK: settingsService is guaranteed non-null here
    await settingsService!.setMainServicesReady(false);
    logger.info("Main Services Readiness Flag RESET to FALSE.");

    // --- Step 3: Wait for OTHER critical async services ---
    logger.info("Waiting for Notification Service FutureProvider...");
    // Ensure notification service is initialized before readiness flag is set
    notificationService = await container.read(notificationServiceFutureProvider.future);
    logger.info("Notification Service resolved.");

    logger.info("Waiting for Background Service FutureProvider...");
    // Get the instance after awaiting
    final backgroundService = await container.read(backgroundServiceFutureProvider.future);
    logger.info("Background Service resolved.");

    logger.info("All core async services initialized.");

    try {
      logger.info("Starting background polling service...");
      await backgroundService.startPolling(); // Call startPolling here
      logger.info("Background polling service start initiated.");
    } catch (e, s) {
      logger.error("Error starting background polling service", e, s);
      // Decide if this is fatal or app can continue
    }

    // --- Step 4: Set Readiness Flag to TRUE ---
    // Null Assertion OK: settingsService is guaranteed non-null here
    await settingsService.setMainServicesReady(true);
    logger.info("Main Services Readiness Flag SET to TRUE.");

    // --- Step 6: Load Initial UI State ---
    logger.info("Loading initial state values for UI overrides...");
    // Null Assertion OK: settingsService is guaranteed non-null here
    final initialPollFrequency = await settingsService.getPollFrequency();
    final initialGrouping = await settingsService.getNotificationGrouping();
    final initialDelay = await settingsService.getDelayNewMedia();
    final initialReminderLeadTime = await settingsService.getReminderLeadTime(); // {{ Load reminder lead time }}

    logger.info("Initial state values loaded.");

    // --- Step 7: Run the App ---
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
    // --- Fatal Error Handling ---
    final initLogger = logger ?? LoggerService(); // Use existing or fallback
    initLogger.fatal("--- FATAL ERROR during app initialization! ---", e, s);
    try {
      // Use Null check for settingsService
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
    // Show minimal error UI
    runApp(ErrorApp(error: e, stackTrace: s));
  } // End try/catch
} // End main

// --- Main App Widget ---
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

// --- Error Display App ---
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
