import 'package:flutter/material.dart';
import 'package:frontend/features/account/domain/entities/feedback.dart';
import 'package:frontend/features/account/domain/repositories/feedback_repository.dart';
import 'package:frontend/features/account/data/repositories/feedback_repository_impl.dart';

class FeedbackProvider extends ChangeNotifier {
  final FeedbackRepository _repository;
  
  FeedbackProvider({FeedbackRepository? repository}) 
      : _repository = repository ?? FeedbackRepositoryImpl();
  
  List<UserFeedback> _feedbacks = [];
  bool _isLoading = false;
  String? _error;

  List<UserFeedback> get feedbacks => _feedbacks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> submitFeedback(String category, String message) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final feedback = UserFeedback(
        id: '',
        ownerId: '', // Set by backend
        ownerName: '', // Set by backend
        category: category,
        message: message,
        createdAt: DateTime.now(),
      );
      await _repository.submitFeedback(feedback);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllFeedback() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _feedbacks = await _repository.getAllFeedback();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteFeedback(String id) async {
    try {
      await _repository.deleteFeedback(id);
      _feedbacks.removeWhere((f) => f.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
