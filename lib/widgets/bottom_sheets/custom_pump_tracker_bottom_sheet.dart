import 'package:duration_picker/duration_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_baby_sara/app/routes/navigation_wrapper.dart';
import 'package:open_baby_sara/blocs/activity/activity_bloc.dart';
import 'package:open_baby_sara/blocs/all_timer/pump_left_side_timer/pump_left_side_timer_bloc.dart'
    as pumpLeft;
import 'package:open_baby_sara/blocs/all_timer/pump_right_side_timer/pump_right_side_timer_bloc.dart'
    as pumpRight;
import 'package:open_baby_sara/blocs/all_timer/pump_total_timer/pump_total_timer_bloc.dart'
    as pumpTotal;
import 'package:open_baby_sara/core/app_colors.dart';
import 'package:open_baby_sara/core/utils/shared_prefs_helper.dart';
import 'package:open_baby_sara/data/models/activity_model.dart';
import 'package:open_baby_sara/data/repositories/locator.dart';
import 'package:open_baby_sara/data/services/firebase/analytics_service.dart';
import 'package:open_baby_sara/widgets/all_timers/pump_left_side_timer.dart';
import 'package:open_baby_sara/widgets/all_timers/pump_right_side_timer.dart';
import 'package:open_baby_sara/widgets/all_timers/pump_total_timer.dart';
import 'package:open_baby_sara/widgets/custom_bottom_sheet_header.dart';
import 'package:open_baby_sara/widgets/custom_date_time_picker.dart';
import 'package:open_baby_sara/widgets/custom_show_flush_bar.dart';
import 'package:open_baby_sara/widgets/custom_text_form_field.dart';
import 'package:open_baby_sara/widgets/unit_input_field_with_toggle.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

class CustomPumpTrackerBottomSheet extends StatefulWidget {
  final String babyID;
  final String firstName;
  final ActivityModel? existingActivity;
  final bool isEdit;

  const CustomPumpTrackerBottomSheet({
    super.key,
    required this.babyID,
    required this.firstName,
    this.existingActivity,
    this.isEdit = false,
  });

  @override
  State<CustomPumpTrackerBottomSheet> createState() =>
      _CustomPumpTrackerBottomSheetState();
}

class _CustomPumpTrackerBottomSheetState
    extends State<CustomPumpTrackerBottomSheet>
    with SingleTickerProviderStateMixin {
  TextEditingController notesTotalController = TextEditingController();
  TextEditingController notesController = TextEditingController();
  late final TabController _tabController;
  DateTime selectedDatetime = DateTime.now();

  // Total Pump
  DateTime? totalStartTime;
  DateTime? totalEndTime;
  Duration? totalTotalTime;
  double? totalAmount;
  String? totalUnit;

  // Left/Right Side Pump
  DateTime? leftSideStartTime;
  DateTime? leftSideEndTime;
  Duration? leftSideTotalTime;
  DateTime? rightSideStartTime;
  DateTime? rightSideEndTime;
  Duration? rightSideTotalTime;
  double? leftSideAmount;
  String? leftSideUnit;
  double? rightSideAmount;
  String? rightSideUnit;
  String selectedSide = 'left'; // Track selected side: 'left' or 'right'

  @override
  void dispose() {
    // Remove notes listeners
    notesTotalController.removeListener(_onTotalNotesChanged);
    notesController.removeListener(_onLeftRightNotesChanged);
    // Dispose controllers
    notesTotalController.dispose();
    notesController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Update UI when tab changes
    });

    if (widget.isEdit && widget.existingActivity != null) {
      selectedDatetime = widget.existingActivity!.activityDateTime;
      final data = widget.existingActivity!.data;
      if (widget.existingActivity!.activityType ==
          ActivityType.pumpTotal.name) {
        // Backward compatibility: use totalStartTimeDate if available, otherwise use activityDateTime
        if (data['totalStartTimeDate'] != null) {
          totalStartTime = DateTime.parse(data['totalStartTimeDate']);
        } else {
          totalStartTime = _buildTime(
            data,
            'totalStartTimeHour',
            'totalStartTimeMin',
          );
        }
        
        if (data['totalEndTimeDate'] != null) {
          totalEndTime = DateTime.parse(data['totalEndTimeDate']);
        } else {
          totalEndTime = _buildTime(
            data,
            'totalEndTimeHour',
            'totalEndTimeMin',
          );
        }
        
        totalTotalTime = Duration(milliseconds: data['totalTime'] ?? 0);
        totalAmount = (data['totalAmount'] ?? 0).toDouble();
        totalUnit = data['totalUnit'];
        notesTotalController.text = data['notes'] ?? '';
        _tabController.index = 0;
      } else if (widget.existingActivity!.activityType ==
          ActivityType.pumpLeftRight.name) {
        // Backward compatibility: use startTimeDate and endTimeDate if available
        if (data['leftSideStartTimeDate'] != null) {
          leftSideStartTime = DateTime.parse(data['leftSideStartTimeDate']);
        } else {
          leftSideStartTime = _buildTime(
            data,
            'leftSideStartTimeHour',
            'leftSideStartTimeMin',
          );
        }
        
        if (data['leftSideEndTimeDate'] != null) {
          leftSideEndTime = DateTime.parse(data['leftSideEndTimeDate']);
        } else {
          leftSideEndTime = _buildTime(
            data,
            'leftSideEndTimeHour',
            'leftSideEndTimeMin',
          );
        }
        
        leftSideTotalTime = Duration(
          milliseconds: data['leftSideTotalTime'] ?? 0,
        );
        leftSideAmount = (data['leftSideAmount'] ?? 0).toDouble();
        leftSideUnit = data['leftSideUnit'];

        if (data['rightSideStartTimeDate'] != null) {
          rightSideStartTime = DateTime.parse(data['rightSideStartTimeDate']);
        } else {
          rightSideStartTime = _buildTime(
            data,
            'rightSideStartTimeHour',
            'rightSideStartTimeMin',
          );
        }
        
        if (data['rightSideEndTimeDate'] != null) {
          rightSideEndTime = DateTime.parse(data['rightSideEndTimeDate']);
        } else {
          rightSideEndTime = _buildTime(
            data,
            'rightSideEndTimeHour',
            'rightSideEndTimeMin',
          );
        }
        
        rightSideTotalTime = Duration(
          milliseconds: data['rightSideTotalTime'] ?? 0,
        );
        rightSideAmount = (data['rightSideAmount'] ?? 0).toDouble();
        rightSideUnit = data['rightSideUnit'];
        notesController.text = data['notes'] ?? '';
        _tabController.index = 1;
      }
    } else {
      // New record mode - check timer state and load temporarily saved notes
      Future.microtask(() async {
        // Load temporarily saved notes for total pump
        final savedTotalNotes = await SharedPrefsHelper.getPumpTrackerNotes('${widget.babyID}_total');
        if (savedTotalNotes != null && savedTotalNotes.isNotEmpty) {
          notesTotalController.text = savedTotalNotes;
        }
        
        // Load temporarily saved notes for left/right pump
        final savedLeftRightNotes = await SharedPrefsHelper.getPumpTrackerNotes('${widget.babyID}_left_right');
        if (savedLeftRightNotes != null && savedLeftRightNotes.isNotEmpty) {
          notesController.text = savedLeftRightNotes;
        }
        
        // Check timer states for total pump
        final totalBloc = context.read<pumpTotal.PumpTotalTimerBloc>();
        final totalState = totalBloc.state;
        
        if (totalState is pumpTotal.TimerRunning && totalState.activityType == 'pumpTotalTimer') {
          if (totalState.startTime != null) {
            setState(() {
              totalStartTime = totalState.startTime;
              totalTotalTime = totalState.duration;
              totalEndTime = null;
            });
          }
        } else if (totalState is pumpTotal.TimerStopped && totalState.activityType == 'pumpTotalTimer') {
          if (totalState.startTime != null) {
            setState(() {
              totalStartTime = totalState.startTime;
            });
          }
          if (totalState.endTime != null) {
            setState(() {
              totalEndTime = totalState.endTime;
            });
          }
          if (totalState.duration != Duration.zero) {
            setState(() {
              totalTotalTime = totalState.duration;
            });
          }
        }
        
        // Check timer states for left side pump
        final leftBloc = context.read<pumpLeft.PumpLeftSideTimerBloc>();
        final leftState = leftBloc.state;
        
        if (leftState is pumpLeft.TimerRunning && leftState.activityType == 'leftPumpTimer') {
          if (leftState.startTime != null) {
            setState(() {
              leftSideStartTime = leftState.startTime;
              leftSideTotalTime = leftState.duration;
              leftSideEndTime = null;
            });
          }
        } else if (leftState is pumpLeft.TimerStopped && leftState.activityType == 'leftPumpTimer') {
          if (leftState.startTime != null) {
            setState(() {
              leftSideStartTime = leftState.startTime;
            });
          }
          if (leftState.endTime != null) {
            setState(() {
              leftSideEndTime = leftState.endTime;
            });
          }
          if (leftState.duration != Duration.zero) {
            setState(() {
              leftSideTotalTime = leftState.duration;
            });
          }
        }
        
        // Check timer states for right side pump
        final rightBloc = context.read<pumpRight.PumpRightSideTimerBloc>();
        final rightState = rightBloc.state;
        
        if (rightState is pumpRight.TimerRunning && rightState.activityType == 'rightPumpTimer') {
          if (rightState.startTime != null) {
            setState(() {
              rightSideStartTime = rightState.startTime;
              rightSideTotalTime = rightState.duration;
              rightSideEndTime = null;
            });
          }
        } else if (rightState is pumpRight.TimerStopped && rightState.activityType == 'rightPumpTimer') {
          if (rightState.startTime != null) {
            setState(() {
              rightSideStartTime = rightState.startTime;
            });
          }
          if (rightState.endTime != null) {
            setState(() {
              rightSideEndTime = rightState.endTime;
            });
          }
          if (rightState.duration != Duration.zero) {
            setState(() {
              rightSideTotalTime = rightState.duration;
            });
          }
        }
      });
    }

    // Listen to notes changes and save
    notesTotalController.addListener(_onTotalNotesChanged);
    notesController.addListener(_onLeftRightNotesChanged);

    getIt<AnalyticsService>().logScreenView('PumpActivityTracker');
  }

  void _onTotalNotesChanged() {
    if (!widget.isEdit) {
      // Only save temporarily in new record mode
      SharedPrefsHelper.savePumpTrackerNotes('${widget.babyID}_total', notesTotalController.text);
    }
  }

  void _onLeftRightNotesChanged() {
    if (!widget.isEdit) {
      // Only save temporarily in new record mode
      SharedPrefsHelper.savePumpTrackerNotes('${widget.babyID}_left_right', notesController.text);
    }
  }

  DateTime _buildTime(
    Map<String, dynamic> data,
    String hourKey,
    String minKey,
  ) {
    // Backward compatibility: use activityDateTime date if available
    final dateTime = widget.existingActivity?.activityDateTime ?? DateTime.now();
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      data[hourKey] ?? 0,
      data[minKey] ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ActivityBloc, ActivityState>(
      listenWhen: (previous, current) => 
          current is ActivityAdded || current is ActivityUpdated,
      listener: (context, state) {
        // Get root navigator context for showing flushbar
        final rootNavigator = Navigator.of(context, rootNavigator: true);
        final rootContext = rootNavigator.context;
        
        // Close bottom sheet first
        if (mounted) {
          final bottomSheetNavigator = Navigator.of(context, rootNavigator: false);
          if (bottomSheetNavigator.canPop()) {
            bottomSheetNavigator.pop();
          }
        }
        
        // Show flushbar in root context after a short delay
        Future.delayed(const Duration(milliseconds: 150), () {
          if (rootContext.mounted) {
            final message = state is ActivityAdded
                ? context.tr('activity_was_added')
                : (context.tr('activity_was_updated') ?? context.tr('activity_was_added'));
            showCustomFlushbar(
              rootContext,
              context.tr('success'),
              message,
              Icons.add_task_outlined,
              color: Colors.green,
            );
          }
        });
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),

        child: Container(
          height: 600.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                CustomSheetHeader(
                  title: context.tr('pump_tracker'),
                  onBack: () => Navigator.of(context).pop(),
                  onSave: () => onPressedSave(),
                  saveText:
                      widget.isEdit ? context.tr('update') : context.tr('save'),
                  backgroundColor: AppColors.pumpColor,
                ),
                // Simple and Elegant Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  padding: EdgeInsets.all(3.w),
                  margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelPadding: EdgeInsets.symmetric(horizontal: 4.w),
                    labelColor: Colors.purple.shade600,
                    unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 12.sp,
                    ),
                    tabs: [
                      Tab(
                        height: 38,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timelapse, size: 16),
                            SizedBox(width: 4.w),
                            Text(context.tr("total")),
                          ],
                        ),
                      ),
                      Tab(
                        height: 38,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.compare_arrows, size: 16),
                            SizedBox(width: 4.w),
                            Text(context.tr("left_right_side")),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    physics: BouncingScrollPhysics(),
                    controller: _tabController,
                    children: <Widget>[
                      customTotalPumpTracker(),
                      customLeftRightPumpTracker(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onPressedSave() async {
    final String activityID =
        widget.isEdit ? widget.existingActivity!.activityID : const Uuid().v4();

    final String activityType = widget.isEdit
        ? widget.existingActivity!.activityType
        : (_tabController.index == 0
            ? ActivityType.pumpTotal.name
            : ActivityType.pumpLeftRight.name);

    // Validation for total pump
    if (_tabController.index == 0) {
      // Scenario 4.3: Eksik Alanlar (Total Pump)
      // At least start/end time or amount is required
      if ((totalStartTime == null || totalEndTime == null) && (totalAmount == null || totalAmount == 0)) {
        _showError(context.tr("please_enter_start_end_time_or_amount") ?? 
            "Please enter start/end time or amount");
        return;
      }
      
      // If times are provided, validate them
      if (totalStartTime != null && totalEndTime != null) {
        if (totalStartTime!.isAfter(totalEndTime!)) {
          _showError(context.tr("end_time_before_start"));
          return;
        }
        
        if (totalStartTime!.isAtSameMomentAs(totalEndTime!)) {
          _showError(context.tr("start_end_time_same") ?? 
              "Start and end time cannot be the same");
          return;
        }
        
        final now = DateTime.now();
        if (totalStartTime!.isAfter(now) || totalEndTime!.isAfter(now)) {
          _showError(context.tr("date_in_future") ?? 
              "Start and end time cannot be in the future");
          return;
        }
        
        final oneYearAgo = now.subtract(const Duration(days: 365));
        if (totalStartTime!.isBefore(oneYearAgo) || totalEndTime!.isBefore(oneYearAgo)) {
          _showError(context.tr("date_too_old") ?? 
              "Date cannot be more than 1 year ago");
          return;
        }
      }
    } else {
      // Validation for left/right pump
      // At least one side must have start and end time
      final hasLeftSide = leftSideStartTime != null && leftSideEndTime != null;
      final hasRightSide = rightSideStartTime != null && rightSideEndTime != null;
      
      if (!hasLeftSide && !hasRightSide) {
        _showError(context.tr("please_enter_start_end_time_or_amount") ?? 
            "Please enter start/end time for at least one side");
        return;
      }
      
      // Validate left side if exists
      if (hasLeftSide) {
        if (leftSideStartTime!.isAfter(leftSideEndTime!)) {
          _showError(context.tr("end_time_before_start"));
          return;
        }
        
        if (leftSideStartTime!.isAtSameMomentAs(leftSideEndTime!)) {
          _showError(context.tr("start_end_time_same") ?? 
              "Start and end time cannot be the same");
          return;
        }
        
        final now = DateTime.now();
        if (leftSideStartTime!.isAfter(now) || leftSideEndTime!.isAfter(now)) {
          _showError(context.tr("date_in_future") ?? 
              "Start and end time cannot be in the future");
          return;
        }
        
        final oneYearAgo = now.subtract(const Duration(days: 365));
        if (leftSideStartTime!.isBefore(oneYearAgo) || leftSideEndTime!.isBefore(oneYearAgo)) {
          _showError(context.tr("date_too_old") ?? 
              "Date cannot be more than 1 year ago");
          return;
        }
      }
      
      // Validate right side if exists
      if (hasRightSide) {
        if (rightSideStartTime!.isAfter(rightSideEndTime!)) {
          _showError(context.tr("end_time_before_start"));
          return;
        }
        
        if (rightSideStartTime!.isAtSameMomentAs(rightSideEndTime!)) {
          _showError(context.tr("start_end_time_same") ?? 
              "Start and end time cannot be the same");
          return;
        }
        
        final now = DateTime.now();
        if (rightSideStartTime!.isAfter(now) || rightSideEndTime!.isAfter(now)) {
          _showError(context.tr("date_in_future") ?? 
              "Start and end time cannot be in the future");
          return;
        }
        
        final oneYearAgo = now.subtract(const Duration(days: 365));
        if (rightSideStartTime!.isBefore(oneYearAgo) || rightSideEndTime!.isBefore(oneYearAgo)) {
          _showError(context.tr("date_too_old") ?? 
              "Date cannot be more than 1 year ago");
          return;
        }
      }
    }

    final data =
        _tabController.index == 0
            ? {
              // New format: Full DateTime objects
              if (totalStartTime != null) 'totalStartTimeDate': totalStartTime!.toIso8601String(),
              if (totalEndTime != null) 'totalEndTimeDate': totalEndTime!.toIso8601String(),
              // Backward compatibility: Hour/minute info
              'totalStartTimeHour': totalStartTime?.hour ?? 0,
              'totalStartTimeMin': totalStartTime?.minute ?? 0,
              'totalEndTimeHour': totalEndTime?.hour ?? 0,
              'totalEndTimeMin': totalEndTime?.minute ?? 0,
              'totalTime': totalTotalTime?.inMilliseconds ?? 0,
              'totalAmount': totalAmount ?? 0,
              'totalUnit': totalUnit ?? '',
              'notes': notesTotalController.text,
            }
            : {
              // New format: Full DateTime objects
              if (leftSideStartTime != null) 'leftSideStartTimeDate': leftSideStartTime!.toIso8601String(),
              if (leftSideEndTime != null) 'leftSideEndTimeDate': leftSideEndTime!.toIso8601String(),
              // Backward compatibility: Hour/minute info
              'leftSideStartTimeHour': leftSideStartTime?.hour ?? 0,
              'leftSideStartTimeMin': leftSideStartTime?.minute ?? 0,
              'leftSideEndTimeHour': leftSideEndTime?.hour ?? 0,
              'leftSideEndTimeMin': leftSideEndTime?.minute ?? 0,
              'leftSideTotalTime': leftSideTotalTime?.inMilliseconds ?? 0,
              'leftSideAmount': leftSideAmount ?? 0,
              'leftSideUnit': leftSideUnit ?? '',
              // New format: Full DateTime objects
              if (rightSideStartTime != null) 'rightSideStartTimeDate': rightSideStartTime!.toIso8601String(),
              if (rightSideEndTime != null) 'rightSideEndTimeDate': rightSideEndTime!.toIso8601String(),
              // Backward compatibility: Hour/minute info
              'rightSideStartTimeHour': rightSideStartTime?.hour ?? 0,
              'rightSideStartTimeMin': rightSideStartTime?.minute ?? 0,
              'rightSideEndTimeHour': rightSideEndTime?.hour ?? 0,
              'rightSideEndTimeMin': rightSideEndTime?.minute ?? 0,
              'rightSideTotalTime': rightSideTotalTime?.inMilliseconds ?? 0,
              'rightSideAmount': rightSideAmount ?? 0,
              'rightSideUnit': rightSideUnit ?? '',
              'totalTime':
                  (leftSideTotalTime ?? Duration.zero).inMilliseconds +
                  (rightSideTotalTime ?? Duration.zero).inMilliseconds,
              'totalAmount': (leftSideAmount ?? 0) + (rightSideAmount ?? 0),
              'totalUnit': rightSideUnit ?? leftSideUnit,
              'notes': notesController.text,
            };

    final activityModel = ActivityModel(
      activityID: activityID,
      activityType: activityType,
      createdAt:
          widget.isEdit ? widget.existingActivity!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
      activityDateTime: selectedDatetime,
      data: data,
      isSynced: false,
      createdBy: widget.firstName,
      babyID: widget.babyID,
    );

    try {
      if (widget.isEdit) {
        context.read<ActivityBloc>().add(
          UpdateActivity(activityModel: activityModel),
        );
      } else {
        context.read<ActivityBloc>().add(
          AddActivity(activityModel: activityModel),
        );
      }
      
      // Clear all temporary data when save is successful
      if (!widget.isEdit) {
        await SharedPrefsHelper.clearPumpTrackerNotes('${widget.babyID}_total');
        await SharedPrefsHelper.clearPumpTrackerNotes('${widget.babyID}_left_right');
      }
      
      // Reset timer states
      context.read<pumpTotal.PumpTotalTimerBloc>().add(
        pumpTotal.ResetTimer(activityType: 'pumpTotalTimer'),
      );
      context.read<pumpLeft.PumpLeftSideTimerBloc>().add(
        pumpLeft.ResetTimer(activityType: 'leftPumpTimer'),
      );
      context.read<pumpRight.PumpRightSideTimerBloc>().add(
        pumpRight.ResetTimer(activityType: 'rightPumpTimer'),
      );
      
      // BlocListener will handle closing the bottom sheet after state is emitted
    } catch (e) {
      showCustomFlushbar(
        context,
        'Warning',
        'Error ${e.toString()}',
        Icons.warning_outlined,
      );
    }
  }

  _onPressedDelete(BuildContext context) async {
    setState(() {
      // Total Pump
      totalStartTime = null;
      totalEndTime = null;
      totalTotalTime = null;
      totalAmount = null;
      totalUnit = null;
      notesTotalController.clear();

      // Left/Right Pump
      leftSideStartTime = null;
      leftSideEndTime = null;
      leftSideTotalTime = null;
      leftSideAmount = null;
      leftSideUnit = null;

      rightSideStartTime = null;
      rightSideEndTime = null;
      rightSideTotalTime = null;
      rightSideAmount = null;
      rightSideUnit = null;
      notesController.clear();
      selectedSide = 'left'; // Reset to left side
    });

    // Clear temporary notes
    if (!widget.isEdit) {
      await SharedPrefsHelper.clearPumpTrackerNotes('${widget.babyID}_total');
      await SharedPrefsHelper.clearPumpTrackerNotes('${widget.babyID}_left_right');
    }

    context.read<pumpTotal.PumpTotalTimerBloc>().add(
      pumpTotal.ResetTimer(activityType: 'pumpTotalTimer'),
    );
    context.read<pumpLeft.PumpLeftSideTimerBloc>().add(
      pumpLeft.ResetTimer(activityType: 'leftPumpTimer'),
    );
    context.read<pumpRight.PumpRightSideTimerBloc>().add(
      pumpRight.ResetTimer(activityType: 'rightPumpTimer'),
    );

    showCustomFlushbar(
      context,
      color: Colors.greenAccent,
      context.tr("info"),
      context.tr("fields_reset"),
      Icons.refresh,
    );
  }

  void _showError(String message) {
    showCustomFlushbar(context, context.tr("warning"), message, Icons.warning);
  }

  Widget customTotalPumpTracker() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 8.h),
            PumpTotalTimer(size: 140, activityType: 'pumpTotalTimer'),
            SizedBox(height: 24.h),
            // Total Pump Information Box
            BlocBuilder<
              pumpTotal.PumpTotalTimerBloc,
              pumpTotal.PumpTotalTimerState
            >(
              builder: (context, state) {
                if (state is pumpTotal.TimerStopped &&
                    state.activityType == 'pumpTotalTimer') {
                  // Only sync from bloc when bloc has actual values.
                  // In edit mode the initial state may have null times — keep pre-loaded data.
                  if (state.endTime != null) totalEndTime = state.endTime;
                  totalTotalTime = state.duration;
                  if (state.startTime != null) {
                    totalStartTime = state.startTime;
                  }
                }
                if (state is pumpTotal.TimerRunning &&
                    state.activityType == 'pumpTotalTimer') {
                  totalEndTime = null;
                  totalStartTime = state.startTime;
                  totalTotalTime = state.duration;
                }
                if (state is pumpTotal.TimerReset) {
                  // In edit mode, don't wipe pre-loaded data on initial reset state.
                  if (!widget.isEdit) {
                    totalEndTime = null;
                    totalStartTime = null;
                    totalTotalTime = null;
                  }
                }
                final isTotalTimerRunning = state is pumpTotal.TimerRunning && 
                                             state.activityType == 'pumpTotalTimer';

                return _buildTotalInfoBox(!isTotalTimerRunning);
              },
            ),
            SizedBox(height: 16.h),
            // Amount section
            UnitInputFieldWithToggle(
              key: ValueKey('totalAmount_${widget.isEdit}_${widget.existingActivity?.activityID}'),
              initialValue: totalAmount != 0 ? totalAmount : null,
              initialUnit: totalUnit,
              onChanged: (value, unit) {
                setState(() {
                  totalAmount = value;
                  totalUnit = unit;
                });
              },
            ),
            SizedBox(height: 16.h),
            Divider(color: Colors.grey.shade300),
            // Notes section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.tr("notes:"),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall!.copyWith(fontSize: 16.sp),
              ),
            ),
            SizedBox(height: 5.h),
            CustomTextFormField(
              hintText: '',
              isNotes: true,
              controller: notesTotalController,
            ),
            SizedBox(height: 20.h),
            // Created by and Reset
            Text(
              '${context.tr("created_by")} ${widget.firstName}',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontSize: 12.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 10.h),
            TextButton(
              onPressed: () {
                _onPressedDelete(context);
              },
              child: Text(
                context.tr("reset"),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalInfoBox(bool endTimeEnabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title above border - positioned to left, border starts after text
        Stack(
          children: [
            // Border container that starts after the title
            Padding(
              padding: EdgeInsets.only(top:12.h, bottom: 10.h, right: 10.w, left: 5.w),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Color(0xFFE1BEE7), width: 1.5),
                ),
                padding: EdgeInsets.all(8.w),
                child: Column(
                  children: [
                    // Start Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.tr("start_time")),
                        CustomDateTimePicker(
                          key: ValueKey('total_start_${totalStartTime?.millisecondsSinceEpoch ?? 0}'),
                          initialText: 'initialText',
                          initialDateTime: totalStartTime,
                          enabled: true,
                          maxDate: DateTime.now(),
                          minDate: DateTime.now().subtract(const Duration(days: 365)),
                          onDateTimeSelected: (selected) {
                            _onTotalStartTimeSelected(selected);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Divider(color: Colors.grey.shade300, height: 1),
                    SizedBox(height: 6.h),
                    // End Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.tr("end_time")),
                        CustomDateTimePicker(
                          key: ValueKey('total_end_${totalEndTime?.millisecondsSinceEpoch ?? 0}_$endTimeEnabled'),
                          initialText: 'initialText',
                          initialDateTime: totalEndTime,
                          enabled: endTimeEnabled,
                          maxDate: DateTime.now(),
                          minDate: totalStartTime ?? DateTime.now().subtract(const Duration(days: 365)),
                          onDateTimeSelected: (selected) {
                            _onTotalEndTimeSelected(selected);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Divider(color: Colors.grey.shade300, height: 1),
                    SizedBox(height: 6.h),
                    // Total Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.tr("total_time")),
                        TextButton(
                          onPressed: () {
                            _onPressedShowDurationSet(context, 'total');
                          },
                          child: Text(
                            totalTotalTime != null
                                ? formatDuration(totalTotalTime!)
                                : '00:00',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Title positioned to align with border's left edge
            Positioned(
              left: 16.w,
              top: 0,
              child: Container(
                color: Colors.white, // Background to cover border
                padding: EdgeInsets.only(right: 8.w),
                child: Text(
                  context.tr("total"),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget customLeftRightPumpTracker() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 8.h),
            // Modern Left Side / Right Side Selector
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16.r),
              ),
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedSide = 'left';
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                        decoration: BoxDecoration(
                          color: selectedSide == 'left' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(selectedSide == 'left' ? 12.r : 16.r),
                          boxShadow: selectedSide == 'left'
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            context.tr("left_side"),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: selectedSide == 'left' ? FontWeight.w600 : FontWeight.normal,
                              color: selectedSide == 'left' 
                                  ? Theme.of(context).primaryColor 
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedSide = 'right';
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                        decoration: BoxDecoration(
                          color: selectedSide == 'right' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(selectedSide == 'right' ? 12.r : 16.r),
                          boxShadow: selectedSide == 'right'
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            context.tr("right_side"),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: selectedSide == 'right' ? FontWeight.w600 : FontWeight.normal,
                              color: selectedSide == 'right' 
                                  ? Theme.of(context).primaryColor 
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            // Show only the selected side timer
            if (selectedSide == 'left')
              PumpLeftSideTimer(
                size: 140,
                activityType: 'leftPumpTimer',
              )
            else
              PumpRightSideTimer(
                size: 140,
                activityType: 'rightPumpTimer',
              ),
            SizedBox(height: 24.h),
            // Unified Information Box - Show both sides info
            Column(
              children: [
                // Left Side Information Box
                _buildLeftSideInfoBox(),
                SizedBox(height: 16.h),
                // Right Side Information Box
                _buildRightSideInfoBox(),
              ],
            ),
            SizedBox(height: 16.h),
            // Notes section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.tr("notes:"),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall!.copyWith(fontSize: 16.sp),
              ),
            ),
            SizedBox(height: 5.h),
            CustomTextFormField(
              hintText: '',
              isNotes: true,
              controller: notesController,
            ),
            SizedBox(height: 20.h),
            // Created by and Reset
            Text(
              '${context.tr("created_by")} ${widget.firstName}',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontSize: 12.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 10.h),
            TextButton(
              onPressed: () {
                _onPressedDelete(context);
              },
              child: Text(
                context.tr("reset"),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftSideInfoBox() {
    return BlocListener<
      pumpLeft.PumpLeftSideTimerBloc,
      pumpLeft.PumpLeftSideTimerState
    >(
      listener: (context, state) {
        if (state is pumpLeft.TimerStopped &&
            state.activityType == 'leftPumpTimer') {
          setState(() {
            if (state.endTime != null) leftSideEndTime = state.endTime;
            leftSideTotalTime = state.duration;
            if (state.startTime != null) leftSideStartTime = state.startTime;
          });
        } else if (state is pumpLeft.TimerRunning &&
            state.activityType == 'leftPumpTimer') {
          setState(() {
            leftSideEndTime = null;
            leftSideStartTime = state.startTime;
            leftSideTotalTime = state.duration;
          });
        } else if (state is pumpLeft.TimerReset && !widget.isEdit) {
          setState(() {
            leftSideEndTime = null;
            leftSideStartTime = null;
            leftSideTotalTime = null;
          });
        }
      },
      child: BlocBuilder<
        pumpLeft.PumpLeftSideTimerBloc,
        pumpLeft.PumpLeftSideTimerState
      >(
        builder: (context, state) {
          final isLeftTimerRunning = state is pumpLeft.TimerRunning &&
              state.activityType == 'leftPumpTimer';
          return _buildInfoBox(
            'left',
            context.tr("left_side"),
            leftSideStartTime,
            leftSideEndTime,
            leftSideTotalTime,
            leftSideAmount,
            leftSideUnit,
            !isLeftTimerRunning,
          );
        },
      ),
    );
  }

  Widget _buildRightSideInfoBox() {
    return BlocListener<
      pumpRight.PumpRightSideTimerBloc,
      pumpRight.PumpRightSideTimerState
    >(
      listener: (context, state) {
        if (state is pumpRight.TimerStopped &&
            state.activityType == 'rightPumpTimer') {
          setState(() {
            if (state.endTime != null) rightSideEndTime = state.endTime;
            rightSideTotalTime = state.duration;
            if (state.startTime != null) rightSideStartTime = state.startTime;
          });
        } else if (state is pumpRight.TimerRunning &&
            state.activityType == 'rightPumpTimer') {
          setState(() {
            rightSideEndTime = null;
            rightSideStartTime = state.startTime;
            rightSideTotalTime = state.duration;
          });
        } else if (state is pumpRight.TimerReset && !widget.isEdit) {
          setState(() {
            rightSideEndTime = null;
            rightSideStartTime = null;
            rightSideTotalTime = null;
          });
        }
      },
      child: BlocBuilder<
        pumpRight.PumpRightSideTimerBloc,
        pumpRight.PumpRightSideTimerState
      >(
        builder: (context, state) {
          final isRightTimerRunning = state is pumpRight.TimerRunning &&
              state.activityType == 'rightPumpTimer';
          return _buildInfoBox(
            'right',
            context.tr("right_side"),
            rightSideStartTime,
            rightSideEndTime,
            rightSideTotalTime,
            rightSideAmount,
            rightSideUnit,
            !isRightTimerRunning,
          );
        },
      ),
    );
  }

  Widget _buildInfoBox(
    String side,
    String title,
    DateTime? startTime,
    DateTime? endTime,
    Duration? totalTime,
    double? amount,
    String? unit,
    bool endTimeEnabled,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title above border - positioned to left, border starts after text
        Stack(
          children: [
            // Border container that starts after the title
            Padding(
              padding: EdgeInsets.only(top:12.h, bottom: 10.h, right: 10.w, left: 5.w),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Color(0xFFE1BEE7), width: 1.5),
                ),
                padding: EdgeInsets.all(8.w),
                child: Column(
                  children: [
                    // Start Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.tr("start_time")),
                        CustomDateTimePicker(
                          key: ValueKey('${side}_start_${startTime?.millisecondsSinceEpoch ?? 0}'),
                          initialText: 'initialText',
                          initialDateTime: startTime,
                          enabled: true,
                          maxDate: DateTime.now(),
                          minDate: DateTime.now().subtract(const Duration(days: 365)),
                          onDateTimeSelected: (selected) {
                            _onStartTimeSelected(selected, side);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Divider(color: Colors.grey.shade300, height: 1),
                    SizedBox(height: 6.h),
                    // End Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.tr("end_time")),
                        CustomDateTimePicker(
                          key: ValueKey('${side}_end_${endTime?.millisecondsSinceEpoch ?? 0}_$endTimeEnabled'),
                          initialText: 'initialText',
                          initialDateTime: endTime,
                          enabled: endTimeEnabled,
                          maxDate: DateTime.now(),
                          minDate: side == 'left' 
                              ? (leftSideStartTime ?? DateTime.now().subtract(const Duration(days: 365)))
                              : (rightSideStartTime ?? DateTime.now().subtract(const Duration(days: 365))),
                          onDateTimeSelected: (selected) {
                            _onEndTimeSelected(selected, side);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Divider(color: Colors.grey.shade300, height: 1),
                    SizedBox(height: 6.h),
                    // Total Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.tr("total_time")),
                        TextButton(
                          onPressed: () {
                            _onPressedShowDurationSet(context, side);
                          },
                          child: Text(
                            totalTime != null
                                ? formatDuration(totalTime)
                                : '00:00',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Divider(color: Colors.grey.shade300, height: 1),
                    SizedBox(height: 6.h),
                    // Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.tr("amount")),
                        TextButton(
                          onPressed: () {
                            _showAmountDialog(side);
                          },
                          child: Text(
                            _getAmountDisplayText(side),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Title positioned to align with border's left edge
            Positioned(
              left: 16.w,
              top: 0,
              child: Container(
                color: Colors.white, // Background to cover border
                padding: EdgeInsets.only(right: 8.w),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _onTotalStartTimeSelected(DateTime selected) {
    // Future date check
    final now = DateTime.now();
    if (selected.isAfter(now)) {
      _showError(context.tr("date_in_future") ?? 
          "Start time cannot be in the future");
      return;
    }
    
    // Too old date check (1 year ago)
    final oneYearAgo = now.subtract(const Duration(days: 365));
    if (selected.isBefore(oneYearAgo)) {
      _showError(context.tr("date_too_old") ?? 
          "Date cannot be more than 1 year ago");
      return;
    }
    
    // Check if end time exists
    if (totalEndTime != null) {
      // Start time cannot be after end time
      if (selected.isAfter(totalEndTime!)) {
        _showError(context.tr("end_time_before_start"));
        return;
      }
      // Start and end time cannot be the same
      if (selected.isAtSameMomentAs(totalEndTime!)) {
        _showError(context.tr("start_end_time_same") ?? 
            "Start and end time cannot be the same");
        return;
      }
      // Calculate duration
      final calculatedDuration = totalEndTime!.difference(selected);
      totalTotalTime = calculatedDuration;
    }
    
    setState(() {
      totalStartTime = selected;
    });
    
    // If timer is running, switch to manual mode (stop timer)
    final currentState = context.read<pumpTotal.PumpTotalTimerBloc>().state;
    final isTimerRunning = currentState is pumpTotal.TimerRunning && 
                           currentState.activityType == 'pumpTotalTimer';
    
    if (isTimerRunning) {
      context.read<pumpTotal.PumpTotalTimerBloc>().add(
        pumpTotal.StopTimer(activityType: 'pumpTotalTimer'),
      );
    }
    
    // SetStartTimeTimer event will stop timer (switch to manual mode)
    context.read<pumpTotal.PumpTotalTimerBloc>().add(
      pumpTotal.SetStartTimeTimer(
        startTime: selected,
        activityType: 'pumpTotalTimer',
      ),
    );
  }

  void _onTotalEndTimeSelected(DateTime selected) {
    // If timer is running, cannot select end time
    final currentState = context.read<pumpTotal.PumpTotalTimerBloc>().state;
    final isRunning = currentState is pumpTotal.TimerRunning && 
                       currentState.activityType == 'pumpTotalTimer';
    
    if (isRunning) {
      // Cannot select end time while timer is running
      return;
    }
    
    // Future date check
    final now = DateTime.now();
    if (selected.isAfter(now)) {
      _showError(context.tr("date_in_future") ?? 
          "End time cannot be in the future");
      return;
    }
    
    // Too old date check (1 year ago)
    final oneYearAgo = now.subtract(const Duration(days: 365));
    if (selected.isBefore(oneYearAgo)) {
      _showError(context.tr("date_too_old") ?? 
          "Date cannot be more than 1 year ago");
      return;
    }
    
    if (totalStartTime != null) {
      // End time cannot be before start time
      if (selected.isBefore(totalStartTime!)) {
        _showError(context.tr("end_time_before_start"));
        return;
      }
      // Start and end time cannot be the same
      if (selected.isAtSameMomentAs(totalStartTime!)) {
        _showError(context.tr("start_end_time_same") ?? 
            "Start and end time cannot be the same");
        return;
      }
      // Calculate duration
      final calculatedDuration = selected.difference(totalStartTime!);
      totalTotalTime = calculatedDuration;
    }
    
    setState(() {
      totalEndTime = selected;
    });
    
    // SetEndTimeTimer event will stop timer (switch to manual mode)
    context.read<pumpTotal.PumpTotalTimerBloc>().add(
      pumpTotal.SetEndTimeTimer(
        activityType: 'pumpTotalTimer',
        endTime: selected,
        startTime: totalStartTime, // Send current start time
      ),
    );
  }

  void _onStartTimeSelected(DateTime selected, String side) {
    // Future date check
    final now = DateTime.now();
    if (selected.isAfter(now)) {
      _showError(context.tr("date_in_future") ?? 
          "Start time cannot be in the future");
      return;
    }
    
    // Too old date check (1 year ago)
    final oneYearAgo = now.subtract(const Duration(days: 365));
    if (selected.isBefore(oneYearAgo)) {
      _showError(context.tr("date_too_old") ?? 
          "Date cannot be more than 1 year ago");
      return;
    }
    
    if (side == 'left') {
      // Check if end time exists
      if (leftSideEndTime != null) {
        // Start time cannot be after end time
        if (selected.isAfter(leftSideEndTime!)) {
          _showError(context.tr("end_time_before_start"));
          return;
        }
        // Start and end time cannot be the same
        if (selected.isAtSameMomentAs(leftSideEndTime!)) {
          _showError(context.tr("start_end_time_same") ?? 
              "Start and end time cannot be the same");
          return;
        }
        // Calculate duration
        final calculatedDuration = leftSideEndTime!.difference(selected);
        leftSideTotalTime = calculatedDuration;
      }
      
      setState(() {
        leftSideStartTime = selected;
      });
      
      // If timer is running, switch to manual mode (stop timer)
      final currentState = context.read<pumpLeft.PumpLeftSideTimerBloc>().state;
      final isTimerRunning = currentState is pumpLeft.TimerRunning && 
                             currentState.activityType == 'leftPumpTimer';
      
      if (isTimerRunning) {
        context.read<pumpLeft.PumpLeftSideTimerBloc>().add(
          pumpLeft.StopTimer(activityType: 'leftPumpTimer'),
        );
      }
      
      // SetStartTimeTimer event will stop timer (switch to manual mode)
      context.read<pumpLeft.PumpLeftSideTimerBloc>().add(
        pumpLeft.SetStartTimeTimer(
          startTime: selected,
          activityType: 'leftPumpTimer',
        ),
      );
    } else if (side == 'right') {
      // Check if end time exists
      if (rightSideEndTime != null) {
        // Start time cannot be after end time
        if (selected.isAfter(rightSideEndTime!)) {
          _showError(context.tr("end_time_before_start"));
          return;
        }
        // Start and end time cannot be the same
        if (selected.isAtSameMomentAs(rightSideEndTime!)) {
          _showError(context.tr("start_end_time_same") ?? 
              "Start and end time cannot be the same");
          return;
        }
        // Calculate duration
        final calculatedDuration = rightSideEndTime!.difference(selected);
        rightSideTotalTime = calculatedDuration;
      }
      
      setState(() {
        rightSideStartTime = selected;
      });
      
      // If timer is running, switch to manual mode (stop timer)
      final currentState = context.read<pumpRight.PumpRightSideTimerBloc>().state;
      final isTimerRunning = currentState is pumpRight.TimerRunning && 
                             currentState.activityType == 'rightPumpTimer';
      
      if (isTimerRunning) {
        context.read<pumpRight.PumpRightSideTimerBloc>().add(
          pumpRight.StopTimer(activityType: 'rightPumpTimer'),
        );
      }
      
      // SetStartTimeTimer event will stop timer (switch to manual mode)
      context.read<pumpRight.PumpRightSideTimerBloc>().add(
        pumpRight.SetStartTimeTimer(
          startTime: selected,
          activityType: 'rightPumpTimer',
        ),
      );
    }
  }

  void _onEndTimeSelected(DateTime selected, String side) {
    // If timer is running, cannot select end time
    if (side == 'left') {
      final currentState = context.read<pumpLeft.PumpLeftSideTimerBloc>().state;
      final isRunning = currentState is pumpLeft.TimerRunning && 
                         currentState.activityType == 'leftPumpTimer';
      
      if (isRunning) {
        // Cannot select end time while timer is running
        return;
      }
    } else {
      final currentState = context.read<pumpRight.PumpRightSideTimerBloc>().state;
      final isRunning = currentState is pumpRight.TimerRunning && 
                         currentState.activityType == 'rightPumpTimer';
      
      if (isRunning) {
        // Cannot select end time while timer is running
        return;
      }
    }
    
    // Future date check
    final now = DateTime.now();
    if (selected.isAfter(now)) {
      _showError(context.tr("date_in_future") ?? 
          "End time cannot be in the future");
      return;
    }
    
    // Too old date check (1 year ago)
    final oneYearAgo = now.subtract(const Duration(days: 365));
    if (selected.isBefore(oneYearAgo)) {
      _showError(context.tr("date_too_old") ?? 
          "Date cannot be more than 1 year ago");
      return;
    }
    
    if (side == 'left') {
      if (leftSideStartTime != null) {
        // End time cannot be before start time
        if (selected.isBefore(leftSideStartTime!)) {
          _showError(context.tr("end_time_before_start"));
          return;
        }
        // Start and end time cannot be the same
        if (selected.isAtSameMomentAs(leftSideStartTime!)) {
          _showError(context.tr("start_end_time_same") ?? 
              "Start and end time cannot be the same");
          return;
        }
        // Calculate duration
        final calculatedDuration = selected.difference(leftSideStartTime!);
        leftSideTotalTime = calculatedDuration;
      }
      
      setState(() {
        leftSideEndTime = selected;
      });
      
      // SetEndTimeTimer event will stop timer (switch to manual mode)
      context.read<pumpLeft.PumpLeftSideTimerBloc>().add(
        pumpLeft.SetEndTimeTimer(
          activityType: 'leftPumpTimer',
          endTime: selected,
          startTime: leftSideStartTime, // Send current start time
        ),
      );
    } else if (side == 'right') {
      if (rightSideStartTime != null) {
        // End time cannot be before start time
        if (selected.isBefore(rightSideStartTime!)) {
          _showError(context.tr("end_time_before_start"));
          return;
        }
        // Start and end time cannot be the same
        if (selected.isAtSameMomentAs(rightSideEndTime!)) {
          _showError(context.tr("start_end_time_same") ?? 
              "Start and end time cannot be the same");
          return;
        }
        // Calculate duration
        final calculatedDuration = selected.difference(rightSideStartTime!);
        rightSideTotalTime = calculatedDuration;
      }
      
      setState(() {
        rightSideEndTime = selected;
      });
      
      // SetEndTimeTimer event will stop timer (switch to manual mode)
      context.read<pumpRight.PumpRightSideTimerBloc>().add(
        pumpRight.SetEndTimeTimer(
          activityType: 'rightPumpTimer',
          endTime: selected,
          startTime: rightSideStartTime, // Send current start time
        ),
      );
    }
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _getAmountDisplayText(String side) {
    if (side == 'left') {
      if (leftSideAmount != null && leftSideAmount! > 0) {
        return '${leftSideAmount!.toStringAsFixed(1)} ${leftSideUnit ?? 'oz'}';
      }
    } else if (side == 'right') {
      if (rightSideAmount != null && rightSideAmount! > 0) {
        return '${rightSideAmount!.toStringAsFixed(1)} ${rightSideUnit ?? 'oz'}';
      }
    }
    return context.tr("add");
  }

  void _showAmountDialog(String side) {
    final currentAmount = side == 'left' ? leftSideAmount : rightSideAmount;
    final currentUnit = side == 'left' ? leftSideUnit : rightSideUnit;
    final controller = TextEditingController(
      text: currentAmount != null && currentAmount > 0 
          ? currentAmount.toStringAsFixed(1) 
          : '',
    );
    String selectedUnit = currentUnit ?? 'oz';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.tr("amount")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: context.tr("amount"),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: Text('oz'),
                    selected: selectedUnit == 'oz',
                    onSelected: (selected) {
                      setDialogState(() {
                        selectedUnit = 'oz';
                      });
                    },
                  ),
                  SizedBox(width: 16),
                  ChoiceChip(
                    label: Text('ml'),
                    selected: selectedUnit == 'ml',
                    onSelected: (selected) {
                      setDialogState(() {
                        selectedUnit = 'ml';
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.tr("cancel")),
            ),
            TextButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null && value > 0) {
                  setState(() {
                    if (side == 'left') {
                      leftSideAmount = value;
                      leftSideUnit = selectedUnit;
                    } else {
                      rightSideAmount = value;
                      rightSideUnit = selectedUnit;
                    }
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text(context.tr("save")),
            ),
          ],
        ),
      ),
    );
  }

  void _onPressedShowDurationSet(BuildContext context, String side) async {
    final currentDuration = side == 'left' 
        ? leftSideTotalTime 
        : (side == 'right' 
            ? rightSideTotalTime 
            : totalTotalTime);
    final setDuration = await showDurationPicker(
      context: context,
      initialTime: currentDuration ?? Duration(hours: 0, minutes: 0),
      baseUnit: BaseUnit.minute, // minute / hour / second
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
    );
    if (setDuration != null) {
      DateTime? newStart;
      DateTime? newEnd;
      
      if (side == 'left') {
        final oldStart = leftSideStartTime;
        final oldEnd = leftSideEndTime;
        
        if (oldEnd != null) {
          // If end time exists, calculate start time
          newEnd = oldEnd;
          newStart = oldEnd.subtract(setDuration);
          
          // Future date check
          final now = DateTime.now();
          if (newStart.isAfter(now)) {
            _showError(context.tr("date_in_future") ?? 
                "Calculated start time cannot be in the future");
            return;
          }
          
          // Too old date check
          final oneYearAgo = now.subtract(const Duration(days: 365));
          if (newStart.isBefore(oneYearAgo)) {
            _showError(context.tr("date_too_old") ?? 
                "Calculated start time cannot be more than 1 year ago");
            return;
          }
        } else if (oldStart != null) {
          // If start time exists, calculate end time
          newStart = oldStart;
          newEnd = oldStart.add(setDuration);
          
          // Future date check
          final now = DateTime.now();
          if (newEnd.isAfter(now)) {
            _showError(context.tr("date_in_future") ?? 
                "Calculated end time cannot be in the future");
            return;
          }
        } else {
          // If neither exists, set end time to current time and calculate start time
          final now = DateTime.now();
          newEnd = now;
          newStart = now.subtract(setDuration);
          
          // Too old date check
          final oneYearAgo = now.subtract(const Duration(days: 365));
          if (newStart.isBefore(oneYearAgo)) {
            _showError(context.tr("date_too_old") ?? 
                "Calculated start time cannot be more than 1 year ago");
            return;
          }
        }
        
        setState(() {
          leftSideTotalTime = setDuration;
          leftSideStartTime = newStart;
          leftSideEndTime = newEnd;
        });
        
        // Notify bloc - first duration, then times
        context.read<pumpLeft.PumpLeftSideTimerBloc>().add(
          pumpLeft.SetDurationTimer(
            duration: setDuration,
            activityType: 'leftPumpTimer',
          ),
        );
        
        // If start time changed, notify bloc
        if (newStart != null && newStart != oldStart) {
          context.read<pumpLeft.PumpLeftSideTimerBloc>().add(
            pumpLeft.SetStartTimeTimer(
              startTime: newStart,
              activityType: 'leftPumpTimer',
            ),
          );
        }
        
        // If end time changed, notify bloc
        if (newEnd != null && newEnd != oldEnd) {
          context.read<pumpLeft.PumpLeftSideTimerBloc>().add(
            pumpLeft.SetEndTimeTimer(
              activityType: 'leftPumpTimer',
              endTime: newEnd,
              startTime: newStart,
            ),
          );
        }
      } else if (side == 'right') {
        final oldStart = rightSideStartTime;
        final oldEnd = rightSideEndTime;
        
        if (oldEnd != null) {
          // If end time exists, calculate start time
          newEnd = oldEnd;
          newStart = oldEnd.subtract(setDuration);
          
          // Future date check
          final now = DateTime.now();
          if (newStart.isAfter(now)) {
            _showError(context.tr("date_in_future") ?? 
                "Calculated start time cannot be in the future");
            return;
          }
          
          // Too old date check
          final oneYearAgo = now.subtract(const Duration(days: 365));
          if (newStart.isBefore(oneYearAgo)) {
            _showError(context.tr("date_too_old") ?? 
                "Calculated start time cannot be more than 1 year ago");
            return;
          }
        } else if (oldStart != null) {
          // If start time exists, calculate end time
          newStart = oldStart;
          newEnd = oldStart.add(setDuration);
          
          // Future date check
          final now = DateTime.now();
          if (newEnd.isAfter(now)) {
            _showError(context.tr("date_in_future") ?? 
                "Calculated end time cannot be in the future");
            return;
          }
        } else {
          // If neither exists, set end time to current time and calculate start time
          final now = DateTime.now();
          newEnd = now;
          newStart = now.subtract(setDuration);
          
          // Too old date check
          final oneYearAgo = now.subtract(const Duration(days: 365));
          if (newStart.isBefore(oneYearAgo)) {
            _showError(context.tr("date_too_old") ?? 
                "Calculated start time cannot be more than 1 year ago");
            return;
          }
        }
        
        setState(() {
          rightSideTotalTime = setDuration;
          rightSideStartTime = newStart;
          rightSideEndTime = newEnd;
        });
        
        // Notify bloc - first duration, then times
        context.read<pumpRight.PumpRightSideTimerBloc>().add(
          pumpRight.SetDurationTimer(
            duration: setDuration,
            activityType: 'rightPumpTimer',
          ),
        );
        
        // If start time changed, notify bloc
        if (newStart != null && newStart != oldStart) {
          context.read<pumpRight.PumpRightSideTimerBloc>().add(
            pumpRight.SetStartTimeTimer(
              startTime: newStart,
              activityType: 'rightPumpTimer',
            ),
          );
        }
        
        // If end time changed, notify bloc
        if (newEnd != null && newEnd != oldEnd) {
          context.read<pumpRight.PumpRightSideTimerBloc>().add(
            pumpRight.SetEndTimeTimer(
              activityType: 'rightPumpTimer',
              endTime: newEnd,
              startTime: newStart,
            ),
          );
        }
      } else if (side == 'total') {
        final oldStart = totalStartTime;
        final oldEnd = totalEndTime;
        
        if (oldEnd != null) {
          // If end time exists, calculate start time
          newEnd = oldEnd;
          newStart = oldEnd.subtract(setDuration);
          
          // Future date check
          final now = DateTime.now();
          if (newStart.isAfter(now)) {
            _showError(context.tr("date_in_future") ?? 
                "Calculated start time cannot be in the future");
            return;
          }
          
          // Too old date check
          final oneYearAgo = now.subtract(const Duration(days: 365));
          if (newStart.isBefore(oneYearAgo)) {
            _showError(context.tr("date_too_old") ?? 
                "Calculated start time cannot be more than 1 year ago");
            return;
          }
        } else if (oldStart != null) {
          // If start time exists, calculate end time
          newStart = oldStart;
          newEnd = oldStart.add(setDuration);
          
          // Future date check
          final now = DateTime.now();
          if (newEnd.isAfter(now)) {
            _showError(context.tr("date_in_future") ?? 
                "Calculated end time cannot be in the future");
            return;
          }
        } else {
          // If neither exists, set end time to current time and calculate start time
          final now = DateTime.now();
          newEnd = now;
          newStart = now.subtract(setDuration);
          
          // Too old date check
          final oneYearAgo = now.subtract(const Duration(days: 365));
          if (newStart.isBefore(oneYearAgo)) {
            _showError(context.tr("date_too_old") ?? 
                "Calculated start time cannot be more than 1 year ago");
            return;
          }
        }
        
        setState(() {
          totalTotalTime = setDuration;
          totalStartTime = newStart;
          totalEndTime = newEnd;
        });
        
        // Notify bloc - first duration, then times
        context.read<pumpTotal.PumpTotalTimerBloc>().add(
          pumpTotal.SetDurationTimer(
            duration: setDuration,
            activityType: 'pumpTotalTimer',
          ),
        );
        
        // If start time changed, notify bloc
        if (newStart != null && newStart != oldStart) {
          context.read<pumpTotal.PumpTotalTimerBloc>().add(
            pumpTotal.SetStartTimeTimer(
              startTime: newStart,
              activityType: 'pumpTotalTimer',
            ),
          );
        }
        
        // If end time changed, notify bloc
        if (newEnd != null && newEnd != oldEnd) {
          context.read<pumpTotal.PumpTotalTimerBloc>().add(
            pumpTotal.SetEndTimeTimer(
              activityType: 'pumpTotalTimer',
              endTime: newEnd,
              startTime: newStart,
            ),
          );
        }
      }
    }
  }
}
