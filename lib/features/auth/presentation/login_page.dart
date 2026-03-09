import 'package:bariskode_cf_email/core/constants/app_routes.dart';
import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/features/auth/domain/repositories/auth_repository.dart';
import 'package:bariskode_cf_email/features/auth/presentation/auth_controller.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final AuthController _controller;
  final TextEditingController _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AuthController(authRepository: widget.authRepository);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final success = await _controller.submit(_tokenController.text);

    if (!mounted || !success) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.shell, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.loginTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.loginDescription,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _tokenController,
                    enabled: !_controller.isLoading,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    keyboardType: TextInputType.visiblePassword,
                    maxLines: 1,
                    onChanged: (_) => _controller.clearError(),
                    decoration: InputDecoration(
                      labelText: AppStrings.apiTokenLabel,
                      hintText: AppStrings.apiTokenHint,
                      border: const OutlineInputBorder(),
                      errorText: _controller.errorMessage,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _controller.isLoading ? null : _submit,
                    child: _controller.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AppStrings.loginButton),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
