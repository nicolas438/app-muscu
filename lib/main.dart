import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/providers.dart';
import 'screens/screens.dart';
import 'services/services.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Stockage local (Hive) : doit être prêt avant le premier écran.
  await StorageService().init();

  // Noms des jours et des mois en français.
  await initializeDateFormatting('fr_FR', null);

  // Barres système claires, assorties au fond « craie ».
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const AppNuno());
}

class AppNuno extends StatelessWidget {
  const AppNuno({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkoutProvider()..loadAll()),
        // Restaure une éventuelle séance interrompue (application fermée en cours d'entraînement).
        ChangeNotifierProvider(create: (_) => ActiveWorkoutProvider()..restoreActiveWorkout()),
      ],
      child: MaterialApp(
        title: 'AppNuno',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeScreen(),
      ),
    );
  }
}
