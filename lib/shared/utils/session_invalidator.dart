import 'package:bariskode_cf_email/core/constants/app_routes.dart';
import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/features/auth/domain/repositories/auth_repository.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_context.dart';
import 'package:flutter/material.dart';

class SessionInvalidationResult {
  const SessionInvalidationResult({required this.didClearStoredSession});

  final bool didClearStoredSession;
}

Future<SessionInvalidationResult> invalidateSession({
  required AuthRepository authRepository,
  required DomainContext domainContext,
}) async {
  var didClearStoredSession = true;

  try {
    await authRepository.logout();
  } catch (_) {
    didClearStoredSession = false;
  }

  final didClearPersistedSelection = await domainContext
      .clearSelectionAndWait();

  return SessionInvalidationResult(
    didClearStoredSession: didClearStoredSession && didClearPersistedSelection,
  );
}

Future<bool> invalidateSessionAndReturnToLogin({
  required BuildContext context,
  required AuthRepository authRepository,
  required DomainContext domainContext,
}) async {
  final result = await invalidateSession(
    authRepository: authRepository,
    domainContext: domainContext,
  );

  if (!context.mounted) {
    return false;
  }

  if (!result.didClearStoredSession) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.authSessionCleanupError)),
    );
    return false;
  }

  Navigator.of(
    context,
  ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);

  return true;
}
