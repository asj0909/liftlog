import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/widgets/error_snack_bar.dart';
import '../application/auth_providers.dart';
import '../domain/credentials_validator.dart';

/// S-01 ログイン。ログイン成功後の画面遷移は router の認証ガードが行う。
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _email => _emailController.text.trim();
  String get _password => _passwordController.text;

  Future<void> _run(Future<void> Function() action, {String? successMessage}) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await action();
      if (successMessage != null) _showMessage(successMessage);
    } on AppException catch (e) {
      _showMessage(snackBarMessageOf(e), duration: snackBarDurationOf(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: duration));
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(authRepositoryProvider);
    await _run(() => repo.signIn(email: _email, password: _password));
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(authRepositoryProvider);
    await _run(() async {
      await repo.signUp(email: _email, password: _password);
      // メール確認が有効な環境ではここではまだログインしていない
      if (repo.currentUser == null) {
        _showMessage('確認メールを送信しました。メール内のリンクから登録を完了してください。');
      }
    });
  }

  Future<void> _resetPassword() async {
    final emailError = CredentialsValidator.email(_email);
    if (emailError != null) {
      _showMessage(emailError);
      return;
    }
    final repo = ref.read(authRepositoryProvider);
    await _run(
      () => repo.sendPasswordReset(email: _email),
      successMessage: 'パスワード再設定用のメールを送信しました',
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('LiftLog', style: textTheme.headlineMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  TextFormField(
                    key: const Key('login_email'),
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'メールアドレス'),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    validator: CredentialsValidator.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('login_password'),
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'パスワード'),
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _signIn(),
                    validator: CredentialsValidator.password,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('login_submit'),
                    onPressed: _submitting ? null : _signIn,
                    child: _submitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('ログイン'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    key: const Key('login_signup'),
                    onPressed: _submitting ? null : _signUp,
                    child: const Text('新規登録'),
                  ),
                  TextButton(
                    onPressed: _submitting ? null : _resetPassword,
                    child: const Text('パスワードを忘れた方'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
