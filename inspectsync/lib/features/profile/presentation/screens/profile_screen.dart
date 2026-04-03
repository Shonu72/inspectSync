import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inspectsync/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:inspectsync/features/auth/presentation/bloc/auth_state.dart';
import 'package:inspectsync/core/theme/theme_cubit.dart';
import 'package:inspectsync/core/security/security_cubit.dart';
import 'package:inspectsync/features/sync/presentation/providers/sync_controller.dart';
import 'package:inspectsync/core/di/injection_container.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final syncController = sl<SyncController>();

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;
        final name = user?.name ?? 'Alex Johnson';
        final role = user?.role ?? 'Senior Field Engineer';

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.primary),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Engineer Profile',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.settings, color: colorScheme.primary),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Top Card (unchanged)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                              image: const DecorationImage(
                                image: NetworkImage('https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&q=80&w=200&h=200'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -5,
                            right: -5,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.verified, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        role,
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 8),
                            const Text(
                              'MEMBER SINCE JAN 2022',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _buildSectionHeader(context, 'APP PREFERENCES'),
                BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, themeMode) {
                    return _buildSettingTile(
                      context,
                      icon: Icons.dark_mode,
                      title: 'Appearance',
                      subtitle: 'Switch between Light and Dark',
                      trailing: Switch(
                        value: themeMode == ThemeMode.dark,
                        onChanged: (v) => context.read<ThemeCubit>().toggleTheme(v),
                      ),
                    );
                  },
                ),
                _buildSettingTile(
                  context,
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: 'English (United States)',
                  trailing: const Icon(Icons.chevron_right),
                ),
                ListenableBuilder(
                  listenable: syncController,
                  builder: (context, _) {
                    return _buildSettingTile(
                      context,
                      icon: Icons.cloud_off,
                      title: 'Offline Mode',
                      subtitle: 'Force local data storage only',
                      trailing: Switch(
                        value: syncController.isManualOffline,
                        onChanged: (v) => syncController.setManualOffline(v),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),
                _buildSectionHeader(context, 'SECURITY & ACCESS'),
                _buildSettingTile(
                  context,
                  icon: Icons.lock,
                  title: 'Change Password',
                  subtitle: 'Update your login credentials',
                  trailing: const Icon(Icons.chevron_right),
                ),
                BlocBuilder<SecurityCubit, SecurityState>(
                  builder: (context, state) {
                    return _buildSettingTile(
                      context,
                      icon: Icons.fingerprint,
                      title: 'Biometric Login',
                      subtitle: state.isBiometricSupported 
                          ? 'FaceID or Fingerprint access'
                          : 'Biometrics not supported on this device',
                      trailing: Switch(
                        value: state.isBiometricEnabled,
                        onChanged: state.isBiometricSupported 
                            ? (v) => context.read<SecurityCubit>().toggleBiometrics(v)
                            : null,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),
                _buildSectionHeader(context, 'ACCOUNT'),
                _buildSettingTile(
                  context,
                  icon: Icons.exit_to_app,
                  title: 'Logout',
                  subtitle: 'Exit your current session',
                  titleColor: colorScheme.primary,
                  iconColor: colorScheme.primary,
                  onTap: () => _showConfirmationDialog(
                    context,
                    title: 'Logout',
                    message: 'Are you sure you want to log out of your session?',
                    confirmLabel: 'LOGOUT',
                    isDestructive: false,
                    onConfirm: () => context.read<AuthCubit>().logout(),
                  ),
                ),
                _buildSettingTile(
                  context,
                  icon: Icons.delete_forever,
                  title: 'Delete Account',
                  subtitle: 'Permanently remove profile data',
                  titleColor: colorScheme.error,
                  iconColor: colorScheme.error,
                  onTap: () => _showConfirmationDialog(
                    context,
                    title: 'Delete Account',
                    message: 'This action is permanent and cannot be undone. All your local data will be lost.',
                    confirmLabel: 'DELETE',
                    isDestructive: true,
                    onConfirm: () {
                      // Logic for delete will go here
                    },
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required bool isDestructive,
    required VoidCallback onConfirm,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? colorScheme.error : colorScheme.primary,
              foregroundColor: isDestructive ? colorScheme.onError : colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              confirmLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? titleColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? colorScheme.onSurfaceVariant, size: 20),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: trailing,
      ),
    );
  }
}
