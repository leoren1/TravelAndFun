import 'package:explore_index/app.dart';
import 'package:explore_index/data/providers.dart';
import 'package:explore_index/data/services/local_storage_service.dart';
import 'package:explore_index/domain/usecases/seed_demo_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await LocalStorageService.registerAdapters();
  await LocalStorageService.openBoxes();

  final storage = LocalStorageService();
  final container = ProviderContainer();
  await SeedDemoData(
    visitRepo: container.read(visitRepositoryProvider),
    storage: storage,
  ).execute();
  container.dispose();

  runApp(
    const ProviderScope(
      child: ExploreIndexApp(),
    ),
  );
}
