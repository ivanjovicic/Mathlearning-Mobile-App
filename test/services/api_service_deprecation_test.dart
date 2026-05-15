import 'package:flutter_test/flutter_test.dart';
import 'package:mathlearning/services/api_service.dart';

void main() {
  test('legacy adaptive ApiService methods exist (deprecated)', () {
    final api = ApiService();

    // Do not invoke network methods; just assert the methods exist as tear-offs.
    expect(api.startAdaptiveSession, isNotNull);
    expect(api.startAdaptiveSessionResult, isNotNull);
    expect(api.submitAdaptiveSessionAnswer, isNotNull);
    expect(api.submitAdaptiveSessionAnswerResult, isNotNull);
    expect(api.getAdaptiveReview, isNotNull);
    expect(api.getAdaptiveReviewResult, isNotNull);
    expect(api.getAdaptivePath, isNotNull);
    expect(api.getAdaptivePathResult, isNotNull);
  });
}
