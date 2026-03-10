import 'package:bariskode_cf_email/app/app.dart';
import 'package:bariskode_cf_email/core/network/api_client.dart';
import 'package:bariskode_cf_email/core/network/auth_header_provider.dart';
import 'package:bariskode_cf_email/core/network/cloudflare_auth_api.dart';
import 'package:bariskode_cf_email/features/analytics/data/analytics_repository.dart';
import 'package:bariskode_cf_email/features/aliases/data/alias_repository.dart';
import 'package:bariskode_cf_email/features/auth/data/auth_repository_impl.dart';
import 'package:bariskode_cf_email/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:bariskode_cf_email/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bariskode_cf_email/features/catchall/data/catchall_repository.dart';
import 'package:bariskode_cf_email/features/destinations/data/destination_repository.dart';
import 'package:bariskode_cf_email/features/domains/data/domain_repository.dart';
import 'package:bariskode_cf_email/features/domains/data/selected_domain_store.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_context.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

void main() {
  final httpClient = http.Client();
  const secureStorage = FlutterSecureStorage();
  final localDataSource = AuthLocalDataSource(secureStorage);
  final apiClient = ApiClient(
    client: httpClient,
    headers: AuthHeaderProvider(localDataSource),
  );
  final authApi = CloudflareAuthApi(client: httpClient);
  final remoteDataSource = AuthRemoteDataSource(
    authApi: authApi,
    apiClient: apiClient,
  );
  final authRepository = AuthRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
  final domainRepository = DomainRepository(
    apiClient: apiClient,
    authApi: authApi,
  );
  final analyticsRepository = AnalyticsRepository(apiClient: apiClient);
  final aliasRepository = AliasRepository(apiClient: apiClient);
  final destinationRepository = DestinationRepository(apiClient: apiClient);
  final catchAllRepository = CatchAllRepository(
    analyticsRepository: analyticsRepository,
    aliasRepository: aliasRepository,
  );
  final domainContext = DomainContext(
    repository: domainRepository,
    selectedDomainStore: SelectedDomainStore(secureStorage),
  );

  runApp(
    BariskodeCfEmailApp(
      authRepository: authRepository,
      domainContext: domainContext,
      aliasRepository: aliasRepository,
      catchAllRepository: catchAllRepository,
      analyticsRepository: analyticsRepository,
      destinationRepository: destinationRepository,
    ),
  );
}
