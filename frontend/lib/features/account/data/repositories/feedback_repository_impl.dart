import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/account/domain/entities/feedback.dart';
import 'package:frontend/features/account/domain/repositories/feedback_repository.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  @override
  Future<void> submitFeedback(UserFeedback feedback) async {
    await ApiClient.post('/feedback', feedback.toJson());
  }

  @override
  Future<List<UserFeedback>> getAllFeedback() async {
    final response = await ApiClient.get('/admin/feedback');
    final List data = response['data'];
    return data.map((json) => UserFeedback.fromJson(json)).toList();
  }

  @override
  Future<void> deleteFeedback(String id) async {
    await ApiClient.delete('/admin/feedback/$id');
  }
}
