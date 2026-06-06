class AppConstants {
  AppConstants._();

  static const String supabaseUrl = 'https://0ec90b57d6e95fcbda19832f.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJib2x0IiwicmVmIjoiMGVjOTBiNTdkNmU5NWZjYmRhMTk4MzJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4ODE1NzQsImV4cCI6MTc1ODg4MTU3NH0.9I8-U0x86Ak8t2DGaIk0HfvTSLsAyzdnz-Nw00mMkKw';

  // Storage buckets
  static const String bucketEmployeePhotos = 'employee_photos';
  static const String bucketSupervisorPhotos = 'supervisor_photos';
  static const String bucketExpenseReceipts = 'expense_receipts';
  static const String bucketDocuments = 'documents';

  // Pagination
  static const int pageSize = 20;

  // Cache
  static const Duration cacheExpiry = Duration(minutes: 15);

  // Attendance
  static const double halfDayMultiplier = 0.5;
  static const double overtimeDefaultRate = 1.5;

  // Expense categories
  static const List<String> expenseCategories = [
    'travel', 'fuel', 'food', 'material', 'labour', 'miscellaneous'
  ];

  // Date formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String monthYearFormat = 'MMMM yyyy';
  static const String apiDateFormat = 'yyyy-MM-dd';
}
