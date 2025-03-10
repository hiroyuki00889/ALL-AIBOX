import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Check if user is already logged in after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.isAuthenticated) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'YOURBUDDY',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: AppTheme.primaryButtonStyle,
              onPressed: null, // Disabled during splash
              child: const Text('ログイン'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: AppTheme.secondaryButtonStyle,
              onPressed: null, // Disabled during splash
              child: const Text('新規登録'),
            ),
            const Spacer(),
            const SizedBox(
              width: double.infinity,
              height: 50,
              child: Align(
                alignment: Alignment.center,
                child: Text('広告'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
