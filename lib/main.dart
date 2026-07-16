import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_screen.dart';
import 'screens/suspended_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'providers/settings_provider.dart';
import 'providers/user_provider.dart';
import 'providers/social_provider.dart';
import 'providers/favorites_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:darawalkaab/l10n/app_localizations.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  await NotificationService().requestPermissions();
  await Supabase.initialize(
    url: 'https://lroliomhhjkjjczrtmph.supabase.co',
    anonKey: 'sb_publishable_1h0tF13PS3hoOY5EJ5IThw_4VRcLCQg',
  );

  runApp(
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
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Tusiye App', // Professional App Name
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          locale: settings.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('so'), Locale('ar')],

          home: Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              if (userProvider.needsPasswordReset) {
                return const ResetPasswordScreen(email: '', isRecovery: true);
              }
              if (userProvider.isAuthenticated) {
                return userProvider.status == 'suspended'
                    ? const SuspendedScreen()
                    : const MainScreen();
              }
              return const WelcomeScreen();
            },
          ),
        );
      },
    );
  }
}
