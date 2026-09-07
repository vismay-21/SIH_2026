import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

/// Common Settings Screen shared between Customer and Worker (Common Screen #9 & #10)
/// Features centralized theme toggle, multilingual ChoiceChips, notifications,
/// and biometric privacy preferences.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.userRole = 'User'});

  final String userRole;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  String _selectedLanguage = 'English';
  bool _pushNotifications = true;
  bool _soundChimes = true;
  bool _smsUpdates = true;
  bool _biometricLock = false;
  bool _locationSharing = true;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'kn', 'name': 'Kannada', 'native': 'ಕನ್ನಡ'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिंदी'},
    {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்'},
    {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          // Section 1: Appearance
          const SectionTitle('Appearance & Theme'),
          const SizedBox(height: 8),
          SurfaceCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _darkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  color: AppColors.primary,
                ),
              ),
              title: const Text(
                'Dark Mode',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: Text(
                _darkMode
                    ? 'Dark contrast theme active'
                    : 'Light cooperative theme active',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              value: _darkMode,
              activeThumbColor: AppColors.primary,
              onChanged: (val) {
                setState(() => _darkMode = val);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      val ? 'Dark mode enabled.' : 'Light mode enabled.',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Section 2: Multilingual Selection (Embedded Language Module)
          const SectionTitle('App Language (ಭಾಷೆ / भाषा)'),
          const SizedBox(height: 8),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select your preferred cooperative language:',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _languages.map((lang) {
                    final isSelected = _selectedLanguage == lang['name'];
                    return ChoiceChip(
                      label: Text('${lang['native']} (${lang['name']})'),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.text,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedLanguage = lang['name']!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Language set to ${lang['name']}.'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 3: Notifications
          const SectionTitle('Notifications & Alerts'),
          const SizedBox(height: 8),
          SurfaceCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Push Notifications',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Real-time gig updates and matching notices',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  value: _pushNotifications,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _pushNotifications = val),
                ),
                const Divider(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.volume_up_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Sound & Vibration Chimes',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Audible chime when opportunities or messages arrive',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  value: _soundChimes,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _soundChimes = val),
                ),
                const Divider(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.sms_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'SMS & WhatsApp Alerts',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Backup dispatch SMS for urgent work schedules',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  value: _smsUpdates,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _smsUpdates = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 4: Security & Privacy
          const SectionTitle('Security & Permissions'),
          const SizedBox(height: 8),
          SurfaceCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.fingerprint_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Biometric App Lock',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Require Fingerprint or FaceID to open app',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  value: _biometricLock,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _biometricLock = val),
                ),
                const Divider(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Proximity Dispatch Location',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Share coarse location for local neighborhood matching',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  value: _locationSharing,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _locationSharing = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 5: Data & Privacy Policy
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.shield_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Cooperative Privacy Pledge',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sahakaar Seva is artisan-owned. Your location, phone number, and earnings data are never sold to advertisers or third-party lead generators.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
                const Divider(height: 20),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Local cache cleared.')),
                      );
                    },
                    icon: const Icon(
                      Icons.cleaning_services_outlined,
                      size: 16,
                    ),
                    label: const Text('Clear Temporary Cache (12.4 MB)'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
