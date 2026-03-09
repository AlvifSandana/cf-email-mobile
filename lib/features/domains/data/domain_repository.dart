import 'package:bariskode_cf_email/core/network/api_client.dart';
import 'package:bariskode_cf_email/core/network/cloudflare_auth_api.dart';
import 'package:bariskode_cf_email/features/domains/domain/entities/domain_summary.dart';

class DomainRepository implements DomainRepositoryContract {
  const DomainRepository({required this.apiClient, required this.authApi});

  final ApiClient apiClient;
  final CloudflareAuthApi authApi;

  @override
  Future<List<DomainSummary>> listDomains() {
    return authApi.fetchZones(apiClient);
  }
}

abstract class DomainRepositoryContract {
  Future<List<DomainSummary>> listDomains();
}
