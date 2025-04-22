// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:holodex_notifier/application/controllers/app_controller.dart';
// import 'package:holodex_notifier/application/state/settings_providers.dart';
// import 'package:holodex_notifier/domain/interfaces/api_service.dart';
// import 'package:holodex_notifier/domain/interfaces/background_polling_service.dart';
// import 'package:holodex_notifier/domain/interfaces/cache_service.dart';
// import 'package:holodex_notifier/domain/interfaces/connectivity_service.dart';
// import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
// import 'package:holodex_notifier/domain/interfaces/notification_action_handler.dart';
// import 'package:holodex_notifier/domain/interfaces/notification_decision_service.dart';
// import 'package:holodex_notifier/domain/interfaces/notification_service.dart';
// import 'package:holodex_notifier/domain/interfaces/secure_storage_service.dart';
// import 'package:holodex_notifier/domain/interfaces/settings_service.dart';
// import 'package:holodex_notifier/infrastructure/data/database.dart';
// import 'package:holodex_notifier/infrastructure/network/dio_client.dart';
// import 'package:holodex_notifier/infrastructure/services/background_poller_service.dart';
// import 'package:holodex_notifier/infrastructure/services/connectivity_plus_service.dart';
// import 'package:holodex_notifier/infrastructure/services/drift_cache_service.dart';
// import 'package:holodex_notifier/infrastructure/services/flutter_secure_storage_service.dart';
// import 'package:holodex_notifier/infrastructure/services/holodex_api_service.dart';
// import 'package:holodex_notifier/infrastructure/services/local_notification_service.dart';
// import 'package:holodex_notifier/infrastructure/services/logger_service.dart';
// import 'package:holodex_notifier/infrastructure/services/notification_action_handler.dart';
// import 'package:holodex_notifier/infrastructure/services/notification_decision_service.dart';
// import 'package:holodex_notifier/infrastructure/services/shared_prefs_settings_service.dart';
// import 'package:holodex_notifier/lib/main.dart';
// import 'package:mockito/mockito.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:dio/dio.dart';

// // Mock classes for testing
// class MockLoggingService extends Mock implements ILoggingService {}
// class MockSecureStorageService extends Mock implements ISecureStorageService {}
// class MockDatabase extends Mock implements AppDatabase {}
// class MockCacheService extends Mock implements ICacheService {}
// class MockConnectivityService extends Mock implements IConnectivityService {}
// class MockDioClient extends Mock implements DioClient {}
// class MockApiService extends Mock implements IApiService {}
// class MockSettingsService extends Mock implements ISettingsService {}
// class MockNotificationService extends Mock implements INotificationService {}
// class MockBackgroundPollingService extends Mock implements IBackgroundPollingService {}
// class MockNotificationDecisionService extends Mock implements INotificationDecisionService {}
// class MockNotificationActionHandler extends Mock implements INotificationActionHandler {}

// void main() {
//   late ProviderContainer container;
//   late MockLoggingService mockLogger;
//   late MockSecureStorageService mockSecureStorage;
//   late MockDatabase mockDatabase;
//   late MockCacheService mockCacheService;
//   late MockConnectivityService mockConnectivityService;
//   late MockDioClient mockDioClient;
//   late MockApiService mockApiService;
//   late MockSettingsService mockSettingsService;
//   late MockNotificationService mockNotificationService;
//   late MockBackgroundPollingService mockBackgroundService;
//   late MockNotificationDecisionService mockNotificationDecisionService;
//   late MockNotificationActionHandler mockNotificationActionHandler;

//   setUp(() {
//     mockLogger = MockLoggingService();
//     mockSecureStorage = MockSecureStorageService();
//     mockDatabase = MockDatabase();
//     mockCacheService = MockCacheService();
//     mockConnectivityService = MockConnectivityService();
//     mockDioClient = MockDioClient();
//     mockApiService = MockApiService();
//     mockSettingsService = MockSettingsService();
//     mockNotificationService = MockNotificationService();
//     mockBackgroundService = MockBackgroundPollingService();
//     mockNotificationDecisionService = MockNotificationDecisionService();
//     mockNotificationActionHandler = MockNotificationActionHandler();

//     container = ProviderContainer(
//       overrides: [
//         loggingServiceProvider.overrideWithValue(mockLogger),
//         secureStorageServiceProvider.overrideWithValue(mockSecureStorage),
//         databaseProvider.overrideWithValue(mockDatabase),
//         cacheServiceProvider.overrideWithValue(mockCacheService),
//         connectivityServiceProvider.overrideWithValue(mockConnectivityService),
//         dioProvider.overrideWithValue(mockDioClient.instance),
//         apiServiceProvider.overrideWithValue(mockApiService),
//         settingsServiceFutureProvider.overrideWithValue(Future.value(mockSettingsService)),
//         notificationServiceFutureProvider.overrideWithValue(Future.value(mockNotificationService)),
//         backgroundServiceFutureProvider.overrideWithValue(Future.value(mockBackgroundService)),
//         settingsServiceProvider.overrideWithValue(mockSettingsService),
//         notificationServiceProvider.overrideWithValue(mockNotificationService),
//         backgroundServiceProvider.overrideWithValue(mockBackgroundService),
//         notificationDecisionServiceProvider.overrideWithValue(mockNotificationDecisionService),
//         notificationActionHandlerProvider.overrideWithValue(mockNotificationActionHandler),
//         appControllerProvider.overrideWithValue(AppController(
//           container,
//           mockSettingsService,
//           mockLogger,
//           mockCacheService,
//           mockNotificationService,
//           mockNotificationDecisionService,
//           mockNotificationActionHandler,
//         )),
//       ],
//     );
//   });

//   tearDown(() {
//     container.dispose();
//   });

//   group('Provider Initialization Tests', () {
//     test('loggingServiceProvider should provide MockLoggingService', () {
//       final logger = container.read(loggingServiceProvider);
//       expect(logger, isA<MockLoggingService>());
//     });

//     test('secureStorageServiceProvider should provide MockSecureStorageService', () {
//       final secureStorage = container.read(secureStorageServiceProvider);
//       expect(secureStorage, isA<MockSecureStorageService>());
//     });

//     test('databaseProvider should provide MockDatabase', () {
//       final db = container.read(databaseProvider);
//       expect(db, isA<MockDatabase>());
//     });

//     test('cacheServiceProvider should provide MockCacheService', () {
//       final cache = container.read(cacheServiceProvider);
//       expect(cache, isA<MockCacheService>());
//     });

//     test('connectivityServiceProvider should provide MockConnectivityService', async {
//       final connectivity = await container.read(connectivityServiceProvider.future);
//       expect(connectivity, isA<MockConnectivityService>());
//     });

//     test('apiServiceProvider should provide MockApiService', async {
//       final apiService = await container.read(apiServiceProvider.future);
//       expect(apiService, isA<MockApiService>());
//     });

//     test('settingsServiceFutureProvider should provide MockSettingsService', async {
//       final settingsService = await container.read(settingsServiceFutureProvider.future);
//       expect(settingsService, isA<MockSettingsService>());
//     });

//     test('notificationServiceFutureProvider should provide MockNotificationService', async {
//       final notificationService = await container.read(notificationServiceFutureProvider.future);
//       expect(notificationService, isA<MockNotificationService>());
//     });

//     test('backgroundServiceFutureProvider should provide MockBackgroundPollingService', async {
//       final backgroundService = await container.read(backgroundServiceFutureProvider.future);
//       expect(backgroundService, isA<MockBackgroundPollingService>());
//     });

//     test('settingsServiceProvider should provide MockSettingsService', () {
//       final settingsService = container.read(settingsServiceProvider);
//       expect(settingsService, isA<MockSettingsService>());
//     });

//     test('notificationServiceProvider should provide MockNotificationService', () {
//       final notificationService = container.read(notificationServiceProvider);
//       expect(notificationService, isA<MockNotificationService>());
//     });

//     test('backgroundServiceProvider should provide MockBackgroundPollingService', () {
//       final backgroundService = container.read(backgroundServiceProvider);
//       expect(backgroundService, isA<MockBackgroundPollingService>());
//     });

//     test('notificationDecisionServiceProvider should provide MockNotificationDecisionService', () {
//       final decisionService = container.read(notificationDecisionServiceProvider);
//       expect(decisionService, isA<MockNotificationDecisionService>());
//     });

//     test('notificationActionHandlerProvider should provide MockNotificationActionHandler', () {
//       final actionHandler = container.read(notificationActionHandlerProvider);
//       expect(actionHandler, isA<MockNotificationActionHandler>());
//     });

//     test('appControllerProvider should provide AppController', () {
//       final appController = container.read(appControllerProvider);
//       expect(appController, isA<AppController>());
//     });
//   });

//   group('Main Function Tests', () {
//     testWidgets('main should initialize services correctly', (WidgetTester tester) async {
//       final mainLogger = MockLoggingService();
//       final mainSecureStorage = MockSecureStorageService();
//       final mainDatabase = MockDatabase();
//       final mainCacheService = MockCacheService();
//       final mainConnectivityService = MockConnectivityService();
//       final mainDioClient = MockDioClient();
//       final mainApiService = MockApiService();
//       final mainSettingsService = MockSettingsService();
//       final mainNotificationService = MockNotificationService();
//       final mainBackgroundService = MockBackgroundPollingService();
//       final mainNotificationDecisionService = MockNotificationDecisionService();
//       final mainNotificationActionHandler = MockNotificationActionHandler();
//       final mainAppController = AppController(
//         ProviderContainer(
//           overrides: [
//             loggingServiceProvider.overrideWithValue(mainLogger),
//             secureStorageServiceProvider.overrideWithValue(mainSecureStorage),
//             databaseProvider.overrideWithValue(mainDatabase),
//             cacheServiceProvider.overrideWithValue(mainCacheService),
//             connectivityServiceProvider.overrideWithValue(mainConnectivityService),
//             dioProvider.overrideWithValue(mainDioClient.instance),
//             apiServiceProvider.overrideWithValue(mainApiService),
//             settingsServiceFutureProvider.overrideWithValue(Future.value(mainSettingsService)),
//             notificationServiceFutureProvider.overrideWithValue(Future.value(mainNotificationService)),
//             backgroundServiceFutureProvider.overrideWithValue(Future.value(mainBackgroundService)),
//             settingsServiceProvider.overrideWithValue(mainSettingsService),
//             notificationServiceProvider.overrideWithValue(mainNotificationService),
//             backgroundServiceProvider.overrideWithValue(mainBackgroundService),
//             notificationDecisionServiceProvider.overrideWithValue(mainNotificationDecisionService),
//             notificationActionHandlerProvider.overrideWithValue(mainNotificationActionHandler),
//             appControllerProvider.overrideWithValue(mainAppController),
//           ],
//         ),
//         mainSettingsService,
//         mainLogger,
//         mainCacheService,
//         mainNotificationService,
//         mainNotificationDecisionService,
//         mainNotificationActionHandler,
//       );

//       // Mock necessary methods and properties
//       when(mainLogger.info(any)).thenReturn(null);
//       when(mainSecureStorage.setSystemInfoString(any)).thenReturn(null);
//       when(mainSettingsService.setMainServicesReady(any)).thenAnswer((_) async => true);
//       when(mainSettingsService.getPollFrequency()).thenAnswer((_) async => 0);
//       when(mainSettingsService.getNotificationGrouping()).thenAnswer((_) async => false);
//       when(mainSettingsService.getDelayNewMedia()).thenAnswer((_) async => 0);
//       when(mainSettingsService.getReminderLeadTime()).thenAnswer((_) async => 0);
//       when(mainBackgroundService.startPolling()).thenAnswer((_) async => true);

//       // Simulate main function
//       await main();

//       // Verify initializations
//       verify(mainLogger.info(any)).called(10); // Adjust based on the actual number of info calls
//       verify(mainSettingsService.setMainServicesReady(false)).called(1);
//       verify(mainSettingsService.setMainServicesReady(true)).called(1);
//       verify(mainBackgroundService.startPolling()).called(1);
//     });

//     testWidgets('main should handle initialization errors', (WidgetTester tester) async {
//       final mainLogger = MockLoggingService();
//       final mainSecureStorage = MockSecureStorageService();
//       final mainDatabase = MockDatabase();
//       final mainCacheService = MockCacheService();
//       final mainConnectivityService = MockConnectivityService();
//       final mainDioClient = MockDioClient();
//       final mainApiService = MockApiService();
//       final mainSettingsService = MockSettingsService();
//       final mainNotificationService = MockNotificationService();
//       final mainBackgroundService = MockBackgroundPollingService();
//       final mainNotificationDecisionService = MockNotificationDecisionService();
//       final mainNotificationActionHandler = MockNotificationActionHandler();
//       final mainAppController = AppController(
//         Ref<ProviderContainer(
//           overrides: [
//             loggingServiceProvider.overrideWithValue(mainLogger),
//             secureStorageServiceProvider.overrideWithValue(mainSecureStorage),
//             databaseProvider.overrideWithValue(mainDatabase),
//             cacheServiceProvider.overrideWithValue(mainCacheService),
//             connectivityServiceProvider.overrideWithValue(mainConnectivityService),
//             dioProvider.overrideWithValue(mainDioClient.instance),
//             apiServiceProvider.overrideWithValue(mainApiService),
//             settingsServiceFutureProvider.overrideWithValue(Future.value(mainSettingsService)),
//             notificationServiceFutureProvider.overrideWithValue(Future.value(mainNotificationService)),
//             backgroundServiceFutureProvider.overrideWithValue(Future.value(mainBackgroundService)),
//             settingsServiceProvider.overrideWithValue(mainSettingsService),
//             notificationServiceProvider.overrideWithValue(mainNotificationService),
//             backgroundServiceProvider.overrideWithValue(mainBackgroundService),
//             notificationDecisionServiceProvider.overrideWithValue(mainNotificationDecisionService),
//             notificationActionHandlerProvider.overrideWithValue(mainNotificationActionHandler),
//             appControllerProvider.overrideWithValue(mainAppController),
//           ]>(),
//         ),
//         mainSettingsService,
//         mainLogger,
//         mainCacheService,
//         mainNotificationService,
//         mainNotificationDecisionService,
//         mainNotificationActionHandler,
//       );

//       // Mock necessary methods and properties with errors
//       when(mainLogger.info(any)).thenReturn(null);
//       when(mainSecureStorage.setSystemInfoString(any)).thenReturn(null);
//       when(mainSettingsService.setMainServicesReady(any)).thenAnswer((_) async => true);
//       when(mainSettingsService.getPollFrequency()).thenAnswer((_) async => 0);
//       when(mainSettingsService.getNotificationGrouping()).thenAnswer((_) async => false);
//       when(mainSettingsService.getDelayNewMedia()).thenAnswer((_) async => 0);
//       when(mainSettingsService.getReminderLeadTime()).thenAnswer((_) async => 0);
//       when(mainBackgroundService.startPolling()).thenThrow(Exception('Test Exception'));

//       // Simulate main function
//       await main();

//       // Verify initializations and error handling
//       verify(mainLogger.info(any)).called(7); // Adjust based on the actual number of info calls
//       verify(mainSettingsService.setMainServicesReady(false)).called(1);
//       verifyNever(mainSettingsService.setMainServicesReady(true));
//       verifyNever(mainBackgroundService.startPolling());
//       verify(mainLogger.fatal(any, any, any)).called(1);
//       verify(mainLogger.warning(any, any)).called(2);
//     });
//   });
// }