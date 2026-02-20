import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_connect/utils/firestore_error_handler.dart';

void main() {
  group('FirestoreErrorHandler.toUserMessage', () {
    test('returns generic message for unknown error', () {
      expect(
        FirestoreErrorHandler.toUserMessage(Exception('boom')),
        'Something went wrong. Please try again.',
      );
    });

    test('handles plain string error', () {
      expect(
        FirestoreErrorHandler.toUserMessage('some string'),
        'Something went wrong. Please try again.',
      );
    });
  });

  group('FirestoreErrorHandler.toUserMessageForOperation', () {
    test('returns generic message for non-seed operations', () {
      expect(
        FirestoreErrorHandler.toUserMessageForOperation(
          Exception('fail'),
          operation: 'other_op',
        ),
        'Something went wrong. Please try again.',
      );
    });

    test('returns seed-specific message for seed_demo_data', () {
      final result = FirestoreErrorHandler.toUserMessageForOperation(
        Exception('timeout'),
        operation: 'seed_demo_data',
      );
      expect(result, contains('Demo seed failed'));
    });
  });
}
