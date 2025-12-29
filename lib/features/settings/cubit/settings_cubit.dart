import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/repositories/settings_repository.dart';
import 'package:organista/services/wakelock/wakelock_service.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;
  final WakelockService _wakelockService;

  SettingsCubit(
    this._repository, {
    WakelockService? wakelockService,
  }) : _wakelockService = wakelockService ?? WakelockPlusService(),
       super(
         SettingsState(
           themeModeIndex: _repository.getThemeModeIndex(),
           localeString: _repository.getLocaleString(),
           showNavigationArrows: _repository.getShowNavigationArrows(),
           keepScreenOn: _repository.getKeepScreenOn(),
         ),
       ) {
    // Initialize wakelock based on saved preference
    _initializeWakelock();
  }

  void _initializeWakelock() async {
    try {
      if (state.keepScreenOn) {
        await _wakelockService.enable();
      } else {
        await _wakelockService.disable();
      }
    } catch (e) {
      logger.i("Wakelock initialization failed $e");
      // Handle wakelock errors gracefully (e.g., in tests or unsupported platforms)
    }
  }

  void changeTheme(int themeModeIndex) {
    _repository.saveThemeModeIndex(themeModeIndex);
    emit(state.copyWith(themeModeIndex: themeModeIndex));
  }

  void changeLanguage(String localeString) {
    _repository.saveLocaleString(localeString);
    emit(state.copyWith(localeString: localeString));
  }

  void changeShowNavigationArrows(bool showArrows) {
    _repository.saveShowNavigationArrows(showArrows);
    emit(state.copyWith(showNavigationArrows: showArrows));
  }

  Future<void> changeKeepScreenOn(bool keepScreenOn) async {
    await _repository.saveKeepScreenOn(keepScreenOn);

    // Update wakelock based on the new setting
    try {
      if (keepScreenOn) {
        await _wakelockService.enable();
      } else {
        await _wakelockService.disable();
      }
    } catch (e, stackTrace) {
      logger.e('Error changing keep screen on', error: e, stackTrace: stackTrace);
    }

    emit(state.copyWith(keepScreenOn: keepScreenOn));
  }
}
