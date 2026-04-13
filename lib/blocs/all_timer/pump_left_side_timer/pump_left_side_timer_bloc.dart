import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:open_baby_sara/data/repositories/locator.dart';
import 'package:open_baby_sara/data/repositories/timer_repository.dart';
import 'package:meta/meta.dart';

part 'pump_left_side_timer_event.dart';
part 'pump_left_side_timer_state.dart';

class PumpLeftSideTimerBloc
    extends Bloc<PumpLeftSideTimerEvent, PumpLeftSideTimerState> {
  final TimerRepository _timerRepository = getIt<TimerRepository>();

  Timer? _timer;
  Duration _duration = Duration.zero;
  DateTime? _startTime;
  DateTime? _endTime;
  PumpLeftSideTimerBloc() : super(PumpLeftSideTimerInitial()) {
    on<PumpLeftSideTimerEvent>((event, emit) {
      // TODO: implement event handler
    });
    on<StartTimer>((event, emit) {
      _timer?.cancel();
      _startTime ??= DateTime.now();
      _timerRepository.saveTimerStart(_startTime!, event.activityType);

      _duration = Duration.zero;
      _timer = Timer.periodic(Duration(seconds: 1), (_) {
        if (!isClosed) {
          add(Tick(activityType: event.activityType));
        }
      });
      emit(
        TimerRunning(
          duration: _duration,
          startTime: _startTime,
          activityType: event.activityType,
        ),
      );
    });

    on<Tick>((event, emit) {
      if (_startTime != null) {
        _duration = DateTime.now().difference(_startTime!);
      }
      emit(
        TimerRunning(
          duration: _duration,
          startTime: _startTime,
          activityType: event.activityType,
        ),
      );
    });

    on<SetStartTimeTimer>((event, emit) {
      _timer?.cancel();
      _startTime = event.startTime;

      if (_startTime != null && _endTime != null) {
        _duration = _endTime!.difference(_startTime!);
        if (_duration.isNegative) _duration = Duration.zero;
      } else {
        _duration = Duration.zero;
      }

      emit(
        TimerStopped(
          duration: _duration,
          startTime: _startTime,
          activityType: event.activityType,
          endTime: _endTime,
        ),
      );
    });

    on<StopTimer>((event, emit) async {
      _timer?.cancel();
      _timer = null;

      _endTime = DateTime.now();

      if (_startTime != null) {
        _duration = _endTime!.difference(_startTime!);
      }
      await _timerRepository.stopTimer(event.activityType);

      emit(
        TimerStopped(
          duration: _duration,
          endTime: _endTime,
          activityType: event.activityType,
        ),
      );
    });
    on<SetEndTimeTimer>((event, emit) {
      // Stop timer if running
      _timer?.cancel();
      
      _endTime = event.endTime;
      
      // If start time exists in event, use it (user manually selected it)
      // Otherwise keep current start time
      if (event.startTime != null) {
        _startTime = event.startTime;
      }

      if (_startTime != null && _endTime != null) {
        // Use full DateTime difference calculation (handles midnight crossing)
        _duration = _endTime!.difference(_startTime!);
      } else {
        _duration = Duration.zero;
      }

      emit(
        TimerStopped(
          duration: _duration,
          endTime: _endTime,
          startTime: _startTime,
          activityType: event.activityType,
        ),
      );
    });
    on<SetDurationTimer>((event, emit) {
      _endTime ??= DateTime.now();
      _startTime = _endTime!.subtract(event.duration);

      emit(
        TimerStopped(
          duration: event.duration,
          activityType: event.activityType,
          endTime: _endTime,
          startTime: _startTime,
        ),
      );
    });

    on<ResetTimer>((event, emit) async {
      _timer?.cancel(); // Stop the timer
      _timer = null;
      _duration = Duration.zero;
      _startTime = null;
      _endTime = null;

      await _timerRepository.clearTimer(event.activityType);

      emit(TimerReset());
    });

    on<LoadTimerFromLocalDatabase>((event, emit) async {
      _timer?.cancel();
      final data = await _timerRepository.loadTimer(event.activityType);
      if (data != null && data['isRunning'] == 1) {
        final getTime = DateTime.parse(data['startTime']);

        _startTime = DateTime(
          getTime.year,
          getTime.month,
          getTime.day,
          getTime.hour,
          getTime.minute,
          getTime.second,
        );
        _endTime = null;
        _duration = DateTime.now().difference(getTime);

        _timer = Timer.periodic(Duration(seconds: 1), (_) {
          add(Tick(activityType: event.activityType));
        });
        emit(
          TimerRunning(
            duration: _duration,
            startTime: _startTime,
            activityType: event.activityType,
          ),
        );
      } else {
        emit(PumpLeftSideTimerInitial());
      }
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
