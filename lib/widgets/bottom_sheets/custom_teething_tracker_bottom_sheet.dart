import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_baby_sara/app/routes/navigation_wrapper.dart';
import 'package:open_baby_sara/blocs/activity/activity_bloc.dart';
import 'package:open_baby_sara/core/app_colors.dart';
import 'package:open_baby_sara/core/utils/shared_prefs_helper.dart';
import 'package:open_baby_sara/data/models/activity_model.dart';
import 'package:open_baby_sara/data/repositories/locator.dart';
import 'package:open_baby_sara/data/services/firebase/analytics_service.dart';
import 'package:open_baby_sara/widgets/build_custom_snack_bar.dart';
import 'package:open_baby_sara/widgets/custom_check_box_tile.dart';
import 'package:open_baby_sara/widgets/custom_date_time_picker.dart';
import 'package:open_baby_sara/widgets/custom_show_flush_bar.dart';
import 'package:open_baby_sara/widgets/custom_teeth_selector.dart';
import 'package:open_baby_sara/widgets/custom_text_form_field.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../custom_bottom_sheet_header.dart';

class CustomTeethingTrackerBottomSheet extends StatefulWidget {
  final String babyID;
  final String firstName;
  final ActivityModel? existingActivity;
  final bool isEdit;

  const CustomTeethingTrackerBottomSheet({
    super.key,
    required this.babyID,
    required this.firstName,
    this.existingActivity,
    this.isEdit = false,
  });

  @override
  State<CustomTeethingTrackerBottomSheet> createState() =>
      _CustomTeethingTrackerBottomSheetState();
}

class _CustomTeethingTrackerBottomSheetState
    extends State<CustomTeethingTrackerBottomSheet> {
  DateTime? selectedDatetime = DateTime.now();
  TextEditingController notesController = TextEditingController();
  bool isErupted = false;
  bool isShed = false;
  String? teethingIsoNumber;
  List<String>? initilizeTeeth = [];
  List<ActivityModel>? fetchTeethingActivity;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit && widget.existingActivity != null) {
      selectedDatetime = widget.existingActivity!.activityDateTime;
      notesController.text = widget.existingActivity!.data['notes'] ?? '';
      isErupted = widget.existingActivity!.data['isErupted'] ?? false;
      isShed = widget.existingActivity!.data['isShed'] ?? false;
      teethingIsoNumber = widget.existingActivity!.data['teethingIsoNumber'];
    } else {
      // New record mode - load temporarily saved notes
      Future.microtask(() async {
        final savedNotes = await SharedPrefsHelper.getTeethingTrackerNotes(widget.babyID);
        if (savedNotes != null && savedNotes.isNotEmpty && mounted) {
          setState(() {
            notesController.text = savedNotes;
          });
        }
      });
    }

    // Listen to notes changes and save
    notesController.addListener(_onNotesChanged);

    context.read<ActivityBloc>().add(
      FetchToothIsoNumber(
        babyID: widget.babyID,
        activityType: ActivityType.teething.name,
      ),
    );
    getIt<AnalyticsService>().logScreenView('TeethingActivityTracker');
  }

  void _onNotesChanged() {
    if (!widget.isEdit) {
      // Only save temporarily in new record mode
      SharedPrefsHelper.saveTeethingTrackerNotes(widget.babyID, notesController.text);
    }
  }

  @override
  void dispose() {
    // Remove notes listener
    notesController.removeListener(_onNotesChanged);
    // Dispose controller
    notesController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    showCustomFlushbar(
      context,
      context.tr('error') ?? 'Error',
      message,
      Icons.error_outline,
      color: Colors.red,
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

      child: BlocBuilder<ActivityBloc, ActivityState>(
        buildWhen: (previous, current) =>
            current is TeethingLoading ||
            current is FetchToothIsoNumberLoaded ||
            current is ActivityError,
        builder: (context, state) {
          if (state is FetchToothIsoNumberLoaded) {
            initilizeTeeth = state.toothIsoNumber;
            fetchTeethingActivity = state.toothActivities;
          }

          return state is TeethingLoading
              ? Center(child: CircularProgressIndicator())
              : GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    height: 600.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20.r),
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          // Header
                          CustomSheetHeader(
                            title: context.tr('teething'),
                            onBack: () => Navigator.of(context).pop(),
                            onSave: () => onPressedSave(),
                            saveText:
                                widget.isEdit
                                    ? context.tr('update')
                                    : context.tr('save'),
                            backgroundColor: AppColors.teethingColor,
                          ),

                          /// Body
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.only(
                                left: 16.r,
                                right: 16.r,
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom +
                                    20,
                                top: 16,
                              ),
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(context.tr('baby_teething')),
                                    TextButton(
                                      onPressed: () {
                                        _onPressedAdd();
                                      },
                                      child: Text(context.tr("add")),
                                    ),
                                  ],
                                ),
                                Divider(color: Colors.grey.shade300),
                                CustomTeethSelector(
                                  key: ValueKey(initilizeTeeth?.join(',')),
                                  onSave: null,
                                  isShowDetailTooth: true,
                                  initilizeTeeth: initilizeTeeth,
                                  isColor: true,
                                  isMultiSelect: false,
                                ),
                                SizedBox(height: 20.h),
                                getTeethingTimeLine(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
        },
      ),
    );
  }

  void onPressedSave() async {
    final activityName = ActivityType.teething.name;

    // Scenario 3.1: Diş veya Erupted/Shed seçimi kontrolü
    if (teethingIsoNumber == null || (isErupted == false && isShed == false)) {
      _showError(context.tr('please_enter_teething_information') ?? 
          "Please enter teething information");
      return;
    }

    // Scenario 3.2: Gelecekteki tarih kontrolü
    if (selectedDatetime == null) {
      _showError(context.tr("please_select_time") ?? 
          "Please select time");
      return;
    }

    final now = DateTime.now();
    if (selectedDatetime!.isAfter(now)) {
      _showError(context.tr("date_in_future") ?? 
          "Date cannot be in the future");
      return;
    }

    // Scenario 3.3: Çok eski tarih kontrolü (1 yıl öncesi)
    final oneYearAgo = now.subtract(const Duration(days: 365));
    if (selectedDatetime!.isBefore(oneYearAgo)) {
      _showError(context.tr("date_too_old") ?? 
          "Date cannot be more than 1 year ago");
      return;
    }

    // Scenario 1.4: Aynı diş tekrar kaydedilme engelleme
    if (initilizeTeeth != null && initilizeTeeth!.contains(teethingIsoNumber)) {
      _showError(context.tr('already_added_body') ?? 
          "This tooth has already been added");
      return;
    }

    final activityModel = ActivityModel(
      activityID:
          widget.isEdit
              ? widget.existingActivity!.activityID
              : const Uuid().v4(),
      activityType: activityName,
      createdAt:
          widget.isEdit ? widget.existingActivity!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
      activityDateTime: selectedDatetime!,
      data: {
        // Backward compatibility: Hour/minute info
        'startTimeHour': selectedDatetime?.hour,
        'startTimeMin': selectedDatetime?.minute,
        'notes': notesController.text,
        'teethingIsoNumber': teethingIsoNumber,
        'isErupted': isErupted,
        'isShed': isShed,
      },
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
        // Clear temporarily saved notes after successful save
        await SharedPrefsHelper.clearTeethingTrackerNotes(widget.babyID);
      }

      // BlocListener will handle closing the bottom sheet after state is emitted
    } catch (e) {
      _showError('Error ${e.toString()}');
    }
  }

  void _onPressedAdd() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Container(
                //padding: EdgeInsets.all(16.r),
                constraints: BoxConstraints(maxHeight: 600.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //header
                    CustomSheetHeader(
                      title: context.tr('add_teething'),
                      onBack: () => Navigator.of(context).pop(),
                      onSave: () => onPressedSave(),
                      saveText:
                          widget.isEdit
                              ? context.tr('update')
                              : context.tr('save'),
                      backgroundColor: AppColors.teethingColor,
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.only(
                          left: 16.r,
                          right: 16.r,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                          top: 16,
                        ),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(context.tr('time')),
                              CustomDateTimePicker(
                                key: ValueKey('dialog_time_${selectedDatetime?.millisecondsSinceEpoch}'),
                                initialText: 'initialText',
                                initialDateTime: selectedDatetime,
                                maxDate: DateTime.now(), // Prevent future dates
                                minDate: DateTime.now().subtract(const Duration(days: 365)), // 1 year ago limit
                                onDateTimeSelected: (selected) {
                                  // Future date check
                                  final now = DateTime.now();
                                  if (selected.isAfter(now)) {
                                    showCustomFlushbar(
                                      context,
                                      context.tr('error') ?? 'Error',
                                      context.tr("date_in_future") ?? 
                                          "Date cannot be in the future",
                                      Icons.error_outline,
                                      color: Colors.red,
                                    );
                                    return;
                                  }
                                  
                                  // Too old date check (1 year ago)
                                  final oneYearAgo = now.subtract(const Duration(days: 365));
                                  if (selected.isBefore(oneYearAgo)) {
                                    showCustomFlushbar(
                                      context,
                                      context.tr('error') ?? 'Error',
                                      context.tr("date_too_old") ?? 
                                          "Date cannot be more than 1 year ago",
                                      Icons.error_outline,
                                      color: Colors.red,
                                    );
                                    return;
                                  }
                                  
                                  // Update main form's date (Scenario 1.5: Dialog içinde tarih seçildiğinde ana formdaki tarih güncellenmeli)
                                  setState(() {
                                    selectedDatetime = selected;
                                  });
                                },
                              ),
                            ],
                          ),
                          Divider(color: Colors.grey.shade300),
                          CustomTeethSelector(
                            onSave: (List<String> listName) {
                              teethingIsoNumber = listName.last.toString();
                            },
                            isShowDetailTooth: false,
                            isColor: true,
                            isMultiSelect: false,
                          ),
                          Divider(color: Colors.grey.shade300),
                          customCheckboxTile(
                            label: context.tr('erupted'),
                            value: isErupted,
                            onChanged: (val) {
                              setState(() {
                                isErupted = val;
                                isShed = false;
                              });
                            },
                          ),
                          Divider(color: Colors.grey.shade300),
                          customCheckboxTile(
                            label: context.tr('shed'),
                            value: isShed,
                            onChanged: (val) {
                              setState(() {
                                isShed = val;
                                isErupted = false;
                              });
                            },
                          ),
                          Divider(color: Colors.grey.shade300),

                          SizedBox(height: 5.h),
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
                          Divider(color: Colors.grey.shade300),
                          SizedBox(height: 20.h),
                          Center(
                            child: Text(
                              '${context.tr("created_by")} ${widget.firstName}',
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmall!.copyWith(
                                fontSize: 12.sp,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget getTeethingTimeLine() {
    if (fetchTeethingActivity == null || fetchTeethingActivity!.isEmpty) {
      return Center(child: Text(context.tr('there_is_no_teething_activity')));
    }

    final reversedList = fetchTeethingActivity!.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Center(
            child: Text(
              '🦷 ${context.tr('teething_timeline')}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
                fontSize: 18,
              ),
            ),
          ),
        ),
        Divider(color: Colors.grey.shade300),

        ...reversedList.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final activity = entry.value;

          final toothData = activity.data['teethingIsoNumber'];
          final isoList =
              toothData is List
                  ? toothData.map((e) => e.toString()).toList()
                  : [toothData.toString()];

          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Column(
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CustomTeethSelector(
                          size: 120,
                          isShowDetailTooth: false,
                          isColor: false,
                          isMultiSelect: false,
                          initilizeTeeth: isoList,
                          onSave: null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          '#$index',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat(
                                'MMM dd, yyyy',
                              ).format(activity.activityDateTime),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '${context.tr('time')}: ${activity.activityDateTime.hour.toString().padLeft(2, '0')}:${activity.activityDateTime.minute.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (activity.data['isErupted'] == true)
                              Text(
                                context.tr('erupted'),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else if (activity.data['isShed'] == true)
                              Text(
                                context.tr('shed'),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            Text(
                              '${context.tr("created_by")} ${widget.firstName}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
