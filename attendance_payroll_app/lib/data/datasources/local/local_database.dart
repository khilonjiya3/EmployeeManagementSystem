import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  throw UnimplementedError('Override in main.dart');
});

class LocalDatabase {
  static const String _attendanceKey = 'offline_attendance';
  static const String _expensesKey = 'offline_expenses';

  Future<void> init() async {}

  Future<void> saveOfflineAttendance(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_attendanceKey) ?? [];
    existing.add(json.encode(data));
    await prefs.setStringList(_attendanceKey, existing);
  }

  Future<List<Map<String, dynamic>>> getOfflineAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_attendanceKey) ?? [];
    return list.map((s) => json.decode(s) as Map<String, dynamic>).toList();
  }

  Future<void> clearOfflineAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attendanceKey);
  }

  Future<void> saveOfflineExpense(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_expensesKey) ?? [];
    existing.add(json.encode(data));
    await prefs.setStringList(_expensesKey, existing);
  }

  Future<List<Map<String, dynamic>>> getOfflineExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_expensesKey) ?? [];
    return list.map((s) => json.decode(s) as Map<String, dynamic>).toList();
  }

  Future<void> clearOfflineExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_expensesKey);
  }

  Future<int> getPendingCount() async {
    final att = await getOfflineAttendance();
    final exp = await getOfflineExpenses();
    return att.length + exp.length;
  }
}
