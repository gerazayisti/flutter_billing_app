import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/data/hive_database.dart';

// Events
abstract class LocaleEvent extends Equatable {
  const LocaleEvent();
  @override
  List<Object?> get props => [];
}

class ChangeLocaleEvent extends LocaleEvent {
  final Locale locale;
  const ChangeLocaleEvent(this.locale);
  @override
  List<Object?> get props => [locale];
}

class LoadLocaleEvent extends LocaleEvent {}

// State
class LocaleState extends Equatable {
  final Locale locale;
  const LocaleState(this.locale);
  @override
  List<Object?> get props => [locale];
}

// Bloc
class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  LocaleBloc() : super(const LocaleState(Locale('fr'))) {
    on<LoadLocaleEvent>(_onLoadLocale);
    on<ChangeLocaleEvent>(_onChangeLocale);
  }

  void _onLoadLocale(LoadLocaleEvent event, Emitter<LocaleState> emit) {
    final String? languageCode = HiveDatabase.settingsBox.get('languageCode');
    if (languageCode != null) {
      emit(LocaleState(Locale(languageCode)));
    } else {
      // Default to French as initial requirement, but main.dart will handle auto-detection
      emit(const LocaleState(Locale('fr')));
    }
  }

  Future<void> _onChangeLocale(ChangeLocaleEvent event, Emitter<LocaleState> emit) async {
    await HiveDatabase.settingsBox.put('languageCode', event.locale.languageCode);
    emit(LocaleState(event.locale));
  }
}
