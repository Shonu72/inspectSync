import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityState {
  final bool isBiometricEnabled;
  final bool isBiometricSupported;

  SecurityState({
    required this.isBiometricEnabled,
    required this.isBiometricSupported,
  });

  SecurityState copyWith({
    bool? isBiometricEnabled,
    bool? isBiometricSupported,
  }) {
    return SecurityState(
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isBiometricSupported: isBiometricSupported ?? this.isBiometricSupported,
    );
  }
}

class SecurityCubit extends Cubit<SecurityState> {
  final SharedPreferences _prefs;
  final LocalAuthentication _auth = LocalAuthentication();
  static const String _biometricKey = 'biometric_enabled';

  SecurityCubit(this._prefs)
    : super(
        SecurityState(
          isBiometricEnabled: _prefs.getBool(_biometricKey) ?? false,
          isBiometricSupported: false,
        ),
      ) {
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    final isSupported =
        await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    emit(state.copyWith(isBiometricSupported: isSupported));
  }

  Future<void> toggleBiometrics(bool enabled) async {
    if (enabled && !state.isBiometricSupported) return;

    await _prefs.setBool(_biometricKey, enabled);
    emit(state.copyWith(isBiometricEnabled: enabled));
  }
}
