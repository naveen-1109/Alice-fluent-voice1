import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/custom_button.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'account_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final patientProvider = Provider.of<PatientProvider>(context);
    final user = authProvider.appUser;
    final bool isPatient = user?.role != 'therapist';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text('Profile', style: AppTypography.screenHeading),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue10,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryBlue30, width: 2),
                    ),
                    child: ClipOval(
                      child: user?.profileImage != null && user!.profileImage!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: user.profileImage!,
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(color: AppColors.primaryBlue),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.person,
                                size: 50,
                                color: AppColors.primaryBlue,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.primaryBlue,
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Name
                  Text(
                    user?.fullName ?? 'Unknown User',
                    style: AppTypography.displayLarge,
                  ),
                  const SizedBox(height: 8),
                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: user?.role == 'therapist' ? AppColors.warningOrange10 : AppColors.successGreenLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (user?.role ?? 'Patient').toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: user?.role == 'therapist' ? AppColors.warningOrange : AppColors.successGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  if (isPatient) ...[
                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: "Total Sessions",
                            value: "${patientProvider.totalSessions}",
                            icon: Icons.history,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            label: "Avg Fluency",
                            value: "${patientProvider.avgFluency.toInt()}%",
                            icon: Icons.trending_up,
                            color: AppColors.successGreen,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: _StatCard(
                            label: "Day Streak",
                            value: "3", // Hardcoded placeholder for now
                            icon: Icons.local_fire_department,
                            color: AppColors.warningOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.black05,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(Icons.email_outlined, 'Email', user?.email ?? 'N/A'),
                        const Divider(height: 32),
                        _buildDetailRow(Icons.phone_outlined, 'Phone', user?.phone ?? 'Not provided'),
                        const Divider(height: 32),
                        _buildDetailRow(Icons.calendar_today_outlined, 'Joined', _formatDate(user?.createdAt)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Edit Profile
                  CustomButton(
                    text: 'Edit Profile',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Account Settings
                  CustomButton(
                    text: 'Account Settings',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AccountSettingsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Logout Button
                  CustomButton(
                    text: 'Log Out',
                    onPressed: () async {
                      await authProvider.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 100), // padding for bottom nav
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.caption),
            const SizedBox(height: 4),
            Text(value, style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Unknown";
    return "${date.month}/${date.day}/${date.year}";
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: const [BoxShadow(color: AppColors.black05, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.subheading.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
