// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:darawalkaab/main.dart';
import 'package:darawalkaab/providers/settings_provider.dart';
import 'package:darawalkaab/providers/user_provider.dart';
import 'package:darawalkaab/providers/social_provider.dart';
import 'package:darawalkaab/providers/favorites_provider.dart';
import 'package:darawalkaab/screens/welcome_screen.dart';

void main() {
  setUpAll(() async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Initialize Supabase client
    await Supabase.initialize(
      url: 'https://lroliomhhjkjjczrtmph.supabase.co',
      anonKey: 'sb_publishable_1h0tF13PS3hoOY5EJ5IThw_4VRcLCQg',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
      ),
    );
  });

  testWidgets('WelcomeScreen renders on initial launch smoke test', (WidgetTester tester) async {
    // Build our app wrapped in providers.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => SocialProvider()),
          ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the WelcomeScreen is rendered.
    expect(find.byType(WelcomeScreen), findsOneWidget);

    // Settle any animations
    await tester.pumpAndSettle();
  });
}
