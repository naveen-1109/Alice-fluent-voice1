import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user_model.dart';

class SupabaseRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // ==========================================
  // USERS
  // ==========================================
  Future<AppUser?> getUserProfile(String userId) async {
    try {
      final data = await _client.from('users').select().eq('id', userId).single();
      return AppUser.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    await _client.from('users').update(updates).eq('id', userId);
  }

  // ==========================================
  // PATIENTS
  // ==========================================
  Future<Map<String, dynamic>?> getPatientProfile(String userId) async {
    try {
      return await _client.from('patients').select().eq('user_id', userId).single();
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createPatient(String userId) async {
    final response = await _client.from('patients').insert({'user_id': userId}).select().single();
    return response;
  }

  Future<List<dynamic>> getTherapistPatients(String therapistId) async {
    return await _client.from('patients').select('*, users(*)').eq('assigned_therapist', therapistId);
  }

  // ==========================================
  // THERAPISTS
  // ==========================================
  Future<Map<String, dynamic>?> getTherapistProfile(String userId) async {
    try {
      return await _client.from('therapists').select().eq('user_id', userId).single();
    } catch (e) {
      return null;
    }
  }

  // ==========================================
  // APPOINTMENTS
  // ==========================================
  Future<List<dynamic>> getPatientAppointments(String patientId) async {
    return await _client.from('appointments').select('*, therapists(*, users(*))').eq('patient_id', patientId).order('appointment_date', ascending: true);
  }

  Future<List<dynamic>> getTherapistAppointments(String therapistId) async {
    return await _client.from('appointments').select('*, patients(*, users(*))').eq('therapist_id', therapistId).order('appointment_date', ascending: true);
  }

  Future<void> createAppointment(Map<String, dynamic> appointmentData) async {
    await _client.from('appointments').insert(appointmentData);
  }

  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    await _client.from('appointments').update({'status': status}).eq('id', appointmentId);
  }

  // ==========================================
  // THERAPY SESSIONS
  // ==========================================
  Future<List<dynamic>> getPatientSessions(String patientId) async {
    return await _client.from('therapy_sessions').select().eq('patient_id', patientId).order('created_at', ascending: false);
  }

  Future<void> createSession(Map<String, dynamic> sessionData) async {
    await _client.from('therapy_sessions').insert(sessionData);
  }

  // ==========================================
  // VOICE RECORDS
  // ==========================================
  Future<List<dynamic>> getPatientVoiceRecords(String patientId) async {
    return await _client.from('voice_records').select().eq('patient_id', patientId).order('created_at', ascending: false);
  }

  Future<void> saveVoiceRecord(String patientId, String audioUrl, Map<String, dynamic> analysis) async {
    await _client.from('voice_records').insert({
      'patient_id': patientId,
      'audio_url': audioUrl,
      'analysis_result': analysis,
    });
  }

  // ==========================================
  // NOTIFICATIONS
  // ==========================================
  Future<List<dynamic>> getUserNotifications(String userId) async {
    return await _client.from('notifications').select().eq('user_id', userId).order('created_at', ascending: false);
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }

  // ==========================================
  // STORAGE
  // ==========================================
  Future<String> uploadAudioFile(String userId, String filePath, Uint8List fileBytes) async {
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _client.storage.from('recordings').uploadBinary(path, fileBytes);
    return _client.storage.from('recordings').getPublicUrl(path);
  }

  Future<String> uploadProfileImage(String userId, String fileExtension, Uint8List fileBytes) async {
    final path = '$userId/profile_$userId.$fileExtension';
    // We use upsert: true to overwrite any existing profile image
    await _client.storage.from('profiles').uploadBinary(
      path, 
      fileBytes,
      fileOptions: const FileOptions(upsert: true),
    );
    // Cache bust by appending a timestamp to the URL
    final url = _client.storage.from('profiles').getPublicUrl(path);
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }
}
