import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/directus_service.dart';
import '../../data/services/widget_service.dart';

class AuthProvider extends ChangeNotifier {
  final DirectusService _directusService;
  String? _currentUserId;
  bool _isLoading = true;

  AuthProvider(this._directusService) {
    _loadUser();
  }

  String? get currentUserId => _currentUserId;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUserId != null;

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('current_user_id');
    if (_currentUserId != null) {
      _directusService.setUserId(_currentUserId!);
      // Sync user ID to iOS widget
      WidgetService.syncUserId(_currentUserId!);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String userId) async {
    // Basic validation: user ID must not be empty
    if (userId.isEmpty) {
      throw Exception('User ID must not be empty');
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Ensure user exists in Directus (create if not)
      await _directusService.ensureUserExists(userId);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', userId);
      _currentUserId = userId;
      _directusService.setUserId(userId);
      // Sync user ID to iOS widget
      WidgetService.syncUserId(userId);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    _currentUserId = null;
    await WidgetService.clearWidgetConfig();

    _isLoading = false;
    notifyListeners();
  }
}
