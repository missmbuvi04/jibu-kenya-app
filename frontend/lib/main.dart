import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const bool forceFreshStart = false;
  if (forceFreshStart) {
    await const FlutterSecureStorage().deleteAll();
  }

  runApp(
    const ProviderScope(
      child: JibuKenyaApp(),
    ),
  );
}