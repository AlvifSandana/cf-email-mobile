import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/auth/domain/repositories/auth_repository.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_context.dart';
import 'package:bariskode_cf_email/shared/utils/session_invalidator.dart';
import 'package:flutter/material.dart';

class DomainSelectorPage extends StatefulWidget {
  const DomainSelectorPage({
    super.key,
    required this.domainContext,
    required this.authRepository,
  });

  final DomainContext domainContext;
  final AuthRepository authRepository;

  @override
  State<DomainSelectorPage> createState() => _DomainSelectorPageState();
}

class _DomainSelectorPageState extends State<DomainSelectorPage> {
  @override
  void initState() {
    super.initState();

    if (widget.domainContext.domains.isEmpty &&
        !widget.domainContext.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDomains();
      });
    }
  }

  Future<void> _loadDomains() async {
    await widget.domainContext.loadDomains();

    final failure = widget.domainContext.authFailure;
    if (failure == null || !mounted) {
      return;
    }

    await _handleAuthFailure(failure);
  }

  Future<void> _handleAuthFailure(AuthFailure failure) async {
    if (failure.type != AuthFailureType.invalidToken &&
        failure.type != AuthFailureType.insufficientPermissions) {
      return;
    }

    await invalidateSessionAndReturnToLogin(
      context: context,
      authRepository: widget.authRepository,
      domainContext: widget.domainContext,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.domainSelectorTitle)),
      body: AnimatedBuilder(
        animation: widget.domainContext,
        builder: (context, _) {
          if (widget.domainContext.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.domainContext.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.domainContext.errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loadDomains,
                      child: const Text(AppStrings.retryButton),
                    ),
                  ],
                ),
              ),
            );
          }

          if (widget.domainContext.domains.isEmpty) {
            return const Center(child: Text(AppStrings.domainEmptyState));
          }

          return ListView.builder(
            itemCount: widget.domainContext.domains.length,
            itemBuilder: (context, index) {
              final domain = widget.domainContext.domains[index];
              final isSelected =
                  widget.domainContext.selectedDomain?.id == domain.id;

              return ListTile(
                title: Text(domain.name),
                trailing: isSelected ? const Icon(Icons.check_circle) : null,
                onTap: () {
                  widget.domainContext.selectDomain(domain);
                  Navigator.of(context).pop();
                },
              );
            },
          );
        },
      ),
    );
  }
}
