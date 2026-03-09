import 'package:bariskode_cf_email/features/catchall/domain/entities/catchall_entry.dart';

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
