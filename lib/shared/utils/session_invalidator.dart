import 'package:bariskode_cf_email/core/constants/app_routes.dart';
import 'package:bariskode_cf_email/features/auth/domain/repositories/auth_repository.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_context.dart';
import 'package:flutter/material.dart';

Future<void> invalidateSessionAndReturnToLogin({
  required BuildContext context,
  required AuthRepository authRepository,
  required DomainContext domainContext,
}) async {
  try {
    await authRepository.logout();
  } catch (_) {}

  domainContext.clearSelection();

  if (!context.mounted) {
    return;
  }

  Navigator.of(
    context,
  ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
}
