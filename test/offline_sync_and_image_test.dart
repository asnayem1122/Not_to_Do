import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do/core/services/calendar_sync_service.dart';
import 'package:not_to_do/core/services/routine_parser_service.dart';

void main() {
  group('Offline Sync Queue Tests', () {
    late CalendarSyncService syncService;

    setUp(() {
      syncService = CalendarSyncService();
    });

    test('enqueues and clears pending sync items without duplicates', () {
      expect(syncService.hasPendingSync, isFalse);
      expect(syncService.pendingSyncQueue.isEmpty, isTrue);

      syncService.enqueuePendingSync('ae-101');
      syncService.enqueuePendingSync('ae-102');
      syncService.enqueuePendingSync('ae-101'); // duplicate

      expect(syncService.hasPendingSync, isTrue);
      expect(syncService.pendingSyncQueue.length, 2);
      expect(syncService.pendingSyncQueue, contains('ae-101'));
      expect(syncService.pendingSyncQueue, contains('ae-102'));

      syncService.clearPendingSync('ae-101');
      expect(syncService.pendingSyncQueue.length, 1);
      expect(syncService.pendingSyncQueue.first, 'ae-102');

      syncService.clearPendingSync('ae-102');
      expect(syncService.hasPendingSync, isFalse);
    });

    test('reconcilePendingQueue purges non-existent events', () async {
      syncService.enqueuePendingSync('missing-id-1');
      syncService.enqueuePendingSync('missing-id-2');

      final reconciled = await syncService.reconcilePendingQueue(
        [],
        (eventId, calendarId) async {},
      );

      expect(reconciled, 0);
      expect(syncService.hasPendingSync, isFalse);
    });
  });

  group('Image Downscaling Pipeline Tests', () {
    test('downscaleImageIfNeeded gracefully handles empty or invalid byte data', () async {
      final dummyBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final result = await RoutineParserService.downscaleImageIfNeeded(
        dummyBytes,
        maxDimension: 1560,
      );

      // Falls back to raw bytes gracefully without throwing
      expect(result.length, dummyBytes.length);
    });
  });
}
