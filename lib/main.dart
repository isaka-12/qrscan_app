import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:qrscan_app/core/database/database_helper.dart';
import 'package:qrscan_app/core/theme/app_theme.dart';
import 'package:qrscan_app/core/providers/theme_provider.dart';
import 'package:qrscan_app/features/qrscan/data/datasources/qrscan_remote_datasource.dart';
import 'package:qrscan_app/features/qrscan/data/datasources/qrscan_local_datasource.dart';
import 'package:qrscan_app/features/qrscan/data/repositories/qrscan_repository_impl.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/save_scan.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/get_all_scans.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/search_scans.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/clear_all_scans.dart';
import 'package:qrscan_app/features/qrscan/presentation/pages/main_navigation_page.dart';
import 'package:qrscan_app/features/qrscan/presentation/providers/qrscan_provider.dart';
import 'package:qrscan_app/features/qrscan/presentation/widgets/qr_data_display.dart';

void main() {
  // Initialize dependencies
  final client = http.Client();
  final databaseHelper = DatabaseHelper();

  // Data sources
  final remoteDataSource = QrScanRemoteDataSource(client);
  final localDataSource = QrScanLocalDataSource(databaseHelper);

  // Repository
  final repository = QrScanRepositoryImpl(remoteDataSource, localDataSource);

  // Use cases
  final saveScan = SaveScan(repository);
  final getAllScans = GetAllScans(repository);
  final searchScans = SearchScans(repository);
  final clearAllScans = ClearAllScans(repository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              QrScanProvider(saveScan, getAllScans, searchScans, clearAllScans),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: "QR Scanner",
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const MainNavigationPage(),
        );
      },
    );
  }
}
