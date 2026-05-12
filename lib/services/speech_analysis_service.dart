import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Communicates with the FluentVoice Python ML backend.
class SpeechAnalysisService {
  // Change this URL if you deploy the backend to a server.
  static const String _baseUrl = 'http://localhost:8000/api/v1/speech';

  /// Send raw audio bytes to the ML API and return the analysis result.
  ///
  /// [audioBytes] – raw bytes of the recorded audio file
  /// [filename]   – file name with extension, e.g. "session.wav"
  static Future<Map<String, dynamic>> analyzeAudio({
    required Uint8List audioBytes,
    String filename = 'session.wav',
  }) async {
    final uri = Uri.parse('$_baseUrl/analyze');

    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          audioBytes,
          filename: filename,
        ),
      );

    try {
      final streamedResponse = await request.send();
      final body = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        return json.decode(body) as Map<String, dynamic>;
      } else {
        throw Exception('API Error ${streamedResponse.statusCode}: $body');
      }
    } on Exception catch (e) {
      throw Exception('Failed to reach speech analysis server: $e');
    }
  }

  /// Simple health check – returns true if the backend is running.
  static Future<bool> isBackendReachable() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
