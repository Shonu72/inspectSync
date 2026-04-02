// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'InspectSync';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get loginSubtitle => 'Access your field operations dashboard';

  @override
  String get emailAddressLabel => 'EMAIL ADDRESS';

  @override
  String get emailHint => 'name@company.com';

  @override
  String get passwordLabel => 'PASSWORD';

  @override
  String get passwordHint => '••••••••';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get rememberDevice => 'Remember this device';

  @override
  String get loginButton => 'Log In to Dashboard';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get contactAdmin => 'Contact Admin';

  @override
  String get encryptedSyncActive => 'ENCRYPTED SYNC ACTIVE';
}
