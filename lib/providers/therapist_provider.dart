import 'package:flutter/material.dart';
import '../repositories/supabase_repository.dart';

class TherapistProvider extends ChangeNotifier {
  final SupabaseRepository _repository = SupabaseRepository();
  bool _isLoading = false;
  List<dynamic> _patients = [];

  bool get isLoading => _isLoading;
  List<dynamic> get patients => _patients;

  Future<void> fetchPatients(String therapistId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _patients = await _repository.getTherapistPatients(therapistId);
    } catch (e) {
      debugPrint('Error fetching therapist patients: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
