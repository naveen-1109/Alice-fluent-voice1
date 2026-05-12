import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/custom_button.dart';
import 'session_replay_screen.dart';

class DetailedAnalysisScreen extends StatelessWidget {
  final Map<String, dynamic> analysisData;

  const DetailedAnalysisScreen({super.key, required this.analysisData});

  @override
  Widget build(BuildContext context) {
    // Support both old key names and new ML API key names
    final rawEvents = analysisData['events'] ?? analysisData['event_breakdown'] ?? {};
    final Map<String, dynamic> events = Map<String, dynamic>.from(rawEvents);

    final int duration = (analysisData['duration_seconds'] as num?)?.toInt() ?? 0;
    final int totalEvents = analysisData['total_events'] ?? 0;
    final double epm = (analysisData['events_per_min'] as num?)?.toDouble()
        ?? (duration > 0 ? (totalEvents / (duration / 60)) : 0);
    final double avgGap = (analysisData['average_gap'] as num?)?.toDouble() ?? 0;
    final double longestGap = (analysisData['longest_gap'] as num?)?.toDouble() ?? 0;
    final double shortestGap = avgGap > 0 ? (avgGap * 0.4) : 0;

    final List<dynamic> timeline =
        List<dynamic>.from(analysisData['event_timeline'] ?? []);
    final List<String> insights =
        List<String>.from(analysisData['insights'] ?? []);
    final bool fromML = analysisData['from_ml'] == true;
    final bool whisperUsed = analysisData['whisper_used'] == true;
    final String? transcript = analysisData['transcript'] as String?;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Detailed Analysis', style: AppTypography.screenHeading),
        centerTitle: true,
        actions: [
          if (fromML)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Chip(
                label: Text(
                  whisperUsed ? 'AI + Whisper' : 'AI Analysis',
                  style: const TextStyle(fontSize: 10, color: AppColors.white),
                ),
                backgroundColor: AppColors.primaryBlue,
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── A. Timing & Gaps ──────────────────────────────────
                  Text("Timing & Gaps", style: AppTypography.subheading),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard("Avg Gap", "${avgGap.toStringAsFixed(1)}s")),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoCard("Shortest", "${shortestGap.toStringAsFixed(1)}s")),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoCard("Longest", "${longestGap.toStringAsFixed(1)}s")),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── B. Event Timeline ──────────────────────────────────
                  Text("Event Timeline", style: AppTypography.subheading),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: AppColors.black05, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        if (timeline.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              "No disfluency events detected 🎉",
                              style: AppTypography.bodyText.copyWith(color: AppColors.successGreen),
                            ),
                          )
                        else
                          ...timeline.take(10).map((e) {
                            final type = (e['type'] ?? '').toString();
                            final time = (e['time'] ?? '0:00').toString();
                            final word = e['word'] as String?;
                            return _buildTimelineMarker(
                              time,
                              word != null ? "$type - $word" : type,
                              _colorForType(type),
                            );
                          }),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: "Open Session Replay",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SessionReplayScreen(analysisData: analysisData),
                              ),
                            );
                          },
                          height: 48,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── C. Disfluency Breakdown ────────────────────────────
                  Text("Disfluency Breakdown", style: AppTypography.subheading),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: AppColors.black05, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        _buildBreakdownBar("Interjections", events['interjections'] ?? 0, totalEvents, AppColors.warningOrange),
                        const SizedBox(height: 12),
                        _buildBreakdownBar("Prolongations", events['prolongations'] ?? 0, totalEvents, AppColors.primaryBlue),
                        const SizedBox(height: 12),
                        _buildBreakdownBar("Blocks", events['blocks'] ?? 0, totalEvents, Colors.red),
                        const SizedBox(height: 12),
                        _buildBreakdownBar("Repetitions", events['repetitions'] ?? 0, totalEvents, AppColors.successGreen),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── D. Session Metrics ────────────────────────────────
                  Text("Session Metrics", style: AppTypography.subheading),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow("Speech Rate",
                            "${analysisData['wpm'] ?? analysisData['speech_rate_wpm'] ?? '--'} WPM"),
                        const Divider(height: 24),
                        _buildSummaryRow("Events per minute", epm.toStringAsFixed(1)),
                        const Divider(height: 24),
                        _buildSummaryRow("Severity Level", analysisData['severity'] ?? '--'),
                        const Divider(height: 24),
                        _buildSummaryRow("AI Engine",
                            whisperUsed ? "Whisper + Librosa" : fromML ? "Librosa Acoustic" : "Simulated"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── E. AI Insights ────────────────────────────────────
                  Text("AI Insights", style: AppTypography.subheading),
                  const SizedBox(height: 16),
                  if (insights.isEmpty)
                    _buildInsightCard(Icons.check_circle, "All Good",
                        "No specific issues detected. Great session!")
                  else
                    ...insights.map((insight) {
                      final icon = _iconForInsight(insight);
                      final title = _titleForInsight(insight);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildInsightCard(icon, title, insight),
                      );
                    }),

                  // ── F. Transcript ─────────────────────────────────────
                  if (transcript != null && transcript.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text("Transcript", style: AppTypography.subheading),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryBlue30),
                      ),
                      child: Text(
                        transcript,
                        style: AppTypography.bodyText.copyWith(height: 1.6),
                      ),
                    ),
                  ],
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _colorForType(String type) {
    switch (type.toLowerCase()) {
      case "block":        return Colors.red;
      case "prolongation": return AppColors.primaryBlue;
      case "repetition":   return AppColors.successGreen;
      case "interjection": return AppColors.warningOrange;
      default:             return AppColors.textSecondary;
    }
  }

  IconData _iconForInsight(String text) {
    if (text.contains("🔴") || text.contains("block"))    return Icons.pause_circle;
    if (text.contains("🟡") || text.contains("prolong"))  return Icons.graphic_eq;
    if (text.contains("🟠") || text.contains("repeti"))   return Icons.repeat;
    if (text.contains("🗣") || text.contains("filler"))   return Icons.chat_bubble;
    if (text.contains("🚀") || text.contains("fast"))     return Icons.speed;
    if (text.contains("🐢") || text.contains("slow"))     return Icons.hourglass_bottom;
    if (text.contains("🎉") || text.contains("Excellent")) return Icons.star;
    return Icons.lightbulb;
  }

  String _titleForInsight(String text) {
    if (text.contains("block"))       return "Speech Blocks";
    if (text.contains("prolongat"))   return "Prolongations";
    if (text.contains("repetit"))     return "Repetitions";
    if (text.contains("filler"))      return "Filler Words";
    if (text.contains("WPM") || text.contains("rate")) return "Speech Rate";
    if (text.contains("Excellent") || text.contains("🎉")) return "Excellent Session!";
    if (text.contains("Good") || text.contains("👍"))   return "Good Progress";
    if (text.contains("Transcript") || text.contains("word")) return "Transcript";
    return "AI Insight";
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          Text(value, style: AppTypography.displayLarge.copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.caption, maxLines: 1),
        ],
      ),
    );
  }

  Widget _buildTimelineMarker(String time, String type, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(time,
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
          ),
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              type.replaceAll(type[0], type[0].toUpperCase()),
              style: AppTypography.bodyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownBar(String label, dynamic count, int total, Color color) {
    final int c = (count as num?)?.toInt() ?? 0;
    final double pct = total > 0 ? (c / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodyText),
            Text("$c", style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.lightBlue,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyText.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInsightCard(IconData icon, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue30),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.bodyText
                        .copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                const SizedBox(height: 4),
                Text(body, style: AppTypography.smallText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
