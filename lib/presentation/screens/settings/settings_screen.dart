import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../core/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _buddyPrefixController = TextEditingController();
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  @override
  void dispose() {
    _buddyPrefixController.dispose();
    super.dispose();
  }

  void _loadUserSettings() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // if (authProvider.currentUser != null && authProvider.currentUser!.buddyPrefix != null) {
    //   _buddyPrefixController.text = authProvider.currentUser!.buddyPrefix!;
    // }

    // In a real app, you'd load dark mode setting from local storage
    setState(() {
      _isDarkMode = false; // Default value
    });
  }

  void _updateBuddyPrefix() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    //await authProvider.updateBuddyPrefix(_buddyPrefixController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('設定を保存しました')),
      );
    }
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });

    // In a real app, you'd save this setting to local storage
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '設定',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Buddyの名前を付ける'),
            const SizedBox(height: 8),
            TextField(
              controller: _buddyPrefixController,
              decoration: AppTheme.textFieldDecoration('Buddyの基本名を設定する'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ダークモード'),
                Switch(
                  value: _isDarkMode,
                  onChanged: _toggleDarkMode,
                  activeColor: AppTheme.primaryGreen,
                ),
              ],
            ),
            const Spacer(),
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _updateBuddyPrefix,
                    style: AppTheme.primaryButtonStyle,
                    child: const Text('保存'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      await authProvider.signOut();
                      if (mounted) {
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    },
                    child: const Text('ログアウト'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}