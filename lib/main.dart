import 'dart:async';

import 'package:document_companion/config/route_generator.dart';
import 'package:document_companion/modules/home/view/homepage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'config/custom_key.dart';
import 'config/custom_theme.dart';
import 'generated/l10n.dart';
import 'local_database/document_file_store.dart';
import 'modules/home/services/ad_service.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  await documentFileStore.init();
  await CustomTheme().load();
  await adService.loadState();

  // Ads are initialised in the background so they never delay startup.
  unawaited(
    MobileAds.instance.initialize().then((_) {
      if (!adService.adsDisabled) adService.preloadAds();
    }),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final CustomTheme currentTheme;

  @override
  void initState() {
    super.initState();
    currentTheme = CustomTheme();
    currentTheme.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    currentTheme.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: CustomTheme.lightTheme,
      darkTheme: CustomTheme.darkTheme,
      themeMode: currentTheme.currentTheme,
      initialRoute: Homepage.route,
      navigatorKey: CustomKey.navigatorKey,
      scaffoldMessengerKey: CustomKey.scaffoldMessengerKey,
      supportedLocales: AppLocalizationDelegate().supportedLocales,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
