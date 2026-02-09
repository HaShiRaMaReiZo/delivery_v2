import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/language_preference.dart';

class SettingsScreen extends StatefulWidget {
  final Future<void> Function(String)? onLanguageChanged;

  const SettingsScreen({super.key, this.onLanguageChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _currentLanguage;

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final languageCode = await LanguagePreference.getLanguage();
    setState(() {
      _currentLanguage = languageCode ?? 'system';
    });
  }

  Future<void> _changeLanguage(String languageCode) async {
    setState(() {
      _currentLanguage = languageCode;
    });

    // Call the callback to update language in MyApp
    if (widget.onLanguageChanged != null) {
      await widget.onLanguageChanged!(languageCode);
    } else {
      // Fallback: save to preferences directly
      if (languageCode == 'system') {
        await LanguagePreference.clearLanguage();
      } else {
        await LanguagePreference.setLanguage(languageCode);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.languageChanged),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.lightBeige,
      appBar: AppBar(
        toolbarHeight: 48,
        title: Text(l10n.settings),
        automaticallyImplyLeading: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Language Section
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.language,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.black,
                  ),
                ),
                const SizedBox(height: 16),
                _buildLanguageOption(
                  context,
                  title: l10n.systemDefault,
                  value: 'system',
                  icon: Icons.language,
                ),
                const Divider(height: 32),
                _buildLanguageOption(
                  context,
                  title: 'English',
                  value: 'en',
                  icon: Icons.translate,
                ),
                const Divider(height: 32),
                _buildLanguageOption(
                  context,
                  title: 'မြန်မာ',
                  value: 'my',
                  icon: Icons.translate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _currentLanguage == value;

    return InkWell(
      onTap: () => _changeLanguage(value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppTheme.primaryBlue, size: 24)
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Colors.grey[400],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
