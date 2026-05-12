import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/patient_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patientProvider = Provider.of<PatientProvider>(context);
    final avg = patientProvider.avgFluency.toInt();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        title: Text('Progress Analytics', style: AppTypography.screenHeading),
        centerTitle: true,
        automaticallyImplyLeading: false, // For bottom nav
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Graph Section
                  Text("Weekly Fluency Trend", style: AppTypography.subheading),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 220,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: AppColors.black05, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildBar('Mon', 70),
                              _buildBar('Tue', 75),
                              _buildBar('Wed', 82),
                              _buildBar('Thu', avg > 0 ? avg : 85, isHighlighted: true),
                              _buildBar('Fri', 88),
                              _buildBar('Sat', 90),
                              _buildBar('Sun', 92),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Monthly Overview
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: "Total Sessions",
                          value: "${patientProvider.totalSessions}",
                          icon: Icons.mic,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: "Avg. Score",
                          value: "$avg%",
                          icon: Icons.trending_up,
                          color: AppColors.successGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Achievements
                  Text("Achievements", style: AppTypography.subheading),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _AchievementBadge(icon: Icons.local_fire_department, label: "3 Day Streak", color: AppColors.warningOrange),
                        const SizedBox(width: 16),
                        _AchievementBadge(icon: Icons.star, label: "First Session", color: AppColors.primaryBlue),
                        const SizedBox(width: 16),
                        _AchievementBadge(icon: Icons.verified, label: "90% Club", color: AppColors.successGreen, opacity: avg >= 90 ? 1.0 : 0.4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Insights
                  Text("AI Insights", style: AppTypography.subheading),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryBlue30),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.primaryBlue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            patientProvider.totalSessions == 0
                                ? "Complete your first session to unlock personalized AI insights."
                                : "Your pacing has improved by 15% this week. Keep taking deep breaths before starting complex sentences.",
                            style: AppTypography.bodyText.copyWith(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Padding for BottomNav
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBar(String day, int percentage, {bool isHighlighted = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$percentage%', style: AppTypography.caption.copyWith(fontSize: 10)),
        const SizedBox(height: 8),
        Container(
          width: 24,
          height: 120 * (percentage / 100),
          decoration: BoxDecoration(
            color: isHighlighted ? AppColors.primaryBlue : AppColors.lightBlue,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: AppTypography.caption),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(value, style: AppTypography.displayLarge.copyWith(fontSize: 28, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(title, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double opacity;

  const _AchievementBadge({required this.icon, required this.label, required this.color, this.opacity = 1.0});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(76)),
          boxShadow: const [BoxShadow(color: AppColors.black05, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
