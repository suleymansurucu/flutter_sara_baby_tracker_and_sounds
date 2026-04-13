import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:open_baby_sara/data/repositories/locator.dart';
import 'package:open_baby_sara/data/repositories/timer_repository.dart';
import 'package:meta/meta.dart';

part 'sleep_timer_event.dart';

part 'sleep_timer_state.dart';

class SleepTimerBloc extends Bloc<SleepTimerEvent, SleepTimerState> {
  final TimerRepository _timerRepository = getIt<TimerRepository>();

  Timer? _timer;
  Duration _duration = Duration.zero;
  DateTime? _startTime;
  DateTime? _endTime;

  SleepTimerBloc() : super(SleepTimerInitial()) {
    on<SleepTimerEvent>((event, emit) {
      // TODO: implement event handler
    });
    on<StartTimer>((event, emit) {
      _timer?.cancel();
      
      // If timerStart exists in event use it, otherwise if _startTime exists use it, otherwise use current time
      if (event.timerStart != null) {
        _startTime = event.timerStart;
      } else {
        _startTime ??= DateTime.now();
      }
      
      // Save to timer repository
      _timerRepository.saveTimerStart(_startTime!, event.activityType);

      // Initialize duration - calculate if endTime exists, otherwise start from zero
      if (_startTime != null && _endTime != null) {
        _duration = _calculateDuration(_startTime!, _endTime!);
      } else {
        _duration = Duration.zero;
      }

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
      // Stop timer if running
      _timer?.cancel();
      
      _startTime = event.startTime;

      if (_startTime != null) {
        // If endTime exists, calculate duration
        if (_endTime != null) {
          _duration = _calculateDuration(_startTime!, _endTime!);
        } else {
          // If endTime doesn't exist, duration should be zero
          // Duration should not be calculated until user manually selects end time
          _duration = Duration.zero;
        }
      } else {
        _duration = Duration.zero;
      }

      // Don't change endTime - user should select it manually
      // EndTime can remain null, don't automatically set to DateTime.now()

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

      _endTime = DateTime.now();

      if (_startTime != null && _endTime != null) {
        _duration = _calculateDuration(_startTime!, _endTime!);
      }
      await _timerRepository.stopTimer(event.activityType);

      emit(
        TimerStopped(
          duration: _duration,
          startTime: _startTime, // Also emit start time
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
        _duration = _calculateDuration(_startTime!, _endTime!);
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
      // Stop timer if running
      _timer?.cancel();
      
      // If endTime already exists use it, otherwise use current time
      _endTime ??= DateTime.now();

      // Calculate startTime by subtracting duration from endTime
      if (_endTime != null) {
        _startTime = _endTime!.subtract(event.duration);
      } else {
        _startTime = null;
      }

      _duration = event.duration;

      emit(
        TimerStopped(
          duration: _duration,
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
        // Use dated DateTime directly
        final getTime = DateTime.parse(data['startTime']);
        _startTime = getTime;
        _endTime = null;
        
        // Calculate duration from current time to start time
        _duration = DateTime.now().difference(getTime);

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
      } else {
        emit(SleepTimerInitial());
      }
    });
  }

  Duration _calculateDuration(DateTime start, DateTime end) {
    // Calculate difference directly since full DateTime objects are now used
    // If end is before start (crossed midnight), add one day
    if (end.isBefore(start)) {
      // Midnight crossing case - add one day to end
      return end.add(const Duration(days: 1)).difference(start);
    }
    
    return end.difference(start);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  DateTime? _calculateStartTime(DateTime endTime, Duration duration) {
    // Subtract directly since full DateTime is now used
    return endTime.subtract(duration);
  }
}
