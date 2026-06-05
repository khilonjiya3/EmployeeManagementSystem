import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final stopwatch = Stopwatch()..start();

      // Supabase connectivity check
      await Supabase.instance.client
          .from('app_health')
          .select()
          .limit(1);

      // Ensure splash shows at least 1 second
      final elapsed = stopwatch.elapsedMilliseconds;

      if (elapsed < 1000) {
        await Future.delayed(
          Duration(milliseconds: 1000 - elapsed),
        );
      }

      if (!mounted) return;

      final session =
          Supabase.instance.client.auth.currentSession;

      if (session == null) {
        context.go('/login');
      } else {
        context.go('/dashboard');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _retry() async {
    await _initialize();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const FlutterLogo(size: 90),
              const SizedBox(height: 24),
              Text(
                'AttendPay',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 80,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Unable to connect',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _error ??
                      'Please check your internet connection and try again.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
