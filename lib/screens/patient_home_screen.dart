import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'goal_selection_screen.dart';
import 'profile_screen.dart';
import 'analytics_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        Provider.of<PatientProvider>(context, listen: false)
            .fetchAnalytics(authProvider.currentUser!.id);
      }
    });
  }

  final List<Widget> _screens = [
    const _DashboardContent(),
    const AnalyticsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.black05,
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.textSecondary,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Progress'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  String _formatDate(String? isoDate) {
    if (isoDate == null) return "Never";
    final date = DateTime.tryParse(isoDate);
    if (date == null) return "Unknown";
    return "${date.month}/${date.day}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final patientProvider = Provider.of<PatientProvider>(context);
    final user = authProvider.appUser;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 32.0),
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
                const SizedBox(height: 24),
                // Greeting
                Text(
                  'Good morning, ${user?.fullName.split(' ').first ?? 'User'}!',
                  style: AppTypography.subheading,
                ),
                const SizedBox(height: 24),
                
                // Progress Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.primaryBlue30,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: patientProvider.isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.white))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.trending_up, color: AppColors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "This Week's Progress",
                                  style: AppTypography.bodyText.copyWith(color: AppColors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "${patientProvider.avgFluency.toInt()}% Avg. Fluency",
                              style: AppTypography.displayLarge.copyWith(color: AppColors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${patientProvider.totalSessions} Sessions",
                              style: AppTypography.smallText.copyWith(color: AppColors.white80),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 24),
                
                // Last Session Card
                Container(
                  width: double.infinity,
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
                  child: patientProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : patientProvider.lastSession == null
                          ? Center(
                              child: Text(
                                "No sessions recorded yet.",
                                style: AppTypography.bodyText.copyWith(color: AppColors.textSecondary),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Last Session",
                                        style: AppTypography.smallText.copyWith(color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(patientProvider.lastSession!['created_at']),
                                        style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${patientProvider.lastSession!['progress_score'] ?? 0}% fluency",
                                        style: AppTypography.caption,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "${patientProvider.lastSession!['progress_score'] ?? 0}%",
                                  style: AppTypography.displayLarge.copyWith(color: AppColors.successGreen),
                                ),
                              ],
                            ),
                ),
                const SizedBox(height: 24),
                
                // Tip Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: AppColors.primaryBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Tip: Remember to breathe deeply before starting a sentence.",
                          style: AppTypography.smallText.copyWith(color: AppColors.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                // Practice Now Button
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const GoalSelectionScreen()),
                          );
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: AppColors.primaryBlue30, blurRadius: 15, offset: Offset(0, 8)),
                            ],
                          ),
                          child: const Icon(Icons.mic, color: AppColors.white, size: 36),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text("Start Practice", style: AppTypography.subheading.copyWith(color: AppColors.primaryBlue)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
