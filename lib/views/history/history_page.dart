import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:open_baby_sara/blocs/activity/activity_bloc.dart';
import 'package:open_baby_sara/blocs/baby/baby_bloc.dart';
import 'package:open_baby_sara/core/app_colors.dart';
import 'package:open_baby_sara/core/constant/activity_constants.dart';
import 'package:open_baby_sara/core/utils/helper_activities.dart';
import 'package:open_baby_sara/data/models/activity_model.dart';
import 'package:open_baby_sara/data/models/baby_model.dart';
import 'package:open_baby_sara/views/history/widgets/history_header_card.dart';
import 'package:open_baby_sara/views/history/widgets/new_activity_card.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_baby_firsts_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_diaper_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_doctor_visit_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_feed_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_fever_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_growth_development_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_medical_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_pump_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_sleep_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_teething_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_vaccination_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/custom_show_flush_bar.dart';
import 'package:open_baby_sara/core/utils/shared_prefs_helper.dart';


class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<BabyModel> babiesList = [];

  DateTime? _lastStartDay;
  DateTime? _lastEndDay;
  String? _lastBabyID;
  String? _lastActivityType;
  String? _selectedFilterType;
  String? _lastLoadedBabyID;

  static const List<_FilterChipData> _filterChips = [
    _FilterChipData(labelKey: 'all', activityType: null),
    _FilterChipData(labelKey: 'sleep', activityType: 'Sleep'),
    _FilterChipData(labelKey: 'feed', activityType: 'Feed'),
    _FilterChipData(labelKey: 'diaper', activityType: 'Diaper'),
    _FilterChipData(labelKey: 'pump', activityType: 'Pump'),
    _FilterChipData(labelKey: 'growth', activityType: 'Growth'),
    _FilterChipData(labelKey: 'baby_firsts', activityType: 'Baby Firsts'),
    _FilterChipData(labelKey: 'teething', activityType: 'Teething'),
    _FilterChipData(labelKey: 'medication', activityType: 'Medication'),
    _FilterChipData(labelKey: 'fever', activityType: 'Fever'),
    _FilterChipData(labelKey: 'vaccination', activityType: 'Vaccination'),
    _FilterChipData(labelKey: 'doctor_visit', activityType: 'Doctor Visit'),
  ];

  @override
  void initState() {
    super.initState();
    final babyState = context.read<BabyBloc>().state;
    if (babyState is BabyLoaded) {
      babiesList = babyState.babies;
    } else {
      context.read<BabyBloc>().add(LoadBabies());
    }
  }

  void _reloadList() {
    if (_lastStartDay != null && _lastEndDay != null && _lastBabyID != null) {
      context.read<ActivityBloc>().add(
            LoadActivitiesByDateRange(
              startDay: _lastStartDay!,
              endDay: _lastEndDay!,
              babyID: _lastBabyID!,
              activityType: _lastActivityType,
            ),
          );
    }
  }

  void _onFilterChipSelected(String? activityType) {
    setState(() => _selectedFilterType = activityType);
    if (_lastStartDay != null && _lastEndDay != null && _lastBabyID != null) {
      context.read<ActivityBloc>().add(
            LoadActivitiesByDateRange(
              startDay: _lastStartDay!,
              endDay: _lastEndDay!,
              babyID: _lastBabyID!,
              activityType: activityType,
            ),
          );
      _lastActivityType = activityType;
    }
  }

  String? _resolvebabyID(BuildContext context) {
    final bState = context.read<BabyBloc>().state;
    return bState is BabyLoaded ? bState.selectedBaby?.babyID : null;
  }

  void _handleFilterChanged(
    BuildContext context,
    DateTime start,
    DateTime end,
    String? babyID,
  ) {
    final id = babyID ?? _resolvebabyID(context);
    if (id == null) return;
    _lastStartDay = start;
    _lastEndDay = end;
    _lastBabyID = id;
    _lastLoadedBabyID = id;
    _lastActivityType = _selectedFilterType;
    context.read<ActivityBloc>().add(
          LoadActivitiesByDateRange(
            startDay: start,
            endDay: end,
            babyID: id,
            activityType: _selectedFilterType,
          ),
        );
  }

  Map<DateTime, List<ActivityModel>> _groupByDate(
      List<ActivityModel> activities) {
    final Map<DateTime, List<ActivityModel>> grouped = {};
    for (final a in activities) {
      final day = DateTime(
        a.activityDateTime.year,
        a.activityDateTime.month,
        a.activityDateTime.day,
      );
      grouped.putIfAbsent(day, () => []).add(a);
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  String _formatGroupDate(DateTime date) {
    return DateFormat('d MMMM yyyy, EEEE', context.locale.toLanguageTag())
        .format(date)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BabyBloc, BabyState>(
      listenWhen: (_, current) => current is BabyLoaded,
      listener: (context, state) async {
        if (state is BabyLoaded) {
          final savedID = await SharedPrefsHelper.getSelectedBabyID();
          if (!context.mounted) return;
          if (savedID != null) {
            final alreadySelected = state.selectedBaby?.babyID == savedID;
            if (!alreadySelected) {
              final matched = state.babies.firstWhere(
                (b) => b.babyID == savedID,
                orElse: () => state.babies.first,
              );
              // SelectBaby will emit another BabyLoaded which HistoryHeaderCard
              // BlocListener will catch and re-trigger filter
              context.read<BabyBloc>().add(SelectBaby(selectBabyModel: matched));
              return;
            }
          }
          // First-time data load: no data loaded yet for this baby
          final currentBabyID = state.selectedBaby?.babyID;
          if (currentBabyID != null && _lastLoadedBabyID == null) {
            _lastLoadedBabyID = currentBabyID;
            if (_lastStartDay != null && _lastEndDay != null) {
              _handleFilterChanged(context, _lastStartDay!, _lastEndDay!, currentBabyID);
            } else {
              final now = DateTime.now();
              _handleFilterChanged(
                context,
                DateTime(now.year, now.month, now.day),
                DateTime(now.year, now.month, now.day, 23, 59, 59),
                currentBabyID,
              );
            }
          }
        }
      },
      child: BlocBuilder<BabyBloc, BabyState>(
        buildWhen: (prev, curr) {
          if (curr is BabyImagePathLoaded) return false;
          if (prev is BabyLoaded && curr is BabyLoaded) {
            return prev.babies.length != curr.babies.length ||
                prev.selectedBaby?.babyID != curr.selectedBaby?.babyID;
          }
          return prev.runtimeType != curr.runtimeType;
        },
        builder: (context, state) {
          if (state is BabyLoaded) babiesList = state.babies;

          if (state is BabyLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            // White so the status bar area matches the header card
            backgroundColor: Colors.white,
            body: Column(
              children: [
                // ── Header sits under SafeArea (white background) ──────
                SafeArea(
                  bottom: false,
                  child: HistoryHeaderCard(
                    babiesList: babiesList,
                    onFilterChanged: (start, end, _, babyID) =>
                        _handleFilterChanged(context, start, end, babyID),
                  ),
                ),

                // ── Everything below: lavender background ──────────────
                Expanded(
                  child: ColoredBox(
                    color: AppColors.historyBackground,
                    child: Column(
                      children: [
                        // Filter chips — natural height, no SizedBox constraint
                        Padding(
                          padding: EdgeInsets.only(top: 10.h, bottom: 4.h),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding:
                                EdgeInsets.symmetric(horizontal: 20.w),
                            child: Row(
                              children: _filterChips.map((chip) {
                                final isSelected =
                                    _selectedFilterType == chip.activityType;
                                return Padding(
                                  padding: EdgeInsets.only(right: 8.w),
                                  child: GestureDetector(
                                    onTap: () => _onFilterChipSelected(
                                        chip.activityType),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14.w,
                                        vertical: 8.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.historyPink
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(20.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isSelected
                                                ? AppColors.historyPink
                                                    .withValues(alpha: 0.3)
                                                : Colors.black
                                                    .withValues(alpha: 0.04),
                                            blurRadius: isSelected ? 6 : 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        context.tr(chip.labelKey),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey[600],
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        // Activity list
                        Expanded(
                          child: BlocListener<ActivityBloc, ActivityState>(
                            listenWhen: (_, current) =>
                                current is ActivityDeleted ||
                                current is ActivityUpdated,
                            listener: (context, state) {
                              if (state is ActivityDeleted) {
                                showCustomFlushbar(
                                  context,
                                  context.tr('activity_deleted'),
                                  context.tr('activity_deleted_body'),
                                  Icons.delete_forever_outlined,
                                );
                                _reloadList();
                              } else if (state is ActivityUpdated) {
                                _reloadList();
                              }
                            },
                            child: BlocBuilder<ActivityBloc, ActivityState>(
                              builder: (context, actState) {
                                if (actState is ActivityLoading) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (actState is ActivityByDateRangeLoaded) {
                                  final activities = actState.activities;
                                  if (activities.isEmpty) {
                                    return _EmptyState(
                                      hasFilter:
                                          _selectedFilterType != null,
                                    );
                                  }

                                  final grouped = _groupByDate(activities);
                                  final dates = grouped.keys.toList();
                                  final showSeparator = dates.length > 1;

                                  return ListView.builder(
                                    padding: EdgeInsets.fromLTRB(
                                        20.w, 4.h, 20.w, 100.h),
                                    itemCount: dates.length,
                                    itemBuilder: (context, i) {
                                      final date = dates[i];
                                      final dayActivities = grouped[date]!;
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (showSeparator)
                                            _DateSeparator(
                                              label: _formatGroupDate(date),
                                            ),
                                          ...dayActivities.map((activity) {
                                            final iconKey =
                                                activityIconMap[activity
                                                        .activityType] ??
                                                    'default';
                                            final summary =
                                                getActivitySummary(
                                                    activity, context);
                                            return NewActivityCard(
                                              activity: activity,
                                              summary: summary,
                                              iconPath:
                                                  'assets/icons/$iconKey.png',
                                              onDelete: () {
                                                context
                                                    .read<ActivityBloc>()
                                                    .add(DeleteActivity(
                                                      babyID: activity.babyID,
                                                      activityID:
                                                          activity.activityID,
                                                    ));
                                              },
                                              onEdit: () =>
                                                  _updateActivity(activity),
                                            );
                                          }),
                                        ],
                                      );
                                    },
                                  );
                                }

                                if (actState is ActivityError) {
                                  return Center(
                                      child: Text(actState.message));
                                }

                                return _EmptyState(
                                  hasFilter: _selectedFilterType != null,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _updateActivity(ActivityModel activityModel) {
    final activityType = activityModel.activityType;
    final babyID = activityModel.babyID;
    final firstName = activityModel.createdBy;

    if (activityType == ActivityType.babyFirsts.name) {
      showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (_) => CustomBabyFirstsTrackerBottomSheet(
          babyID: babyID,
          firstName: firstName,
          isEdit: true,
          existingActivity: activityModel,
        ),
      );
    } else if (activityType == ActivityType.bottleFeed.name ||
        activityType == ActivityType.breastFeed.name ||
        activityType == ActivityType.solids.name) {
      showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (_) => CustomFeedTrackerBottomSheet(
          babyID: babyID,
          firstName: firstName,
          isEdit: true,
          existingActivity: activityModel,
        ),
      );
    } else if (activityType == ActivityType.doctorVisit.name) {
      showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (_) => CustomDoctorVisitTrackerBottomSheet(
          babyID: babyID,
          firstName: firstName,
          isEdit: true,
          existingActivity: activityModel,
        ),
      );
    } else if (activityType == ActivityType.vaccination.name) {
      showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (_) => CustomVaccinationTrackerBottomSheet(
          babyID: babyID,
          firstName: firstName,
          isEdit: true,
          existingActivity: activityModel,
        ),
      );
    } else if (activityType == ActivityType.fever.name) {
      showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (_) => CustomFeverTrackerBottomSheet(
          babyID: babyID,
          firstName: firstName,
          isEdit: true,
          existingActivity: activityModel,
        ),
      );
    } else if (activityType == ActivityType.medication.name) {
      showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (_) => CustomMedicalTrackerBottomSheet(
          babyID: babyID,
          firstName: firstName,
          isEdit: true,
          existingActivity: activityModel,
        ),
      );
    } else if (activityType == ActivityType.teething.name) {
      showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (_) => CustomTeethingTrackerBottomSheet(
          babyID: babyID,
          firstName: firstName,
          isEdit: true,
          existingActivity: activityModel,
        ),
      );
    } else if (activityType == ActivityType.growth.name) {
      showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (_) => CustomGrowthDevelopmentTrackerBottomSheet(
          babyID: babyID,
          firstName: firstName,
          isEdit: true,
          existingActivity: activityModel,
        ),
      );
    } else if (activityType == ActivityType.diaper.name) {
      showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (_) => CustomDiaperTrackerBottomSheet(
          babyID: babyID,
          firstName: firstName,
          isEdit: true,
          existingActivity: activityModel,
        ),
      );
    } else if (activityType == ActivityType.pumpTotal.name ||
        activityType == ActivityType.pumpLeftRight.name) {
      showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (_) => CustomPumpTrackerBottomSheet(
          babyID: babyID,
          firstName: firstName,
          isEdit: true,
          existingActivity: activityModel,
        ),
      );
    } else if (activityType == ActivityType.sleep.name) {
      showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (_) => CustomSleepTrackerBottomSheet(
          babyID: babyID,
          firstName: firstName,
          isEdit: true,
          existingActivity: activityModel,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Unsupported'),
          content: Text('Editing this activity is not supported yet.'),
        ),
      );
    }
  }
}

class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[350], thickness: 1)),
          SizedBox(width: 10.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(child: Divider(color: Colors.grey[350], thickness: 1)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;

  const _EmptyState({this.hasFilter = false});

  @override
  Widget build(BuildContext context) {
    final emoji = hasFilter ? '🔍' : '🌸';
    final message = hasFilter
        ? context.tr('no_activities_with_filter')
        : context.tr('no_activities_date_range');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: TextStyle(fontSize: 48.sp)),
          SizedBox(height: 16.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipData {
  final String labelKey;
  final String? activityType;
  const _FilterChipData({required this.labelKey, required this.activityType});
}
