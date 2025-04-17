import 'package:holodex_notifier/domain/interfaces/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FlutterSecureStorageService implements ISecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      print("SecureStorage Read Error for key '$key': $e");
      return null;
    }
  }

  @override
  Future<void> write(String key, String? value) async {
    try {
      if (value == null) {
        await delete(key);
      } else {
        await _storage.write(key: key, value: value);
      }
    } catch (e) {
      print("SecureStorage Write Error for key '$key': $e");
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      print("SecureStorage Delete Error for key '$key': $e");
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      print("SecureStorage Delete All Error: $e");
    }
  }
}
