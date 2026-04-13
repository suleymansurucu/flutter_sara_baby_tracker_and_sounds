import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_baby_sara/blocs/all_timer/pump_left_side_timer/pump_left_side_timer_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PumpLeftSideTimer extends StatefulWidget {
  final double size;
  final String activityType;

  const PumpLeftSideTimer({
    super.key,
    this.size = 140,
    required this.activityType,
  });

  @override
  State<PumpLeftSideTimer> createState() => _PumpLeftSideTimerState();
}

class _PumpLeftSideTimerState extends State<PumpLeftSideTimer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Timer? _timer;
  Duration _duration = Duration.zero;
  bool _isRunning = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<PumpLeftSideTimerBloc>().add(
      LoadTimerFromLocalDatabase(activityType: widget.activityType),
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 1.0,
      upperBound: 1.05,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed && _isRunning) {
        _animationController.forward();
      }
    });
  }

  void _startTimer() {
    context.read<PumpLeftSideTimerBloc>().add(
      StartTimer(activityType: widget.activityType),
    );
    _isRunning = true;
    _animationController.forward();
  }

  void _stopTimer() {
    context.read<PumpLeftSideTimerBloc>().add(
      StopTimer(activityType: widget.activityType),
    );
    _timer?.cancel();
    _isRunning = false;
    _animationController.stop();
    _animationController.value = 1.0;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.remainder(60).toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<PumpLeftSideTimerBloc>().add(
        LoadTimerFromLocalDatabase(activityType: widget.activityType),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PumpLeftSideTimerBloc, PumpLeftSideTimerState>(
      builder: (context, state) {
        if (state is TimerRunning &&
            state.activityType == widget.activityType) {
          _duration = state.duration;
          _isRunning = true;
          _animationController.forward();
        }
        if (state is TimerStopped &&
            state.activityType == widget.activityType) {
          _duration = state.duration;
          _isRunning = false;
          _animationController.stop();
          _animationController.value = 1.0;
        }
        if (state is TimerReset) {
          _duration = Duration.zero;
          _timer?.cancel();
          _isRunning = false;
          _animationController.stop();
          _animationController.value = 1.0;
        }

        final Color accentColor = const Color(0xFFFFD6E8);
        final Color shadowColor = accentColor.withOpacity(0.3);
        final Color textColor = const Color(0xFF703D57);

        return GestureDetector(
          onTap: () {
            setState(() {
              _isRunning ? _stopTimer() : _startTimer();
            });
          },
          child: Column(
            children: [
              Center(
                child: ScaleTransition(
                  scale: _animationController,
                  child: Container(
                    width: widget.size,
                    height: widget.size * 0.5,
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: accentColor, width: 2),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _formatDuration(_duration),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(6.w),
                    margin: EdgeInsets.only(right: 6.w),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      border: Border.all(color: accentColor),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 20.sp,
                      color: textColor,
                    ),
                  ),
                  Text(
                    _isRunning
                        ? context.tr('tap_to_pause')
                        : context.tr('tap_to_start_2'),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
