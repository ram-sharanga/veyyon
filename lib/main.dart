import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/dependency_injection/injection_container.dart' as di;

Future<void> main() async {
  // Ensure Flutter engine is initialized
  // before any platform channel calls
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file from assets
  // so dotenv.env['SUPABASE_URL'] works anywhere in the app.
  await dotenv.load(fileName: '.env');

  // Initialize Supabase.
  // must complete before runApp as it establishes the connection,
  // restores any existing session from local storage, and
  // sets up the auth state stream.
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      // PKCE = Proof Key for Code Exchange.
      // The alternative (implicit flow) puts the access token in the URL
      // fragment - a security vulnerability.
      authFlowType: AuthFlowType.pkce,
      // autoRefreshToken = true means the SDK will automatically refresh
      // your access token before it expires. No need for manual management.
      autoRefreshToken: true,
    ),
  );

  // Register all dependencies.
  // Supabase is now ready, so we can register the client instance.
  await di.initDependencies();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Veyyon'))),
    );
  }
}
