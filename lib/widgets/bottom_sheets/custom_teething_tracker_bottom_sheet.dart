import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sara_baby_tracker_and_sound/app/routes/navigation_wrapper.dart';
import 'package:flutter_sara_baby_tracker_and_sound/blocs/activity/activity_bloc.dart';
import 'package:flutter_sara_baby_tracker_and_sound/core/app_colors.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/models/activity_model.dart';
import 'package:flutter_sara_baby_tracker_and_sound/widgets/build_custom_snack_bar.dart';
import 'package:flutter_sara_baby_tracker_and_sound/widgets/custom_check_box_tile.dart';
import 'package:flutter_sara_baby_tracker_and_sound/widgets/custom_date_time_picker.dart';
import 'package:flutter_sara_baby_tracker_and_sound/widgets/custom_show_flush_bar.dart';
import 'package:flutter_sara_baby_tracker_and_sound/widgets/custom_teeth_selector.dart';
import 'package:flutter_sara_baby_tracker_and_sound/widgets/custom_text_form_field.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

class CustomTeethingTrackerBottomSheet extends StatefulWidget {
  final String babyID;
  final String firstName;

  const CustomTeethingTrackerBottomSheet({
    super.key,
    required this.babyID,
    required this.firstName,
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
  List<String>? initilizeTeeth=[];
  List<ActivityModel>? fetchTeethingActivity;

  @override
  void initState() {
    context.read<ActivityBloc>().add(
      FetchToothIsoNumber(
        babyID: widget.babyID,
        activityType: ActivityType.teething.name,
      ),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ActivityBloc, ActivityState>(
      listener: (context, state) {
        if (state is ActivityAdded) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(buildCustomSnackBar(state.message));
        }
      },

      child: BlocBuilder<ActivityBloc, ActivityState>(
        builder: (context, state) {
          if (state is FetchToothIsoNumberLoaded) {
            initilizeTeeth = state.toothIsoNumber;
            fetchTeethingActivity = state.toothActivities;

            debugPrint(initilizeTeeth!.length.toString());
          }

          return state is ActivityLoading
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
                          Container(
                            height: 50.h,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.r,
                              vertical: 12.r,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.teethingColor,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                Text(
                                  context.tr('teething'),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  icon: Icon(
                                    Icons.close,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
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
                                SizedBox(height: 20.h,),
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

  void onPressedSave() {
    final activityName = ActivityType.teething.name;

    if (teethingIsoNumber == null || isErupted == false && isShed == false) {
      showCustomFlushbar(
        context,
        context.tr('warning'),
        context.tr('please_enter_teething_information'),
        Icons.warning_outlined,
      );
    } else if (initilizeTeeth!.contains(teethingIsoNumber)) {
      showCustomFlushbar(
        context,
        context.tr('already_added'),
        context.tr('already_added_body'),
        Icons.warning_outlined,
      );
    }
    else {
      final activityModel = ActivityModel(
        activityID: Uuid().v4(),
        activityType: activityName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        data: {
          'activityDay' : selectedDatetime?.toIso8601String(),
          'startTimeHour': selectedDatetime?.hour,
          'startTimeMin': selectedDatetime?.minute,
          'notes': notesController.text,
          'teethingIsoNumber': teethingIsoNumber,
          isErupted == true ? 'isErupted' : 'isShed': true,
        },
        isSynced: false,
        createdBy: widget.firstName,
        babyID: widget.babyID,
      );
      try {
        context.read<ActivityBloc>().add(
          AddActivity(activityModel: activityModel),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => NavigationWrapper()),
        );
      } catch (e) {
        showCustomFlushbar(
          context,
          context.tr('warning'),
          'Error ${e.toString()}',
          Icons.warning_outlined,
        );
      }
    }
  }

  _onPressedDelete(BuildContext context) {}

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
                    Container(
                      height: 50.h,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.r,
                        vertical: 12.r,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.teethingColor,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('add_teething'),
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: onPressedSave,
                            child: Text(
                              context.tr('save'),
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                                initialText: 'initialText',
                                onDateTimeSelected: (selected) {
                                  selectedDatetime = selected;
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
      return  Center(child: Text(context.tr('there_is_no_teething_activity')));
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
          final isoList = toothData is List
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
                              DateFormat('MMM dd, yyyy').format(activity.createdAt!),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '${context.tr('time')}: ${activity.createdAt!.hour.toString().padLeft(2, '0')}:${activity.createdAt!.minute.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.bodyMedium,
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
