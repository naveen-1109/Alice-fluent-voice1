import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/patient_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/custom_button.dart';
import 'detailed_analysis_screen.dart';

class SessionResultScreen extends StatefulWidget {
  final Map<String, dynamic> sessionData;

  const SessionResultScreen({super.key, required this.sessionData});

  @override
  State<SessionResultScreen> createState() => _SessionResultScreenState();
}

class _SessionResultScreenState extends State<SessionResultScreen> {
  bool _isSaved = false;
  late Map<String, dynamic> _analysisData;

  @override
  void initState() {
    super.initState();
    _buildAnalysisData();
    
    // Save to database automatically when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveToDatabase();
    });
  }

  void _buildAnalysisData() {
    final bool fromML = widget.sessionData['from_ml'] == true;
    final int fluencyScore = widget.sessionData['fluency_score'] ?? 75;
    final int duration = widget.sessionData['duration_seconds'] ?? 60;

    if (fromML) {
      // Use real data straight from the ML API
      _analysisData = {
        'fluency_score':    fluencyScore,
        'duration_seconds': duration,
        'wpm':              widget.sessionData['wpm'] ?? 110,
        'severity':         widget.sessionData['severity'] ?? 'Mild',
        'total_events':     widget.sessionData['total_events'] ?? 0,
        'goal':             widget.sessionData['goal'],
        'notes':            widget.sessionData['notes'],
        'events':           widget.sessionData['events'] ?? {},
        'insights':         widget.sessionData['insights'] ?? [],
        'from_ml':          true,
      };
    } else {
      // Simulated fallback (no audio bytes were sent)
      final int wpm = 110 + (fluencyScore % 20);
      String severity = 'Mild';
      if (fluencyScore < 70) severity = 'Severe';
      else if (fluencyScore < 85) severity = 'Moderate';
      final int totalEvents = ((100 - fluencyScore) / 10 * (duration / 60)).ceil() + 1;

      _analysisData = {
        'fluency_score':    fluencyScore,
        'duration_seconds': duration,
        'wpm':              wpm,
        'severity':         severity,
        'total_events':     totalEvents,
        'goal':             widget.sessionData['goal'],
        'notes':            widget.sessionData['notes'],
        'events': {
          'prolongations': (totalEvents * 0.4).floor(),
          'interjections': (totalEvents * 0.3).floor(),
          'blocks':        (totalEvents * 0.2).floor(),
          'repetitions':   (totalEvents * 0.1).ceil(),
        },
        'insights': [
          'Practice complete. Connect to the ML backend for detailed insights.',
        ],
        'from_ml': false,
      };
    }
  }

  Future<void> _saveToDatabase() async {
    if (_isSaved) return;
    
    final patientProvider = Provider.of<PatientProvider>(context, listen: false);
    
    // 1. Save standard session to therapy_sessions
    await patientProvider.savePracticeSession(
      _analysisData['fluency_score'],
      _analysisData['notes'],
    );

    // 2. We should ideally also save to voice_records with JSON analysis here.
    // For now, we utilize the new method we will add to PatientProvider
    await patientProvider.saveVoiceRecordAndAnalysis(
      "https://fake-storage-url.com/audio.m4a", // Mock URL
      _analysisData,
    );
    
    setState(() {
      _isSaved = true;
    });
  }

  String _formatTime(int totalSeconds) {
    int m = totalSeconds ~/ 60;
    int s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Success Header
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.successGreenLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle, color: AppColors.successGreen, size: 48),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Wonderful progress!",
                    style: AppTypography.screenHeading.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You completed your practice session",
                    style: AppTypography.bodyText.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 40),

                  // Main Score Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: AppColors.primaryBlue30, blurRadius: 15, offset: Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "${_analysisData['fluency_score']}%",
                          style: AppTypography.displayLarge.copyWith(color: AppColors.white, fontSize: 64),
                        ),
                        Text(
                          "Overall Fluency",
                          style: AppTypography.subheading.copyWith(color: AppColors.white80),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildScoreTag("Severity: ${_analysisData['severity']}"),
                            _buildScoreTag("Self-Practice"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Metrics Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          "Total Events",
                          "${_analysisData['total_events']}",
                          Icons.warning_amber_rounded,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          "Duration",
                          _formatTime(_analysisData['duration_seconds']),
                          Icons.timer_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          "Pacing",
                          "${_analysisData['wpm'] ?? _analysisData['speech_rate_wpm'] ?? '--'} wpm",
                          Icons.speed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Insights Section
                  if ((_analysisData['insights'] as List?)?.isNotEmpty == true) ...[  
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("AI Insights", style: AppTypography.subheading),
                    ),
                    const SizedBox(height: 12),
                    ...(_analysisData['insights'] as List).take(3).map((insight) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue10,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryBlue30),
                          ),
                          child: Text(insight.toString(), style: AppTypography.smallText),
                        ),
                      )
                    ),
                  ],
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.record_voice_over, color: AppColors.primaryBlue, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Speech Rate: ${_analysisData['wpm'] > 120 ? 'Slightly fast' : 'Excellent'}",
                                style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Target pacing is 100-120 WPM. ${_analysisData['wpm'] > 120 ? 'Try to slow down slightly.' : 'Great job maintaining rhythm.'}",
                                style: AppTypography.smallText.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // CTA Buttons
                  CustomButton(
                    text: 'View Detailed Analysis',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailedAnalysisScreen(analysisData: _analysisData),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Pop back to home
                    },
                    child: Text(
                      "Back to Home",
                      style: AppTypography.bodyText.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
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

  Widget _buildScoreTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withAlpha(50),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.black05, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryBlue),
          const SizedBox(height: 12),
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
