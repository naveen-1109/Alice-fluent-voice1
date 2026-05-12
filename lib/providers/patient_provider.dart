import 'package:flutter/material.dart';
import '../repositories/supabase_repository.dart';

class PatientProvider extends ChangeNotifier {
  final SupabaseRepository _repository = SupabaseRepository();
  bool _isLoading = false;
  
  String? _patientRecordId;
  int _totalSessions = 0;
  double _avgFluency = 0.0;
  
  Map<String, dynamic>? _lastSession;
  
  bool get isLoading => _isLoading;
  String? get patientRecordId => _patientRecordId;
  int get totalSessions => _totalSessions;
  double get avgFluency => _avgFluency;
  Map<String, dynamic>? get lastSession => _lastSession;

  Future<void> fetchAnalytics(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Ensure patient record exists
      var patientProfile = await _repository.getPatientProfile(userId);
      if (patientProfile == null) {
        // Create patient record
        final newPatient = await _repository.createPatient(userId);
        _patientRecordId = newPatient['id'];
      } else {
        _patientRecordId = patientProfile['id'];
      }

      if (_patientRecordId != null) {
        // 2. Fetch sessions
        final sessions = await _repository.getPatientSessions(_patientRecordId!);
        _totalSessions = sessions.length;
        
        if (sessions.isNotEmpty) {
          _lastSession = sessions.first;
          
          int totalScore = 0;
          int validScores = 0;
          for (var session in sessions) {
            if (session['progress_score'] != null) {
              totalScore += (session['progress_score'] as num).toInt();
              validScores++;
            }
          }
          
          if (validScores > 0) {
            _avgFluency = totalScore / validScores;
          } else {
            _avgFluency = 0.0;
          }
        } else {
          _lastSession = null;
          _avgFluency = 0.0;
        }
      }
    } catch (e) {
      debugPrint('Error fetching analytics: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> savePracticeSession(int score, String notes) async {
    if (_patientRecordId == null) return;
    try {
      await _repository.createSession({
        'patient_id': _patientRecordId,
        'progress_score': score,
        'session_notes': notes,
      });
      // Refresh analytics
      final sessions = await _repository.getPatientSessions(_patientRecordId!);
      _totalSessions = sessions.length;
      if (sessions.isNotEmpty) {
        _lastSession = sessions.first;
        int totalScore = 0;
        int validScores = 0;
        for (var session in sessions) {
          if (session['progress_score'] != null) {
            totalScore += (session['progress_score'] as num).toInt();
            validScores++;
          }
        }
        _avgFluency = validScores > 0 ? totalScore / validScores : 0.0;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  Future<void> saveVoiceRecordAndAnalysis(String audioUrl, Map<String, dynamic> analysisData) async {
    if (_patientRecordId == null) return;
    try {
      await _repository.saveVoiceRecord(
        _patientRecordId!,
        audioUrl,
        analysisData,
      );
    } catch (e) {
      debugPrint('Error saving voice record: $e');
    }
  }
}
