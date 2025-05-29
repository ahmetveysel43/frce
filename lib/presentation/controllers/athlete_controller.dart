// lib/presentation/controllers/athlete_controller.dart
import 'package:flutter/foundation.dart';
import '../../domain/entities/athlete.dart';
import '../../domain/usecases/manage_athlete_usecase.dart';

enum AthleteListState {
  loading,
  loaded,
  error,
  empty,
}

class AthleteController extends ChangeNotifier {
  final ManageAthleteUseCase _manageAthleteUseCase;

  AthleteController(this._manageAthleteUseCase);

  // State
  AthleteListState _state = AthleteListState.loading;
  List<Athlete> _athletes = [];
  List<Athlete> _filteredAthletes = [];
  String _searchQuery = '';
  String? _errorMessage;
  bool _isSearching = false;

  // Getters
  AthleteListState get state => _state;
  List<Athlete> get athletes => _isSearching ? _filteredAthletes : _athletes;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == AthleteListState.loading;
  bool get hasError => _state == AthleteListState.error;
  bool get isEmpty => _state == AthleteListState.empty;
  bool get isSearching => _isSearching;
  int get athleteCount => athletes.length;

  // Load all athletes
  Future<void> loadAthletes() async {
    _setState(AthleteListState.loading);

    final result = await _manageAthleteUseCase.getAllAthletes();
    
    result.fold(
      (failure) => _setError(failure.message),
      (athletes) {
        _athletes = athletes;
        _filteredAthletes = athletes;
        _setState(athletes.isEmpty ? AthleteListState.empty : AthleteListState.loaded);
      },
    );
  }

  // Search athletes
  Future<void> searchAthletes(String query) async {
    _searchQuery = query.trim();
    
    if (_searchQuery.isEmpty) {
      _isSearching = false;
      _filteredAthletes = _athletes;
      notifyListeners();
      return;
    }

    _isSearching = true;
    
    final result = await _manageAthleteUseCase.searchAthletes(_searchQuery);
    
    result.fold(
      (failure) => _setError(failure.message),
      (athletes) {
        _filteredAthletes = athletes;
        notifyListeners();
      },
    );
  }

  // Add new athlete
  Future<bool> addAthlete({
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required Gender gender,
    required double height,
    required double weight,
    String? sport,
    String? position,
    String? notes,
  }) async {
    final result = await _manageAthleteUseCase.createAthlete(
      firstName: firstName,
      lastName: lastName,
      birthDate: birthDate,
      gender: gender,
      height: height,
      weight: weight,
      sport: sport,
      position: position,
      notes: notes,
    );

    return result.fold(
      (failure) {
        _setError(failure.message);
        return false;
      },
      (_) {
        // Listeyi yenile
        loadAthletes();
        return true;
      },
    );
  }

  // Update athlete
  Future<bool> updateAthlete(Athlete athlete) async {
    final result = await _manageAthleteUseCase.updateAthlete(athlete);

    return result.fold(
      (failure) {
        _setError(failure.message);
        return false;
      },
      (_) {
        // Listeyi yenile
        loadAthletes();
        return true;
      },
    );
  }

  // Delete athlete
  Future<bool> deleteAthlete(String athleteId) async {
    final result = await _manageAthleteUseCase.deleteAthlete(athleteId);

    return result.fold(
      (failure) {
        _setError(failure.message);
        return false;
      },
      (_) {
        // Listeyi yenile
        loadAthletes();
        return true;
      },
    );
  }

  // Get athlete by ID
  Future<Athlete?> getAthlete(String athleteId) async {
    final result = await _manageAthleteUseCase.getAthlete(athleteId);

    return result.fold(
      (failure) {
        _setError(failure.message);
        return null;
      },
      (athlete) => athlete,
    );
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _isSearching = false;
    _filteredAthletes = _athletes;
    notifyListeners();
  }

  // Refresh
  Future<void> refresh() async {
    await loadAthletes();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    if (_state == AthleteListState.error) {
      _setState(_athletes.isEmpty ? AthleteListState.empty : AthleteListState.loaded);
    }
  }

  // Private methods
  void _setState(AthleteListState newState) {
    _state = newState;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _state = AthleteListState.error;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}