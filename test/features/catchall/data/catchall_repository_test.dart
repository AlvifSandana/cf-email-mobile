import 'package:bariskode_cf_email/features/analytics/data/analytics_repository.dart';
import 'package:bariskode_cf_email/features/analytics/domain/entities/activity_log_entry.dart';
import 'package:bariskode_cf_email/features/aliases/data/alias_repository.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/catchall/data/catchall_repository.dart';
import 'package:bariskode_cf_email/shared/models/alias_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CatchAllRepository', () {
    test('filters to unknown addresses for selected domain', () async {
      final repository = CatchAllRepository(
        analyticsRepository: FakeAnalyticsRepository(
          logs: [
            ActivityLogEntry(
              address: 'sales@example.com',
              status: 'forwarded',
              spf: 'pass',
              dkim: 'pass',
              dmarc: 'pass',
              timestamp: _timestamp,
            ),
            ActivityLogEntry(
              address: 'hello@example.com',
              status: 'dropped',
              spf: 'fail',
              dkim: 'pass',
              dmarc: 'none',
              timestamp: _earlierTimestamp,
            ),
            ActivityLogEntry(
              address: 'other@startup.io',
              status: 'forwarded',
              spf: 'pass',
              dkim: 'pass',
              dmarc: 'pass',
              timestamp: _timestamp,
            ),
            ActivityLogEntry(
              address: 'sales@example.com',
              status: 'forwarded',
              spf: 'pass',
              dkim: 'pass',
              dmarc: 'pass',
              timestamp: _earlierTimestamp,
            ),
          ],
        ),
        aliasRepository: FakeAliasRepository(
          aliases: const [
            AliasModel(
              id: 'rule-1',
              address: 'hello@example.com',
              destination: 'dest@example.net',
              isEnabled: true,
              isSupported: true,
            ),
          ],
        ),
      );

      final result = await repository.listDetectedAddresses(
        zoneId: 'zone-1',
        domainName: 'example.com',
      );

      expect(result, hasLength(1));
      expect(result.single.address, 'sales@example.com');
      expect(result.single.lastSeenLabel, 'Last seen 2026-03-09T10:15:00.000Z');
    });

    test(
      'propagates recoverable analytics failures without logout logic',
      () async {
        final repository = CatchAllRepository(
          analyticsRepository: FakeAnalyticsRepository(
            error: const AuthFailure.network(),
          ),
          aliasRepository: FakeAliasRepository(),
        );

        await expectLater(
          repository.listDetectedAddresses(
            zoneId: 'zone-1',
            domainName: 'example.com',
          ),
          throwsA(
            isA<AuthFailure>().having(
              (failure) => failure.type,
              'type',
              AuthFailureType.network,
            ),
          ),
        );
      },
    );

    test(
      'keeps latest timestamp when duplicate addresses appear unsorted',
      () async {
        final repository = CatchAllRepository(
          analyticsRepository: FakeAnalyticsRepository(
            logs: [
              ActivityLogEntry(
                address: 'sales@example.com',
                status: 'forwarded',
                spf: 'pass',
                dkim: 'pass',
                dmarc: 'pass',
                timestamp: _earlierTimestamp,
              ),
              ActivityLogEntry(
                address: 'sales@example.com',
                status: 'forwarded',
                spf: 'pass',
                dkim: 'pass',
                dmarc: 'pass',
                timestamp: _timestamp,
              ),
            ],
          ),
          aliasRepository: FakeAliasRepository(),
        );

        final result = await repository.listDetectedAddresses(
          zoneId: 'zone-1',
          domainName: 'example.com',
        );

        expect(result, hasLength(1));
        expect(
          result.single.lastSeenLabel,
          'Last seen 2026-03-09T10:15:00.000Z',
        );
      },
    );
  });
}

final _timestamp = DateTime.utc(2026, 3, 9, 10, 15);
final _earlierTimestamp = DateTime.utc(2026, 3, 9, 9, 0);

class FakeAnalyticsRepository implements AnalyticsRepositoryContract {
  const FakeAnalyticsRepository({this.logs = const [], this.error});

  final List<ActivityLogEntry> logs;
  final Exception? error;

  @override
  Future<ActivityLogPage> listActivityLogs({
    required String zoneId,
    int limit = 20,
    DateTime? before,
  }) async {
    if (error != null) {
      throw error!;
    }

    return ActivityLogPage(
      entries: List<ActivityLogEntry>.unmodifiable(logs),
      hasMore: false,
      nextBefore: null,
    );
  }
}

class FakeAliasRepository implements AliasRepositoryContract {
  FakeAliasRepository({this.aliases = const []});

  final List<AliasModel> aliases;

  @override
  Future<List<AliasModel>> listAliases({required String zoneId}) async =>
      List<AliasModel>.unmodifiable(aliases);

  @override
  Future<AliasModel> createAlias({
    required String zoneId,
    required String aliasAddress,
    String? destination,
    String actionType = 'forward',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAlias({required String zoneId, required String ruleId}) {
    throw UnimplementedError();
  }

  @override
  Future<AliasModel> updateAlias({
    required String zoneId,
    required String ruleId,
    required String aliasAddress,
    String? destination,
    required bool isEnabled,
    String actionType = 'forward',
  }) {
    throw UnimplementedError();
  }
}
