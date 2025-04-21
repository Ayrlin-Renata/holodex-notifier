import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holodex_notifier/main.dart';
import 'package:holodex_notifier/application/state/channel_providers.dart';
import 'package:holodex_notifier/application/state/settings_providers.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/interfaces/settings_service.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import the generated mock file
import 'channel_providers_test.mocks.dart';

// Annotation to generate mocks for these interfaces
@GenerateMocks([ISettingsService, ILoggingService])
void main() {
  // Create instances of the mocks
  late MockISettingsService mockSettingsService;
  late MockILoggingService mockLogger;
  late ProviderContainer container;
  late ChannelListNotifier notifier;

  // Sample data
  const channel1 = ChannelSubscriptionSetting(channelId: 'UC1', name: 'Channel 1');
  const channel2 = ChannelSubscriptionSetting(channelId: 'UC2', name: 'Channel 2');
  const channel3 = ChannelSubscriptionSetting(channelId: 'UC3', name: 'Channel 3');

  setUp(() {
    // Create fresh mocks for each test
    mockSettingsService = MockISettingsService();
    mockLogger = MockILoggingService();

    // Provide default return values for common mock calls to avoid boilerplate
    // Use `any` for arguments we don't care about in the specific test setup
    when(mockSettingsService.getChannelSubscriptions())
        .thenAnswer((_) async => []); // Default to returning empty list initially
    when(mockSettingsService.saveChannelSubscriptions(any))
        .thenAnswer((_) async {}); // Default to successful save
    // Mock logger methods to prevent null pointer exceptions if they are called
    when(mockLogger.info(any)).thenReturn(null);
    when(mockLogger.debug(any)).thenReturn(null);
    when(mockLogger.warning(any)).thenReturn(null);
    when(mockLogger.error(any, any, any)).thenReturn(null);


    // Create a ProviderContainer, overriding providers with mocks
    container = ProviderContainer(
      overrides: [
        // Override the actual services with our mocks
        settingsServiceProvider.overrideWithValue(mockSettingsService),
        loggingServiceProvider.overrideWithValue(mockLogger),
        // Override global defaults (can use actual providers or mock if needed)
        globalNewMediaDefaultProvider.overrideWith((ref) => true),
        globalMentionsDefaultProvider.overrideWith((ref) => true),
        globalLiveDefaultProvider.overrideWith((ref) => true),
        globalUpdateDefaultProvider.overrideWith((ref) => true),
        globalMembersOnlyDefaultProvider.overrideWith((ref) => false),
        globalClipsDefaultProvider.overrideWith((ref) => false),
      ],
    );

    // Instantiate the Notifier using the container to get mocked dependencies
    // We read the '.notifier' directly AFTER the container setup
    notifier = container.read(channelListProvider.notifier);
  });

  tearDown(() {
    // Dispose the container after each test
    container.dispose();
  });

  test('Initial state should be empty or load from settings', () async {
    // Arrange: Setup mock to return specific data for this test
    when(mockSettingsService.getChannelSubscriptions())
        .thenAnswer((_) async => [channel1, channel2]);

    // Act: Trigger the load (it's called in the constructor/init)
    await notifier.loadInitialState(); // Manually call load for test verification

    // Assert
    expect(notifier.state, [channel1, channel2]);
    verify(mockSettingsService.getChannelSubscriptions()).called(1);
    verify(mockLogger.info(any)).called(greaterThan(0)); // Verify logging happened
  });

  test('addChannel should add a new channel and save state', () async {
    // Arrange (Initial state is empty as per default mock setup)

    // Act
    notifier.addChannel(channel3);
    await untilCalled(mockSettingsService.saveChannelSubscriptions(any)); // Wait for async save

    // Assert
    expect(notifier.state, contains(channel3));
    expect(notifier.state, hasLength(1));
    // Verify that save was called with the correct state
    verify(mockSettingsService.saveChannelSubscriptions([channel3])).called(1);
     verify(mockLogger.debug('ChannelListNotifier: Adding channel ${channel3.channelId}')).called(1);
  });

   test('addChannel should not add a duplicate channel', () async {
    // Arrange: Start with channel1 already loaded
        when(mockSettingsService.getChannelSubscriptions())
        .thenAnswer((_) async => [channel1]);
    await notifier.loadInitialState();


    // Act
    notifier.addChannel(channel1); // Try adding the same channel

    // Assert
    expect(notifier.state, hasLength(1)); // Length should not change
    expect(notifier.state, [channel1]);
    // Verify that save was *not* called because no change happened
    verifyNever(mockSettingsService.saveChannelSubscriptions(any));
    verify(mockLogger.warning("ChannelListNotifier: Channel ${channel1.channelId} already exists, cannot add.")).called(1);
  });


  test('removeChannel should remove the channel and save state', () async {
    // Arrange: Start with two channels loaded
    when(mockSettingsService.getChannelSubscriptions())
        .thenAnswer((_) async => [channel1, channel2]);
    await notifier.loadInitialState(); // Load initial state

    // Act
    notifier.removeChannel(channel1.channelId);
    await untilCalled(mockSettingsService.saveChannelSubscriptions(any)); // Wait for async save

    // Assert
    expect(notifier.state, isNot(contains(channel1)));
    expect(notifier.state, contains(channel2));
    expect(notifier.state, hasLength(1));
    // Verify save was called with the state *after* removal
    verify(mockSettingsService.saveChannelSubscriptions([channel2])).called(1);
     verify(mockLogger.debug('ChannelListNotifier: Removing channel ${channel1.channelId}')).called(1);
  });

 test('updateChannelSettings should update specific settings and save state', () async {
    // Arrange: Start with channel1
    when(mockSettingsService.getChannelSubscriptions())
        .thenAnswer((_) async => [channel1]);
    await notifier.loadInitialState(); // Load initial state

    // Act
    notifier.updateChannelSettings(channel1.channelId, live: false, membersOnly: true);
     await untilCalled(mockSettingsService.saveChannelSubscriptions(any)); // Wait for async save

    // Assert
    final updatedChannel = notifier.state.firstWhere((c) => c.channelId == channel1.channelId);
    expect(updatedChannel.notifyLive, isFalse);
    expect(updatedChannel.notifyMembersOnly, isTrue);
    expect(updatedChannel.notifyNewMedia, isTrue); // Should remain default

    // Verify save was called with the updated state
    final expectedSavedState = [channel1.copyWith(notifyLive: false, notifyMembersOnly: true)];
    verify(mockSettingsService.saveChannelSubscriptions(expectedSavedState)).called(1);
  });

  test('applyGlobalSwitches should update all channels based on global providers', () async {
     // Arrange: Start with two channels with non-default settings
     final chan1NonDefault = channel1.copyWith(notifyLive: false, notifyMembersOnly: true);
     final chan2NonDefault = channel2.copyWith(notifyNewMedia: false, notifyClips: true);
     when(mockSettingsService.getChannelSubscriptions())
        .thenAnswer((_) async => [chan1NonDefault, chan2NonDefault]);
     await notifier.loadInitialState();

     // Global defaults are set in setUp: new=true, mention=true, live=true, update=true, members=false, clips=false

     // Act
     notifier.applyGlobalSwitches();
     await untilCalled(mockSettingsService.saveChannelSubscriptions(any)); // Wait for async save

     // Assert
     final expectedStateAfterApply = [
       chan1NonDefault.copyWith(notifyNewMedia: true, notifyMentions: true, notifyLive: true, notifyUpdates: true, notifyMembersOnly: false, notifyClips: false),
       chan2NonDefault.copyWith(notifyNewMedia: true, notifyMentions: true, notifyLive: true, notifyUpdates: true, notifyMembersOnly: false, notifyClips: false),
     ];
     expect(notifier.state, expectedStateAfterApply);
     verify(mockSettingsService.saveChannelSubscriptions(expectedStateAfterApply)).called(1);
   });

   test('reorderChannels should reorder the list and save state', () async {
    // Arrange: Start with three channels
     when(mockSettingsService.getChannelSubscriptions())
        .thenAnswer((_) async => [channel1, channel2, channel3]);
     await notifier.loadInitialState(); // Load initial state

    // Act: Move channel1 (index 0) to index 2
    notifier.reorderChannels(0, 2);
    await untilCalled(mockSettingsService.saveChannelSubscriptions(any)); // Wait for async save

    // Assert
    expect(notifier.state, [channel2, channel1, channel3]); // Order should be 2, 1, 3
    verify(mockSettingsService.saveChannelSubscriptions([channel2, channel1, channel3])).called(1);

     // Act: Move channel3 (now index 2) to index 0
     notifier.reorderChannels(2, 0);
     await untilCalled(mockSettingsService.saveChannelSubscriptions(any)); // Wait for async save

     // Assert
     expect(notifier.state, [channel3, channel2, channel1]); // Order should be 3, 2, 1
     verify(mockSettingsService.saveChannelSubscriptions([channel3, channel2, channel1])).called(1);
   });

}