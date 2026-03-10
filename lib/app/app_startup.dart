import 'package:bariskode_cf_email/core/constants/app_routes.dart';
import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/auth/domain/repositories/auth_repository.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_context.dart';
import 'package:bariskode_cf_email/shared/utils/session_resolution.dart';
import 'package:flutter/material.dart';

class AppStartup extends StatefulWidget {
  const AppStartup({
    super.key,
    required this.authRepository,
    required this.domainContext,
  });

  final AuthRepository authRepository;
  final DomainContext domainContext;

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _resolveStartupRoute();
  }

  Future<void> _resolveStartupRoute() async {
    setState(() {
      _errorMessage = null;
    });

    var hasSession = false;
    late SessionResolution resolution;

    try {
      resolution = await resolveSession(
        authRepository: widget.authRepository,
        domainContext: widget.domainContext,
      );
    } on AuthFailure catch (failure) {
      if (failure.type == AuthFailureType.network) {
        if (!mounted) {
          return;
        }

        setState(() {
          _errorMessage = AppStrings.authStartupError;
        });
        return;
      }

      hasSession = false;
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = AppStrings.authStartupError;
      });
      return;
    }

    if (!mounted) {
      return;
    }

    hasSession = resolution.hasValidSession;

    if (!hasSession && resolution.hadStoredToken) {
      widget.domainContext.clearSelection();
    }

    if (resolution.shouldInvalidateSession) {
      try {
        await widget.authRepository.logout();
      } catch (_) {}
      widget.domainContext.clearSelection();
      hasSession = false;
    }

    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushReplacementNamed(hasSession ? AppRoutes.shell : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _errorMessage == null
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(AppStrings.authCheckingSession),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _resolveStartupRoute,
                      child: const Text(AppStrings.retryButton),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
