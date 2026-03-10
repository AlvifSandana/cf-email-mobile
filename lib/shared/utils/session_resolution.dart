import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/auth/domain/repositories/auth_repository.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_context.dart';

class SessionResolution {
  const SessionResolution({
    required this.hasValidSession,
    required this.hadStoredToken,
    required this.shouldInvalidateSession,
  });

  final bool hasValidSession;
  final bool hadStoredToken;
  final bool shouldInvalidateSession;
}

Future<SessionResolution> resolveSession({
  required AuthRepository authRepository,
  required DomainContext domainContext,
  bool ensureDomainAccess = true,
}) async {
  var hadStoredToken = false;

  try {
    final token = await authRepository.readToken();
    hadStoredToken = token != null && token.trim().isNotEmpty;
  } catch (_) {}

  final hasValidSession = await authRepository.hasValidSession();
  if (!hasValidSession) {
    return SessionResolution(
      hasValidSession: false,
      hadStoredToken: hadStoredToken,
      shouldInvalidateSession: false,
    );
  }

  final shouldCheckDomainAccess =
      ensureDomainAccess &&
      domainContext.domains.isEmpty &&
      domainContext.selectedDomain == null &&
      domainContext.errorMessage == null &&
      domainContext.authFailure == null;

  if (!shouldCheckDomainAccess) {
    return SessionResolution(
      hasValidSession: true,
      hadStoredToken: hadStoredToken,
      shouldInvalidateSession: false,
    );
  }

  await domainContext.loadDomains();
  final authFailure = domainContext.authFailure;
  final shouldInvalidateSession =
      authFailure?.type == AuthFailureType.invalidToken ||
      authFailure?.type == AuthFailureType.insufficientPermissions;

  return SessionResolution(
    hasValidSession: !shouldInvalidateSession,
    hadStoredToken: hadStoredToken,
    shouldInvalidateSession: shouldInvalidateSession,
  );
}
