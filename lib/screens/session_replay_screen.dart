import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class SessionReplayScreen extends StatefulWidget {
  final Map<String, dynamic> analysisData;

  const SessionReplayScreen({super.key, required this.analysisData});

  @override
  State<SessionReplayScreen> createState() => _SessionReplayScreenState();
}

class _SessionReplayScreenState extends State<SessionReplayScreen> with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  double _currentPosition = 0;
  late int _duration;

  @override
  void initState() {
    super.initState();
    _duration = widget.analysisData['duration_seconds'];
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Session Replay',
          style: AppTypography.subheading,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  
                  // Score & Duration Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: AppColors.black05, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text("Fluency", style: AppTypography.caption),
                            const SizedBox(height: 4),
                            Text("${widget.analysisData['fluency_score']}%", style: AppTypography.displayLarge.copyWith(color: AppColors.successGreen, fontSize: 32)),
                          ],
                        ),
                        Container(width: 1, height: 40, color: AppColors.borderGrey),
                        Column(
                          children: [
                            Text("Duration", style: AppTypography.caption),
                            const SizedBox(height: 4),
                            Text(_formatTime(_duration), style: AppTypography.displayLarge.copyWith(fontSize: 32)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // Waveform / Timeline simulation
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue10,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        // Fake Waveform Lines
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(30, (index) {
                            return Container(
                              width: 4,
                              height: (20 + (index * 7 % 40)).toDouble(),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue30,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                        // Event Markers
                        Positioned(
                          left: 40,
                          bottom: 10,
                          child: _buildTimelinePin(AppColors.primaryBlue, "Pro"),
                        ),
                        Positioned(
                          left: 120,
                          bottom: 10,
                          child: _buildTimelinePin(AppColors.warningOrange, "Int"),
                        ),
                        Positioned(
                          left: 200,
                          bottom: 10,
                          child: _buildTimelinePin(Colors.red, "Blk"),
                        ),
                        // Progress Indicator
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.8 * (_currentPosition / (_duration == 0 ? 1 : _duration)),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withAlpha(50),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Scrubber
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.primaryBlue,
                      inactiveTrackColor: AppColors.primaryBlue10,
                      thumbColor: AppColors.primaryBlue,
                      overlayColor: AppColors.primaryBlue30,
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: _currentPosition,
                      min: 0,
                      max: _duration.toDouble() > 0 ? _duration.toDouble() : 1,
                      onChanged: (val) {
                        setState(() {
                          _currentPosition = val;
                        });
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatTime(_currentPosition.toInt()), style: AppTypography.caption),
                      Text(_formatTime(_duration), style: AppTypography.caption),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Playback Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10),
                        iconSize: 40,
                        color: AppColors.textPrimary,
                        onPressed: () {
                          setState(() {
                            _currentPosition = (_currentPosition - 10).clamp(0, _duration.toDouble());
                          });
                        },
                      ),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: _togglePlay,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: AppColors.primaryBlue30, blurRadius: 15, offset: Offset(0, 8)),
                            ],
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: AppColors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: const Icon(Icons.forward_10),
                        iconSize: 40,
                        color: AppColors.textPrimary,
                        onPressed: () {
                          setState(() {
                            _currentPosition = (_currentPosition + 10).clamp(0, _duration.toDouble());
                          });
                        },
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelinePin(Color color, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 2,
          height: 16,
          color: color,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label, style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
