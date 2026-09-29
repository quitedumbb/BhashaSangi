import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class TeacherProfile {
  final String id;
  final String fullName;
  final String emailOrUsername;
  final String schoolName;
  final String district;
  final String state;
  final String primaryGrade;

  const TeacherProfile({
    required this.id,
    required this.fullName,
    required this.emailOrUsername,
    required this.schoolName,
    required this.district,
    required this.state,
    required this.primaryGrade,
  });

  factory TeacherProfile.fromJson(Map<String, dynamic> json) {
    return TeacherProfile(
      id: json['id']?.toString() ?? 'tch-01',
      fullName: json['full_name'] ?? json['fullName'] ?? 'Classroom Teacher',
      emailOrUsername: json['email'] ?? json['username'] ?? json['emailOrUsername'] ?? 'teacher@primary.edu.in',
      schoolName: json['school_name'] ?? json['schoolName'] ?? 'Govt. Primary School',
      district: json['district'] ?? 'Dumka',
      state: json['state'] ?? 'Jharkhand',
      primaryGrade: json['primary_grade'] ?? json['primaryGrade'] ?? 'Classes 1 - 8',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': emailOrUsername,
      'school_name': schoolName,
      'district': district,
      'state': state,
      'primary_grade': primaryGrade,
    };
  }

  static const TeacherProfile demoTeacher = TeacherProfile(
    id: 'tch-01',
    fullName: 'Sunita Soren',
    emailOrUsername: 'sunita.soren@primary.edu.in',
    schoolName: 'Govt. Primary School, Dumka',
    district: 'Dumka',
    state: 'Jharkhand',
    primaryGrade: 'Classes 1 - 8 (Primary & Upper Primary)',
  );
}

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._();
  AuthService._();

  TeacherProfile? _currentTeacher = TeacherProfile.demoTeacher;
  bool _isAuthenticated = true;
  String? _authToken;

  bool get isAuthenticated => _isAuthenticated;
  TeacherProfile? get currentTeacher => _currentTeacher;
  String? get authToken => _authToken;

  /// Authenticates teacher via FastAPI backend, syncing with MySQL and local SQLite.
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse(ApiConfig.loginEndpoint);

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'password': password.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data['teacher'] != null) {
          _currentTeacher = TeacherProfile.fromJson(data['teacher'] as Map<String, dynamic>);
        }
        _authToken = data['token']?.toString();
        _isAuthenticated = true;
        notifyListeners();
        return {
          'success': true,
          'message': data['message'] ?? 'Logged in successfully',
          'teacher': _currentTeacher,
        };
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Invalid username or password',
        };
      }
    } catch (e) {
      // Local demo fallback if backend is offline
      if (username.toLowerCase() == 'sunita' || password == 'password123' || username.isNotEmpty) {
        _isAuthenticated = true;
        _currentTeacher = TeacherProfile(
          id: 'tch-offline',
          fullName: username.isEmpty ? 'Sunita Soren' : username,
          emailOrUsername: username.contains('@') ? username : '$username@primary.edu.in',
          schoolName: 'Govt. Primary School, Dumka',
          district: 'Dumka',
          state: 'Jharkhand',
          primaryGrade: 'Classes 1 - 8',
        );
        notifyListeners();
        return {
          'success': true,
          'message': 'Logged in via local offline profile (Server unreachable)',
          'teacher': _currentTeacher,
        };
      }

      return {
        'success': false,
        'message': 'Server unreachable. Could not log in: $e',
      };
    }
  }

  /// Registers a new teacher in FastAPI backend (saved in MySQL + local SQLite).
  Future<Map<String, dynamic>> register({
    required String username,
    required String fullName,
    required String password,
    String? email,
    String? schoolName,
    String? district,
    String? state,
    String? primaryGrade,
  }) async {
    final uri = Uri.parse(ApiConfig.registerEndpoint);

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'full_name': fullName.trim(),
          'email': (email != null && email.isNotEmpty) ? email.trim() : '${username.trim()}@primary.edu.in',
          'password': password.trim(),
          'school_name': (schoolName != null && schoolName.isNotEmpty) ? schoolName.trim() : 'Govt. Primary School',
          'district': (district != null && district.isNotEmpty) ? district.trim() : 'Dumka',
          'state': (state != null && state.isNotEmpty) ? state.trim() : 'Jharkhand',
          'primary_grade': (primaryGrade != null && primaryGrade.isNotEmpty) ? primaryGrade.trim() : 'Classes 1 - 8',
        }),
      ).timeout(const Duration(seconds: 12));

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data['teacher'] != null) {
          _currentTeacher = TeacherProfile.fromJson(data['teacher'] as Map<String, dynamic>);
        }
        _authToken = data['token']?.toString();
        _isAuthenticated = true;
        notifyListeners();
        return {
          'success': true,
          'message': data['message'] ?? 'Teacher registered successfully',
          'teacher': _currentTeacher,
        };
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      // Offline fallback registration
      _isAuthenticated = true;
      _currentTeacher = TeacherProfile(
        id: 'tch-local',
        fullName: fullName.isEmpty ? username : fullName,
        emailOrUsername: email ?? '$username@primary.edu.in',
        schoolName: schoolName ?? 'Govt. Primary School',
        district: district ?? 'Dumka',
        state: state ?? 'Jharkhand',
        primaryGrade: primaryGrade ?? 'Classes 1 - 8',
      );
      notifyListeners();
      return {
        'success': true,
        'message': 'Registered locally (Offline mode)',
        'teacher': _currentTeacher,
      };
    }
  }

  void logout() {
    _isAuthenticated = false;
    _currentTeacher = null;
    _authToken = null;
    notifyListeners();
  }
}
