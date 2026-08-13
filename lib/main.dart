import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spella/app/app.locator.dart';
import 'package:spella/app/app.router.dart' as router;
import 'package:spella/ui/common/app_palette.dart';
import 'package:spella/ui/common/app_theme.dart';
import 'package:stacked_services/stacked_services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();

  runApp(const SpellaApp());
}

/// Root of the app. Everything below this point is driven by view models.
class SpellaApp extends StatelessWidget {
  const SpellaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spella',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Spella is a dark-first app. The light theme is kept in sync so it can
      // be offered as a setting later, but it is not what ships by default.
      themeMode: ThemeMode.dark,
      // Wrapping here rather than above MaterialApp means the system bars are
      // styled from the theme that actually resolved, so they stay correct if
      // the app is ever switched back to following the system setting.
      builder: (BuildContext context, Widget? child) =>
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: AppTheme.systemOverlay(context.palette),
            child: child ?? const SizedBox.shrink(),
          ),
      // The navigator key and observer let NavigationService drive routing
      // from the view models.
      navigatorKey: StackedService.navigatorKey,
      navigatorObservers: <NavigatorObserver>[StackedService.routeObserver],
      onGenerateRoute: router.onGenerateRoute,
      initialRoute: router.Routes.startup,
    );
  }
}
