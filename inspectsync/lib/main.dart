import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/db/app_database.dart';
import 'core/di/injection_container.dart' as di;
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/security/security_cubit.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/sync/presentation/providers/sync_controller.dart';
import 'features/tasks/data/task_repository.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await di.init();

  final authCubit = sl<AuthCubit>();
  await authCubit.checkStatus();

  final syncController = sl<SyncController>();
  final taskRepository = sl<TaskRepository>();
  final db = sl<AppDatabase>();
  final themeCubit = sl<ThemeCubit>();
  final securityCubit = sl<SecurityCubit>();

  final router = AppRouter.createRouter(authCubit, syncController, db);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authCubit),
        BlocProvider.value(value: themeCubit),
        BlocProvider.value(value: securityCubit),
      ],
      child: MyApp(router: router, taskRepository: taskRepository),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  final TaskRepository taskRepository;

  const MyApp({super.key, required this.router, required this.taskRepository});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp.router(
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          title: 'InspectSync Pro',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
    );
  }
}

