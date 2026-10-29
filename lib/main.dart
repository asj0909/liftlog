import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
    runApp(
      const _StartupMessageApp(
        'SUPABASE_URL / SUPABASE_ANON_KEY が未設定です。\n'
        'flutter run --dart-define-from-file=env/dev.json で起動してください。',
      ),
    );
    return;
  }

  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      // anonKey は非推奨になったため publishableKey を使う（値は同じ公開用キー）
      publishableKey: Env.supabaseAnonKey,
    );
  } catch (e, stackTrace) {
    // 初期化に失敗するとスプラッシュのまま止まるので、案内画面を出す（基本設計書 7.3）
    debugPrint('Supabase の初期化に失敗: $e\n$stackTrace');
    runApp(
      const _StartupMessageApp(
        '起動に失敗しました。\n通信環境を確認して、アプリを再起動してください。',
      ),
    );
    return;
  }

  runApp(const ProviderScope(child: LiftLogApp()));
}

/// 起動できないときに理由を表示するだけの画面。
class _StartupMessageApp extends StatelessWidget {
  const _StartupMessageApp(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
