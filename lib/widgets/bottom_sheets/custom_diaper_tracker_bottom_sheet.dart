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
import 'package:open_baby_sara/widgets/custom_bottom_sheet_header.dart';
import 'package:open_baby_sara/widgets/custom_check_box_tile.dart';
import 'package:open_baby_sara/widgets/custom_date_time_picker.dart';
import 'package:open_baby_sara/widgets/custom_show_flush_bar.dart';
import 'package:open_baby_sara/widgets/custom_text_form_field.dart';
import 'package:open_baby_sara/widgets/dirty_detail_options.dart';
import 'package:open_baby_sara/widgets/wet_dirty_dry_selector.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

class CustomDiaperTrackerBottomSheet extends StatefulWidget {
  final String babyID;
  final String firstName;
  final bool isEdit;
  final ActivityModel? existingActivity;

  const CustomDiaperTrackerBottomSheet({
    super.key,
    required this.babyID,
    required this.firstName,
    this.isEdit = false,
    this.existingActivity,
  });

  @override
  State<CustomDiaperTrackerBottomSheet> createState() =>
      _CustomDiaperTrackerBottomSheetState();
}

class _CustomDiaperTrackerBottomSheetState
    extends State<CustomDiaperTrackerBottomSheet> {
  TextEditingController notesController = TextEditingController();
  String textTimeAndDate = '';
  DateTime? selectedDatetime = DateTime.now();
  List<String> selectedMain = [];
  List<String> selectedTextures = [];
  List<String> selectedColors = [];
  bool isBlowout = false;
  bool isDiaperRush = false;
  bool isBloodInStool = false;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit && widget.existingActivity != null) {
      final data = widget.existingActivity!.data;
      selectedDatetime = widget.existingActivity!.activityDateTime;
      notesController.text = data['notes'] ?? '';
      selectedMain = List<String>.from(data['mainSelection'] ?? []);
      selectedTextures = List<String>.from(data['textures'] ?? []);
      selectedColors = List<String>.from(data['colors'] ?? []);
      isBlowout = data['isBlowout'] ?? false;
      isDiaperRush = data['isDiaperRush'] ?? false;
      isBloodInStool = data['isBloodInStool'] ?? false;
    } else {
      // New record mode - load temporarily saved notes
      Future.microtask(() async {
        final savedNotes = await SharedPrefsHelper.getDiaperTrackerNotes(widget.babyID);
        if (savedNotes != null && savedNotes.isNotEmpty) {
          notesController.text = savedNotes;
        }
      });
    }

    // Listen to notes changes and save
    notesController.addListener(_onNotesChanged);

    getIt<AnalyticsService>().logScreenView('DiaperActivityTracker');
  }

  void _onNotesChanged() {
    if (!widget.isEdit) {
      // Only save temporarily in new record mode
      SharedPrefsHelper.saveDiaperTrackerNotes(widget.babyID, notesController.text);
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
        onTap: () => FocusScope.of(context).unfocus(),
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
                  title: context.tr('diaper_tracker'),
                  onBack: () => Navigator.of(context).pop(),
                  onSave: () => onPressedSave(),
                  saveText:
                      widget.isEdit ? context.tr('update') : context.tr('save'),
                  backgroundColor: AppColors.diaperColor,
                ),

                // Body: SCROLLABLE
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
                          Text(context.tr("time")),
                          CustomDateTimePicker(
                            key: ValueKey('time_${selectedDatetime?.millisecondsSinceEpoch}'),
                            initialText: 'initialText',
                            initialDateTime: selectedDatetime,
                            maxDate: DateTime.now(), // Prevent future dates
                            minDate: DateTime.now().subtract(const Duration(days: 365)), // 1 year ago limit
                            onDateTimeSelected: (selected) {
                              // Future date check
                              final now = DateTime.now();
                              if (selected.isAfter(now)) {
                                _showError(context.tr("date_in_future") ?? 
                                    "Date cannot be in the future");
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
                      Text(context.tr("select_diaper_condition")),
                      SizedBox(height: 10.h),
                      WetDirtyDrySelector(
                        initialValues: selectedMain,
                        onChanged: (selectedValue) {
                          setState(() {
                            selectedMain = selectedValue;
                            // If Dirty is removed, clear texture and color selections
                            if (!selectedValue.contains('Dirty')) {
                              selectedTextures.clear();
                              selectedColors.clear();
                            }
                          });
                        },
                      ),
                      SizedBox(height: 5.h),

                      if (selectedMain.contains('Dirty'))
                        Divider(color: Colors.grey.shade300),
                      if (selectedMain.contains('Dirty'))
                        DirtyDetailOptions(
                          initialTextures: selectedTextures,
                          initialColors: selectedColors,
                          onChanged: ({
                            required List<String> selectedTextures,
                            required List<String> selectedColors,
                          }) {
                            setState(() {
                              this.selectedTextures = selectedTextures;
                              this.selectedColors = selectedColors;
                            });
                          },
                        ),

                      Divider(color: Colors.grey.shade300),
                      Text(context.tr("additional_observations")),
                      customCheckboxTile(
                        label: context.tr("blowout"),
                        value: isBlowout,
                        onChanged: (val) => setState(() => isBlowout = val),
                      ),
                      customCheckboxTile(
                        label: context.tr("diaper_rush"),
                        value: isDiaperRush,
                        onChanged: (val) => setState(() => isDiaperRush = val),
                      ),
                      customCheckboxTile(
                        label: context.tr("blood_in_stool"),
                        value: isBloodInStool,
                        onChanged:
                            (val) => setState(() => isBloodInStool = val),
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
                      SizedBox(height: 10.h),
                      TextButton(
                        onPressed: () => _onPressedDelete(context),
                        child: Text(
                          context.tr("reset"),
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
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

  void _showError(String message) {
    showCustomFlushbar(context, context.tr("warning"), message, Icons.warning);
  }

  void onPressedSave() async {
    final activityName = ActivityType.diaper.name;

    // Validation: Diaper condition must be selected
    if (selectedMain.isEmpty) {
      _showError(context.tr("please_choose_diaper_condition"));
      return;
    }

    // Validation: DateTime must be selected
    if (selectedDatetime == null) {
      _showError(context.tr("please_complete_all_fields") ?? 
          "Please complete all fields");
      return;
    }

    // Validation: Future date check
    final now = DateTime.now();
    if (selectedDatetime!.isAfter(now)) {
      _showError(context.tr("date_in_future") ?? 
          "Date cannot be in the future");
      return;
    }

    // Validation: Too old date check (1 year ago)
    final oneYearAgo = now.subtract(const Duration(days: 365));
    if (selectedDatetime!.isBefore(oneYearAgo)) {
      _showError(context.tr("date_too_old") ?? 
          "Date cannot be more than 1 year ago");
      return;
    }

    try {
      // New format: Save full DateTime objects as ISO string
      // Also save hour/minute info for backward compatibility with old format
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
          // New format: Full DateTime object
          'activityDateTime': selectedDatetime!.toIso8601String(),
          // Backward compatibility: Hour/minute info
          'startTimeHour': selectedDatetime?.hour,
          'startTimeMin': selectedDatetime?.minute,
          'notes': notesController.text,
          // Defensive copies — setState().clear() below must not mutate these
          'mainSelection': List<String>.from(selectedMain),
          'textures': List<String>.from(selectedTextures),
          'colors': List<String>.from(selectedColors),
          'isBlowout': isBlowout,
          'isDiaperRush': isDiaperRush,
          'isBloodInStool': isBloodInStool,
        },
        isSynced: false,
        createdBy: widget.firstName,
        babyID: widget.babyID,
      );

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
        await SharedPrefsHelper.clearDiaperTrackerNotes(widget.babyID);
      }

      // Clear local state
      setState(() {
        selectedDatetime = DateTime.now();
        selectedMain.clear();
        selectedTextures.clear();
        selectedColors.clear();
        isBlowout = false;
        isDiaperRush = false;
        isBloodInStool = false;
        notesController.clear();
      });

      // BlocListener will handle closing the bottom sheet after state is emitted
    } catch (e, stack) {
      print(stack);
      _showError('Error ${e.toString()}');
    }
  }

  void _onPressedDelete(BuildContext context) {
    setState(() {
      selectedDatetime = DateTime.now();
      selectedMain.clear();
      selectedTextures.clear();
      selectedColors.clear();
      isBlowout = false;
      isDiaperRush = false;
      isBloodInStool = false;
      notesController.clear();
    });

    // Also clear temporary notes
    if (!widget.isEdit) {
      SharedPrefsHelper.clearDiaperTrackerNotes(widget.babyID);
    }

    showCustomFlushbar(
      context,
      context.tr("reset"),
      context.tr("fields_reset"),
      Icons.refresh,
    );
  }
}
