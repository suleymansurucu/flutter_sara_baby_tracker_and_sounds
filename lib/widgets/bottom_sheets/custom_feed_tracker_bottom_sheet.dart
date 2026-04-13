import 'package:duration_picker/duration_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_baby_sara/app/routes/navigation_wrapper.dart';
import 'package:open_baby_sara/blocs/activity/activity_bloc.dart';
import 'package:open_baby_sara/blocs/all_timer/breasfeed_left_side_timer/breasfeed_left_side_timer_bloc.dart'
    as leftBreastfeed;
import 'package:open_baby_sara/blocs/all_timer/breastfeed_right_side_timer/breastfeed_right_side_timer_bloc.dart'
    as rightBreastfeed;
import 'package:open_baby_sara/core/app_colors.dart';
import 'package:open_baby_sara/core/utils/shared_prefs_helper.dart';
import 'package:open_baby_sara/data/models/activity_model.dart';
import 'package:open_baby_sara/data/repositories/locator.dart';
import 'package:open_baby_sara/data/services/firebase/analytics_service.dart';
import 'package:open_baby_sara/widgets/all_timers/breastfeed_left_side_timer.dart';
import 'package:open_baby_sara/widgets/all_timers/breastfeed_right_side_timer.dart';
import 'package:open_baby_sara/widgets/build_custom_snack_bar.dart';
import 'package:open_baby_sara/widgets/custom_bottom_sheet_header.dart';
import 'package:open_baby_sara/widgets/custom_date_time_picker.dart';
import 'package:open_baby_sara/widgets/custom_show_flush_bar.dart';
import 'package:open_baby_sara/widgets/custom_text_form_field.dart';
import 'package:open_baby_sara/widgets/formula_breastmilk_selector.dart';
import 'package:open_baby_sara/widgets/unit_input_field_with_toggle.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

class CustomFeedTrackerBottomSheet extends StatefulWidget {
  final String babyID;
  final String firstName;
  final ActivityModel? existingActivity;
  final bool isEdit;

  const CustomFeedTrackerBottomSheet({
    super.key,
    required this.babyID,
    required this.firstName,
    this.existingActivity,
    this.isEdit = false,
  });

  @override
  State<CustomFeedTrackerBottomSheet> createState() =>
      _CustomFeedTrackerBottomSheetState();
}

class _CustomFeedTrackerBottomSheetState
    extends State<CustomFeedTrackerBottomSheet>
    with SingleTickerProviderStateMixin {
  TextEditingController notesBottleFeedController = TextEditingController();
  late final TabController _tabController;
  String? selectedMainActivity;
  DateTime selectedDatetime = DateTime.now();

  double? feedAmout;
  String? feedUnit;
  DateTime? leftSideStartTime;
  DateTime? leftSideEndTime;
  Duration? leftSideTotalTime;
  DateTime? rightSideStartTime;
  DateTime? rightSideEndTime;
  Duration? rightSideTotalTime;

  double? leftSideAmout;
  String? leftSideUnit;
  double? rightSideAmout;
  String? rightSideUnit;
  TextEditingController notesController = TextEditingController();
  String selectedSide = 'left'; // Track selected side: 'left' or 'right'

  @override
  void dispose() {
    // Remove notes listeners
    notesBottleFeedController.removeListener(_onBottleFeedNotesChanged);
    notesController.removeListener(_onBreastfeedNotesChanged);
    // Dispose controllers
    notesBottleFeedController.dispose();
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
          ActivityType.bottleFeed.name) {
        selectedMainActivity = data['mainSelection'];
        feedAmout = (data['totalAmount'] ?? 0).toDouble();
        feedUnit = data['totalUnit'];
        notesBottleFeedController.text = data['notes'] ?? '';
        _tabController.index = 1;
        
        // Backward compatibility: use feedingTimeDate if available, otherwise use activityDateTime
        if (data['feedingTimeDate'] != null) {
          selectedDatetime = DateTime.parse(data['feedingTimeDate']);
        } else {
          selectedDatetime = widget.existingActivity!.activityDateTime;
        }
      } else if (widget.existingActivity!.activityType ==
          ActivityType.breastFeed.name) {
        // Backward compatibility: use startTimeDate and endTimeDate if available, otherwise get date from activityDateTime
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
        leftSideAmout = (data['leftSideAmount'] ?? 0).toDouble();
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
        rightSideAmout = (data['rightSideAmount'] ?? 0).toDouble();
        rightSideUnit = data['rightSideUnit'];
        notesController.text = data['notes'] ?? '';
      }
    } else {
      // New record mode - check timer state and load temporarily saved notes
      Future.microtask(() async {
        // Load temporarily saved notes for bottle feed
        final savedBottleFeedNotes = await SharedPrefsHelper.getFeedTrackerNotes('${widget.babyID}_bottle');
        if (savedBottleFeedNotes != null && savedBottleFeedNotes.isNotEmpty) {
          notesBottleFeedController.text = savedBottleFeedNotes;
        }
        
        // Load temporarily saved notes for breastfeed
        final savedBreastfeedNotes = await SharedPrefsHelper.getFeedTrackerNotes('${widget.babyID}_breastfeed');
        if (savedBreastfeedNotes != null && savedBreastfeedNotes.isNotEmpty) {
          notesController.text = savedBreastfeedNotes;
        }
        
        // Check timer states for breastfeed
        final leftBloc = context.read<leftBreastfeed.BreasfeedLeftSideTimerBloc>();
        final rightBloc = context.read<rightBreastfeed.BreastfeedRightSideTimerBloc>();
        final leftState = leftBloc.state;
        final rightState = rightBloc.state;
        
        if (leftState is leftBreastfeed.TimerRunning && leftState.activityType == 'leftPumpTimer') {
          if (leftState.startTime != null) {
            setState(() {
              leftSideStartTime = leftState.startTime;
              leftSideTotalTime = leftState.duration;
              leftSideEndTime = null;
            });
          }
        } else if (leftState is leftBreastfeed.TimerStopped && leftState.activityType == 'leftPumpTimer') {
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
        
        if (rightState is rightBreastfeed.TimerRunning && rightState.activityType == 'rightPumpTimer') {
          if (rightState.startTime != null) {
            setState(() {
              rightSideStartTime = rightState.startTime;
              rightSideTotalTime = rightState.duration;
              rightSideEndTime = null;
            });
          }
        } else if (rightState is rightBreastfeed.TimerStopped && rightState.activityType == 'rightPumpTimer') {
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
    notesBottleFeedController.addListener(_onBottleFeedNotesChanged);
    notesController.addListener(_onBreastfeedNotesChanged);

    getIt<AnalyticsService>().logScreenView('FeedActivityTracker');
  }

  void _onBottleFeedNotesChanged() {
    if (!widget.isEdit) {
      // Only save temporarily in new record mode
      SharedPrefsHelper.saveFeedTrackerNotes('${widget.babyID}_bottle', notesBottleFeedController.text);
    }
  }

  void _onBreastfeedNotesChanged() {
    if (!widget.isEdit) {
      // Only save temporarily in new record mode
      SharedPrefsHelper.saveFeedTrackerNotes('${widget.babyID}_breastfeed', notesController.text);
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
                  title: context.tr('feed_tracker'),
                  onBack: () => Navigator.of(context).pop(),
                  onSave: () => onPressedSave(),
                  saveText:
                      widget.isEdit ? context.tr('update') : context.tr('save'),
                  backgroundColor: AppColors.feedColor,
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
                            Icon(Icons.favorite_rounded, size: 16),
                            SizedBox(width: 4.w),
                            Text(context.tr("breastfeed")),
                          ],
                        ),
                      ),
                      Tab(
                        height: 38,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_drink_rounded, size: 16),
                            SizedBox(width: 4.w),
                            Text(context.tr("bottle_feed")),
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
                      customBreastFeedTracker(),
                      customBottlerFeedTracker(),
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
        : (_tabController.index == 1
            ? ActivityType.bottleFeed.name
            : ActivityType.breastFeed.name);

    // Validation for bottle feed
    if (_tabController.index == 1) {
      // Scenario 4.3: Eksik Alanlar (Bottle Feed)
      if (selectedMainActivity == null || selectedMainActivity!.isEmpty) {
        _showError(context.tr("please_complete_all_fields"));
        return;
      }
      
      if (feedAmout == null || feedAmout == 0) {
        _showError(context.tr("please_complete_all_fields"));
        return;
      }
      
      if (feedUnit == null || feedUnit!.isEmpty) {
        _showError(context.tr("please_complete_all_fields"));
        return;
      }
      
      // Scenario 4.2: Future date check
      final now = DateTime.now();
      if (selectedDatetime.isAfter(now)) {
        _showError(context.tr("date_in_future") ?? 
            "Feeding time cannot be in the future");
        return;
      }
      
      // Scenario 4.6: Too old date check (1 year ago)
      final oneYearAgo = now.subtract(const Duration(days: 365));
      if (selectedDatetime.isBefore(oneYearAgo)) {
        _showError(context.tr("date_too_old") ?? 
            "Date cannot be more than 1 year ago");
        return;
      }
    } else {
      // Validation for breastfeed
      // At least one side must have start and end time
      final hasLeftSide = leftSideStartTime != null && leftSideEndTime != null;
      final hasRightSide = rightSideStartTime != null && rightSideEndTime != null;
      
      if (!hasLeftSide && !hasRightSide) {
        _showError(context.tr("please_complete_all_fields"));
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
        _tabController.index == 1
            ? {
              // New format: Full DateTime objects
              'feedingTimeDate': selectedDatetime.toIso8601String(),
              // Backward compatibility: Hour/minute info
              'startTimeHour': selectedDatetime.hour,
              'startTimeMin': selectedDatetime.minute,
              'notes': notesBottleFeedController.text,
              'mainSelection': selectedMainActivity,
              'totalAmount': feedAmout,
              'totalUnit': feedUnit,
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
              'leftSideAmount': leftSideAmout ?? 0,
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
              'rightSideAmount': rightSideAmout ?? 0,
              'rightSideUnit': rightSideUnit ?? '',
              'totalTime':
                  (leftSideTotalTime ?? Duration.zero).inMilliseconds +
                  (rightSideTotalTime ?? Duration.zero).inMilliseconds,
              'totalAmount': (leftSideAmout ?? 0) + (rightSideAmout ?? 0),
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
        await SharedPrefsHelper.clearFeedTrackerNotes('${widget.babyID}_bottle');
        await SharedPrefsHelper.clearFeedTrackerNotes('${widget.babyID}_breastfeed');
      }
      
      // Reset timer states
      context.read<leftBreastfeed.BreasfeedLeftSideTimerBloc>().add(
        leftBreastfeed.ResetTimer(activityType: 'leftPumpTimer'),
      );
      context.read<rightBreastfeed.BreastfeedRightSideTimerBloc>().add(
        rightBreastfeed.ResetTimer(activityType: 'rightPumpTimer'),
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
      // Bottle Feed
      selectedMainActivity = null;
      feedAmout = null;
      feedUnit = null;
      notesBottleFeedController.clear();
      selectedDatetime = DateTime.now();

      // Breast Feed
      leftSideStartTime = null;
      leftSideEndTime = null;
      leftSideTotalTime = null;
      leftSideAmout = null;
      leftSideUnit = null;

      rightSideStartTime = null;
      rightSideEndTime = null;
      rightSideTotalTime = null;
      rightSideAmout = null;
      rightSideUnit = null;
      notesController.clear();
      selectedSide = 'left'; // Reset to left side
    });

    // Clear temporary notes
    if (!widget.isEdit) {
      await SharedPrefsHelper.clearFeedTrackerNotes('${widget.babyID}_bottle');
      await SharedPrefsHelper.clearFeedTrackerNotes('${widget.babyID}_breastfeed');
    }

    context.read<leftBreastfeed.BreasfeedLeftSideTimerBloc>().add(
      leftBreastfeed.ResetTimer(activityType: 'leftPumpTimer'),
    );

    context.read<rightBreastfeed.BreastfeedRightSideTimerBloc>().add(
      rightBreastfeed.ResetTimer(activityType: 'rightPumpTimer'),
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

  Widget customBottlerFeedTracker() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16.r,
        right: 16.r,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr("time")),
              CustomDateTimePicker(
                key: ValueKey('feeding_time_${selectedDatetime.millisecondsSinceEpoch}'),
                initialText: 'initialText',
                initialDateTime: selectedDatetime,
                maxDate: DateTime.now(), // Prevent future dates
                minDate: DateTime.now().subtract(const Duration(days: 365)), // 1 year ago limit
                onDateTimeSelected: (selected) {
                  // Future date check
                  final now = DateTime.now();
                  if (selected.isAfter(now)) {
                    _showError(context.tr("date_in_future") ?? 
                        "Feeding time cannot be in the future");
                    return;
                  }
                  
                  // Too old date check (1 year ago)
                  final oneYearAgo = now.subtract(const Duration(days: 365));
                  if (selected.isBefore(oneYearAgo)) {
                    _showError(context.tr("date_too_old") ?? 
                        "Date cannot be more than 1 year ago");
                    return;
                  }
                  
                  setState(() {
                    selectedDatetime = selected;
                  });
                },
              ),
            ],
          ),
          Divider(color: Colors.grey.shade300),
          SizedBox(height: 10.h),
          Text(context.tr("feeding_type")),
          SizedBox(height: 5.h),
          FormulaBreastmilkSelector(
            onChanged: (selectedValue) {
              setState(() {
                selectedMainActivity = selectedValue;
              });
            },
          ),
          SizedBox(height: 10.h),
          Divider(color: Colors.grey.shade300),
          UnitInputFieldWithToggle(
            key: ValueKey('feedAmount_${widget.isEdit}_${widget.existingActivity?.activityID}'),
            initialValue: feedAmout != 0 ? feedAmout : null,
            initialUnit: feedUnit,
            onChanged: (value, unit) {
              feedAmout = value;
              feedUnit = unit;
            },
          ),
          Divider(color: Colors.grey.shade300),
          Text(
            context.tr("notes:"),
            style: Theme.of(
              context,
            ).textTheme.titleSmall!.copyWith(fontSize: 16.sp),
          ),
          CustomTextFormField(
            hintText: '',
            isNotes: true,
            controller: notesBottleFeedController,
          ),
          Divider(color: Colors.grey.shade300),

          SizedBox(height: 20.h),
          Center(
            child: Text(
              '${context.tr("created_by")} ${widget.firstName}',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontSize: 12.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Center(
            child: TextButton(
              onPressed: () => _onPressedDelete(context),
              child: Text(
                context.tr("reset"),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTimeInfo(String label, DateTime? dateTime, bool isStartTime, String side, bool isEnabled) {
    String displayText;
    if (dateTime != null) {
      final now = DateTime.now();
      if (dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day) {
        // Today - show only time
        displayText = DateFormat('HH:mm').format(dateTime);
      } else {
        // Different day - show date and time
        displayText = DateFormat('MMM d, HH:mm').format(dateTime);
      }
    } else {
      displayText = context.tr("add");
    }
    
    return Column(
      children: [
        Divider(color: Colors.grey.shade300),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            CustomDateTimePicker(
              key: ValueKey('${side}_${isStartTime ? "start" : "end"}_${dateTime?.millisecondsSinceEpoch ?? 0}_${isEnabled}'),
              initialText: 'initialText',
              initialDateTime: dateTime,
              enabled: isEnabled,
              maxDate: DateTime.now(), // Prevent future dates
              minDate: isStartTime 
                  ? DateTime.now().subtract(const Duration(days: 365)) // 1 year ago limit
                  : (side == 'left' 
                      ? (leftSideStartTime ?? DateTime.now().subtract(const Duration(days: 365)))
                      : (rightSideStartTime ?? DateTime.now().subtract(const Duration(days: 365)))),
              onDateTimeSelected: (selected) {
                if (isStartTime) {
                  _onStartTimeSelected(selected, side);
                } else {
                  _onEndTimeSelected(selected, side);
                }
              },
            ),
          ],
        ),
      ],
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
      final currentState = context.read<leftBreastfeed.BreasfeedLeftSideTimerBloc>().state;
      final isTimerRunning = currentState is leftBreastfeed.TimerRunning && 
                             currentState.activityType == 'leftPumpTimer';
      
      if (isTimerRunning) {
        context.read<leftBreastfeed.BreasfeedLeftSideTimerBloc>().add(
          leftBreastfeed.StopTimer(activityType: 'leftPumpTimer'),
        );
      }
      
      // SetStartTimeTimer event will stop timer (switch to manual mode)
      context.read<leftBreastfeed.BreasfeedLeftSideTimerBloc>().add(
        leftBreastfeed.SetStartTimeTimer(
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
      final currentState = context.read<rightBreastfeed.BreastfeedRightSideTimerBloc>().state;
      final isTimerRunning = currentState is rightBreastfeed.TimerRunning && 
                             currentState.activityType == 'rightPumpTimer';
      
      if (isTimerRunning) {
        context.read<rightBreastfeed.BreastfeedRightSideTimerBloc>().add(
          rightBreastfeed.StopTimer(activityType: 'rightPumpTimer'),
        );
      }
      
      // SetStartTimeTimer event will stop timer (switch to manual mode)
      context.read<rightBreastfeed.BreastfeedRightSideTimerBloc>().add(
        rightBreastfeed.SetStartTimeTimer(
          startTime: selected,
          activityType: 'rightPumpTimer',
        ),
      );
    }
  }

  void _onEndTimeSelected(DateTime selected, String side) {
    // If timer is running, cannot select end time
    if (side == 'left') {
      final currentState = context.read<leftBreastfeed.BreasfeedLeftSideTimerBloc>().state;
      final isRunning = currentState is leftBreastfeed.TimerRunning && 
                         currentState.activityType == 'leftPumpTimer';
      
      if (isRunning) {
        // Cannot select end time while timer is running
        return;
      }
    } else {
      final currentState = context.read<rightBreastfeed.BreastfeedRightSideTimerBloc>().state;
      final isRunning = currentState is rightBreastfeed.TimerRunning && 
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
      context.read<leftBreastfeed.BreasfeedLeftSideTimerBloc>().add(
        leftBreastfeed.SetEndTimeTimer(
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
        if (selected.isAtSameMomentAs(rightSideStartTime!)) {
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
      context.read<rightBreastfeed.BreastfeedRightSideTimerBloc>().add(
        rightBreastfeed.SetEndTimeTimer(
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

  void _onPressedShowDurationSet(BuildContext context, String side) async {
    final currentDuration = side == 'left' ? leftSideTotalTime : rightSideTotalTime;
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
        context.read<leftBreastfeed.BreasfeedLeftSideTimerBloc>().add(
          leftBreastfeed.SetDurationTimer(
            duration: setDuration,
            activityType: 'leftPumpTimer',
          ),
        );
        
        // If start time changed, notify bloc
        if (newStart != null && newStart != oldStart) {
          context.read<leftBreastfeed.BreasfeedLeftSideTimerBloc>().add(
            leftBreastfeed.SetStartTimeTimer(
              startTime: newStart,
              activityType: 'leftPumpTimer',
            ),
          );
        }
        
        // If end time changed, notify bloc
        if (newEnd != null && newEnd != oldEnd) {
          context.read<leftBreastfeed.BreasfeedLeftSideTimerBloc>().add(
            leftBreastfeed.SetEndTimeTimer(
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
        context.read<rightBreastfeed.BreastfeedRightSideTimerBloc>().add(
          rightBreastfeed.SetDurationTimer(
            duration: setDuration,
            activityType: 'rightPumpTimer',
          ),
        );
        
        // If start time changed, notify bloc
        if (newStart != null && newStart != oldStart) {
          context.read<rightBreastfeed.BreastfeedRightSideTimerBloc>().add(
            rightBreastfeed.SetStartTimeTimer(
              startTime: newStart,
              activityType: 'rightPumpTimer',
            ),
          );
        }
        
        // If end time changed, notify bloc
        if (newEnd != null && newEnd != oldEnd) {
          context.read<rightBreastfeed.BreastfeedRightSideTimerBloc>().add(
            rightBreastfeed.SetEndTimeTimer(
              activityType: 'rightPumpTimer',
              endTime: newEnd,
              startTime: newStart,
            ),
          );
        }
      }
    }
  }

  customBreastFeedTracker() {
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
              BreastfeedLeftSideTimer(
                size: 140,
                activityType: 'leftPumpTimer',
              )
            else
              BreastfeedRightSideTimer(
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
    // Anti-pattern fix: state mutasyonu BlocListener'da, BlocBuilder sadece UI render eder
    return BlocListener<
      leftBreastfeed.BreasfeedLeftSideTimerBloc,
      leftBreastfeed.BreasfeedLeftSideTimerState
    >(
      listener: (context, state) {
        if (state is leftBreastfeed.TimerStopped &&
            state.activityType == 'leftPumpTimer') {
          setState(() {
            leftSideEndTime = state.endTime;
            leftSideTotalTime = state.duration;
            if (state.startTime != null) leftSideStartTime = state.startTime;
          });
        } else if (state is leftBreastfeed.TimerRunning &&
            state.activityType == 'leftPumpTimer') {
          setState(() {
            leftSideEndTime = null;
            leftSideStartTime = state.startTime;
            leftSideTotalTime = state.duration;
          });
        } else if (state is leftBreastfeed.TimerReset) {
          setState(() {
            leftSideEndTime = null;
            leftSideStartTime = null;
            leftSideTotalTime = null;
          });
        }
      },
      child: BlocBuilder<
        leftBreastfeed.BreasfeedLeftSideTimerBloc,
        leftBreastfeed.BreasfeedLeftSideTimerState
      >(
        builder: (context, state) {
          final isLeftTimerRunning = state is leftBreastfeed.TimerRunning &&
              state.activityType == 'leftPumpTimer';
          return _buildInfoBox(
            'left',
            context.tr("left_side"),
            leftSideStartTime,
            leftSideEndTime,
            leftSideTotalTime,
            !isLeftTimerRunning,
          );
        },
      ),
    );
  }

  Widget _buildRightSideInfoBox() {
    return BlocListener<
      rightBreastfeed.BreastfeedRightSideTimerBloc,
      rightBreastfeed.BreastfeedRightSideTimerState
    >(
      listener: (context, state) {
        if (state is rightBreastfeed.TimerStopped &&
            state.activityType == 'rightPumpTimer') {
          setState(() {
            rightSideEndTime = state.endTime;
            rightSideTotalTime = state.duration;
            if (state.startTime != null) rightSideStartTime = state.startTime;
          });
        } else if (state is rightBreastfeed.TimerRunning &&
            state.activityType == 'rightPumpTimer') {
          setState(() {
            rightSideEndTime = null;
            rightSideStartTime = state.startTime;
            rightSideTotalTime = state.duration;
          });
        } else if (state is rightBreastfeed.TimerReset) {
          setState(() {
            rightSideEndTime = null;
            rightSideStartTime = null;
            rightSideTotalTime = null;
          });
        }
      },
      child: BlocBuilder<
        rightBreastfeed.BreastfeedRightSideTimerBloc,
        rightBreastfeed.BreastfeedRightSideTimerState
      >(
        builder: (context, state) {
          final isRightTimerRunning = state is rightBreastfeed.TimerRunning &&
              state.activityType == 'rightPumpTimer';
          return _buildInfoBox(
            'right',
            context.tr("right_side"),
            rightSideStartTime,
            rightSideEndTime,
            rightSideTotalTime,
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
              padding: EdgeInsets.only(top:12.h, bottom: 10.h, right: 10.w, left: 5.w), // Space for title, shifted right more
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
                  ],
                ),
              ),
            ),
            // Title positioned to align with border's left edge (border starts at 16.w)
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
}
