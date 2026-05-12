import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'recording_screen.dart';

class GoalSelectionScreen extends StatelessWidget {
  const GoalSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              const SizedBox(height: 16),
              Text(
                'Choose your goal',
                style: AppTypography.screenHeading,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Self-Practice Session',
                  style: AppTypography.smallText.copyWith(color: AppColors.primaryBlue),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'What would you like to work on today?',
                style: AppTypography.bodyText,
              ),
              const SizedBox(height: 40),
              // Options
              _GoalOptionCard(
                title: 'Slow Speech',
                subtitle: 'Focus on speaking at a controlled pace',
                icon: Icons.speed,
                backgroundColor: AppColors.lightBlue,
                iconColor: AppColors.primaryBlue,
                onTap: () => _navigateToRecording(context, 'Slow Speech'),
              ),
              const SizedBox(height: 16),
              _GoalOptionCard(
                title: 'Smooth Starts',
                subtitle: 'Practice initiating words gently',
                icon: Icons.flash_on,
                backgroundColor: AppColors.successGreenLight,
                iconColor: AppColors.successGreen,
                onTap: () => _navigateToRecording(context, 'Smooth Starts'),
              ),
              const SizedBox(height: 16),
              _GoalOptionCard(
                title: 'Free Speech',
                subtitle: 'Speak naturally without specific focus',
                icon: Icons.chat_bubble_outline,
                backgroundColor: AppColors.accentPurpleLight,
                iconColor: AppColors.accentPurple,
                onTap: () => _navigateToRecording(context, 'Free Speech'),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToRecording(BuildContext context, String goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordingScreen(goal: goal),
      ),
    );
  }
}

class _GoalOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _GoalOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withAlpha(77)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.subheading.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.smallText.copyWith(color: AppColors.textSecondary),
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
