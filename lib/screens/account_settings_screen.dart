import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/custom_button.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _dailyReminders = false;
  
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Change Password", style: AppTypography.subheading),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Current Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            onPressed: () async {
              if (_newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("New password must be at least 6 characters.")),
                );
                return;
              }
              if (_oldPasswordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter your current password.")),
                );
                return;
              }
              Navigator.pop(context); // Close dialog
              
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final success = await authProvider.changePassword(
                _oldPasswordController.text,
                _newPasswordController.text,
              );
              
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password changed successfully!")),
                  );
                  _oldPasswordController.clear();
                  _newPasswordController.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(authProvider.errorMessage ?? "Failed to change password.")),
                  );
                }
              }
            },
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Account Settings', style: AppTypography.screenHeading),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Security", style: AppTypography.subheading),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.lock_outline, color: AppColors.primaryBlue),
                      title: Text("Change Password", style: AppTypography.bodyText),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      onTap: _showPasswordDialog,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text("Preferences", style: AppTypography.subheading),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          activeColor: AppColors.primaryBlue,
                          title: Text("Push Notifications", style: AppTypography.bodyText),
                          value: _notificationsEnabled,
                          onChanged: (val) => setState(() => _notificationsEnabled = val),
                          secondary: const Icon(Icons.notifications_none, color: AppColors.primaryBlue),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          activeColor: AppColors.primaryBlue,
                          title: Text("Daily Practice Reminders", style: AppTypography.bodyText),
                          value: _dailyReminders,
                          onChanged: (val) => setState(() => _dailyReminders = val),
                          secondary: const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  Text("Danger Zone", style: AppTypography.subheading.copyWith(color: Colors.red)),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withAlpha(50)),
                    ),
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Account deletion must be processed by an administrator.')),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "Delete Account",
                          style: AppTypography.bodyText.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
