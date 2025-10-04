import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageNotifier extends ChangeNotifier {
  bool _useCloudStorage;

  StorageNotifier(this._useCloudStorage);

  bool get useCloudStorage => _useCloudStorage;

  Future<void> loadStoragePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _useCloudStorage = prefs.getBool('useCloudStorage') ?? false; // Default to local storage
    notifyListeners();
  }

  void setStoragePreference(bool value) {
    if (_useCloudStorage != value) {
      _useCloudStorage = value;
      _saveStoragePreference(value);
      notifyListeners();
    }
  }

  Future<void> _saveStoragePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useCloudStorage', value);
  }
}
