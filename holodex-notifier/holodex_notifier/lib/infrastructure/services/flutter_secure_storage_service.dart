import 'package:holodex_notifier/domain/interfaces/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import flutter_secure_storage

class FlutterSecureStorageService implements ISecureStorageService {
  // Hold FlutterSecureStorage instance with platform options if needed
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    // Optional: Specify Android options like encrypted shared preferences
     aOptions: AndroidOptions(
       encryptedSharedPreferences: true,
     ),
    // Optional: Specify iOS options like keychain accessibility
    // iOptions: IOSOptions(
    //  accessibility: KeychainAccessibility.first_unlock,
    // ),
  );

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      // Log error appropriately - maybe use the LoggerService if injectable
      print("SecureStorage Read Error for key '$key': $e");
      return null;
    }
  }

  @override
  Future<void> write(String key, String? value) async {
    try {
      if (value == null) {
        // If value is null, delete the key instead of storing null
        await delete(key);
      } else {
        await _storage.write(key: key, value: value);
      }
    } catch (e) {
      print("SecureStorage Write Error for key '$key': $e");
      // Rethrow or handle as appropriate
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