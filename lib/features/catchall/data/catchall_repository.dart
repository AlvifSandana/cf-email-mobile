import 'package:bariskode_cf_email/features/catchall/domain/entities/catchall_entry.dart';
import 'package:bariskode_cf_email/features/aliases/data/alias_repository.dart';
import 'package:bariskode_cf_email/features/analytics/data/analytics_repository.dart';

abstract class CatchAllRepositoryContract {
  Future<List<CatchAllEntry>> listDetectedAddresses({
    required String zoneId,
    required String domainName,
  });
}

class EmptyCatchAllRepository implements CatchAllRepositoryContract {
  const EmptyCatchAllRepository();

  @override
  Future<List<CatchAllEntry>> listDetectedAddresses({
    required String zoneId,
    required String domainName,
  }) async => const [];
}

class CatchAllRepository implements CatchAllRepositoryContract {
  const CatchAllRepository({
    required this.analyticsRepository,
    required this.aliasRepository,
  });

  final AnalyticsRepositoryContract analyticsRepository;
  final AliasRepositoryContract aliasRepository;

  @override
  Future<List<CatchAllEntry>> listDetectedAddresses({
    required String zoneId,
    required String domainName,
  }) async {
    final logsPage = await analyticsRepository.listActivityLogs(zoneId: zoneId);
    final logs = logsPage.entries;
    final aliases = await aliasRepository.listAliases(zoneId: zoneId);
    final existingAddresses = aliases
        .map((alias) => alias.address.toLowerCase())
        .toSet();
    final suffix = '@${domainName.toLowerCase()}';
    final Map<String, CatchAllEntry> uniqueEntries = <String, CatchAllEntry>{};
    final Map<String, DateTime> latestSeenByAddress = <String, DateTime>{};

    for (final log in logs) {
      final address = log.address.toLowerCase();
      if (!address.endsWith(suffix) || existingAddresses.contains(address)) {
        continue;
      }

      final currentLatest = latestSeenByAddress[address];
      if (currentLatest != null && !log.timestamp.isAfter(currentLatest)) {
        continue;
      }

      latestSeenByAddress[address] = log.timestamp;
      uniqueEntries[address] = CatchAllEntry(
        address: address,
        lastSeenLabel: _formatLastSeen(log.timestamp),
      );
    }

    final sortedEntries = uniqueEntries.values.toList(growable: false)
      ..sort((a, b) {
        final left =
            latestSeenByAddress[a.address] ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final right =
            latestSeenByAddress[b.address] ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });

    return List<CatchAllEntry>.unmodifiable(sortedEntries);
  }

  String _formatLastSeen(DateTime timestamp) {
    final utcTimestamp = timestamp.toUtc();
    final safeTimestamp =
        utcTimestamp.second == 0 && utcTimestamp.millisecond == 0
        ? utcTimestamp
        : DateTime.utc(
            utcTimestamp.year,
            utcTimestamp.month,
            utcTimestamp.day,
            utcTimestamp.hour,
            utcTimestamp.minute,
          );
    return 'Last seen ${safeTimestamp.toIso8601String()}';
  }
}
