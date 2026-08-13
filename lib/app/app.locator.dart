import 'package:get_it/get_it.dart';
import 'package:spella/core/services/app_tab_service.dart';
import 'package:spella/core/services/definition_service.dart';
import 'package:spella/core/services/dictionary_service.dart';
import 'package:spella/core/services/game_engine_service.dart';
import 'package:spella/core/services/haptic_service.dart';
import 'package:spella/core/services/opponent_service.dart';
import 'package:spella/core/services/player_service.dart';
import 'package:spella/core/services/rack_generator_service.dart';
import 'package:spella/core/services/scoring_service.dart';
import 'package:spella/core/services/social_service.dart';
import 'package:stacked_services/stacked_services.dart';

/// Service locator for the app.
///
/// Written by hand rather than generated so the dependency graph is visible in
/// one place. Services that talk to the outside world are registered against
/// their abstract type, which is what lets the Firestore and auth
/// implementations replace the mocks later without touching a view model.
final GetIt locator = GetIt.instance;

/// Registers every dependency. Call once from `main` before `runApp`.
void setupLocator() {
  if (locator.isRegistered<DictionaryService>()) return;

  // Navigation and dialogs - keeps routing and prompts out of the widget tree.
  locator.registerLazySingleton<NavigationService>(() => NavigationService());
  locator.registerLazySingleton<DialogService>(() => DialogService());
  locator.registerLazySingleton<AppTabService>(() => AppTabService());

  // Pure game logic. No platform or network access, fully unit testable.
  locator.registerLazySingleton<DictionaryService>(() => DictionaryService());
  locator.registerLazySingleton<ScoringService>(() => ScoringService());
  locator.registerLazySingleton<RackGeneratorService>(
    () => RackGeneratorService(locator<DictionaryService>()),
  );
  locator.registerLazySingleton<GameEngineService>(
    () => GameEngineService(
      locator<DictionaryService>(),
      locator<RackGeneratorService>(),
      locator<ScoringService>(),
    ),
  );

  // Swappable back ends. Replace the right hand side when the real services
  // land; nothing that depends on them needs to change.
  locator.registerLazySingleton<DefinitionService>(() => FreeDictionaryApiService());
  locator.registerLazySingleton<OpponentService>(
    () => BotOpponentService(locator<DictionaryService>(), locator<ScoringService>()),
  );
  locator.registerLazySingleton<PlayerService>(() => LocalPlayerService());
  locator.registerLazySingleton<SocialService>(() => EmptySocialService());

  // Platform feedback.
  locator.registerLazySingleton<HapticService>(() => HapticService());
}
