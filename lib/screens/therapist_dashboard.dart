import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/therapist_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'profile_screen.dart';

class TherapistDashboard extends StatefulWidget {
  const TherapistDashboard({super.key});

  @override
  State<TherapistDashboard> createState() => _TherapistDashboardState();
}

class _TherapistDashboardState extends State<TherapistDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        Provider.of<TherapistProvider>(context, listen: false)
            .fetchPatients(authProvider.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final therapistProvider = Provider.of<TherapistProvider>(context);
    final user = authProvider.appUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'FluentVoice',
                        style: AppTypography.screenHeading.copyWith(color: AppColors.primaryBlue),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileScreen()),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Greeting
                  Text(
                    'Dr. ${user?.fullName.split(' ').first ?? 'Therapist'} Dashboard',
                    style: AppTypography.subheading,
                  ),
                  const SizedBox(height: 24),
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search patients...',
                              hintStyle: AppTypography.bodyText.copyWith(color: AppColors.textSecondary),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Recent Patients',
                    style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Patient List
                  if (therapistProvider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (therapistProvider.patients.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          "No patients assigned yet.",
                          style: AppTypography.bodyText.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: therapistProvider.patients.length,
                      itemBuilder: (context, index) {
                        final patient = therapistProvider.patients[index];
                        final userData = patient['users'];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _PatientCard(
                            name: userData != null ? userData['full_name'] : 'Unknown Patient',
                            lastActive: 'Recently',
                            progress: 0,
                            trend: 'neutral',
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        onPressed: () {},
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final String name;
  final String lastActive;
  final int progress;
  final String trend;

  const _PatientCard({
    required this.name,
    required this.lastActive,
    required this.progress,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black05,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.lightBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                style: AppTypography.subheading.copyWith(color: AppColors.primaryBlue),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Last active: $lastActive', style: AppTypography.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$progress%',
                style: AppTypography.subheading.copyWith(
                  color: progress > 80 ? AppColors.successGreen : (progress == 0 ? AppColors.textSecondary : AppColors.warningOrange),
                ),
              ),
              Icon(
                trend == 'up' ? Icons.arrow_upward : (trend == 'down' ? Icons.arrow_downward : Icons.remove),
                color: trend == 'up' ? AppColors.successGreen : (trend == 'down' ? AppColors.warningOrange : AppColors.textSecondary),
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
