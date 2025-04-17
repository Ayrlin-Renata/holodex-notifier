import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/interfaces/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FlutterSecureStorageService implements ISecureStorageService {
  final ILoggingService _logger;
  final FlutterSecureStorage _storage = const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

  FlutterSecureStorageService(this._logger);

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e, s) {
      _logger.error("SecureStorage Read Error for key '$key'", e, s);
      return null;
    }
  }

  @override
  Future<void> write(String key, String? value) async {
    try {
      if (value == null) {
        _logger.debug("SecureStorage: Value for key '$key' is null, deleting instead of writing.");
        await delete(key);
      } else {
        await _storage.write(key: key, value: value);
      }
    } catch (e, s) {
      _logger.error("SecureStorage Write Error for key '$key'", e, s);
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e, s) {
      _logger.error("SecureStorage Delete Error for key '$key'", e, s);
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      _logger.info("SecureStorage: Deleted all keys.");
    } catch (e, s) {
      _logger.error("SecureStorage Delete All Error", e, s);
    }
  }
}