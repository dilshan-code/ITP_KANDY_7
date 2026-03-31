import 'package:frontend/features/account/domain/entities/feedback.dart';

abstract class FeedbackRepository {
  Future<void> submitFeedback(UserFeedback feedback);
  Future<List<UserFeedback>> getAllFeedback();
  Future<void> deleteFeedback(String id);
}
