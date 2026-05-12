import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../services/speech_analysis_service.dart';
import 'session_result_screen.dart';

class AnalyzingScreen extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  // Optional: raw audio bytes to send to the ML API
  final Uint8List? audioBytes;
  final String audioFilename;

  const AnalyzingScreen({
    super.key,
    required this.sessionData,
    this.audioBytes,
    this.audioFilename = 'session.wav',
  });

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentStage = 0;
  final List<String> _stages = [
    "Uploading audio...",
    "Extracting acoustic features...",
    "Detecting disfluency events...",
    "Computing fluency score...",
    "Generating AI insights...",
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    // Animate through stages visually while API call runs
    _advanceStages();

    Map<String, dynamic> resultData;

    if (widget.audioBytes != null) {
      // ─── Real ML analysis ────────────────────────────
      try {
        final apiResult = await SpeechAnalysisService.analyzeAudio(
          audioBytes: widget.audioBytes!,
          filename: widget.audioFilename,
        );
        resultData = {
          ...widget.sessionData,
          'fluency_score':     apiResult['fluency_score'] ?? 75,
          'duration_seconds':  apiResult['duration_seconds'] ?? widget.sessionData['duration_seconds'],
          'severity':          apiResult['severity'] ?? 'Mild',
          'wpm':               apiResult['words_per_minute'] ?? 110,
          'total_events':      apiResult['total_events'] ?? 0,
          'events':            apiResult['events'] ?? {},
          'disfluency_events': apiResult['disfluency_events'] ?? [],
          'insights':          apiResult['insights'] ?? [],
          'from_ml':           true,
        };
      } catch (e) {
        // Fallback to simulated if API is unreachable
        resultData = {
          ...widget.sessionData,
          'from_ml': false,
          'error': e.toString(),
        };
      }
    } else {
      // No audio bytes – use simulated (e.g., from old recording flow)
      resultData = {...widget.sessionData, 'from_ml': false};
    }

    // Wait until at least stage 4 is shown
    while (_currentStage < 4) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SessionResultScreen(sessionData: resultData),
        ),
      );
    }
  }

  void _advanceStages() async {
    for (int i = 0; i < _stages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1100));
      if (mounted) {
        setState(() => _currentStage = i);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Pulsing Mic/Waveform
              ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.1).animate(
                  CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
                ),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue10,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.primaryBlue20,
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome, color: AppColors.primaryBlue, size: 60),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              
              Text(
                "Analyzing your speech...",
                style: AppTypography.screenHeading.copyWith(color: AppColors.primaryBlue),
              ),
              const SizedBox(height: 16),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  "Our AI is processing your recording to provide detailed insights and personalized feedback.",
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyText.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 48),

              // Progress Stages
              SizedBox(
                height: 40,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    _stages[_currentStage],
                    key: ValueKey<int>(_currentStage),
                    style: AppTypography.subheading.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_currentStage + 1) / _stages.length,
                    backgroundColor: AppColors.primaryBlue10,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                    minHeight: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
