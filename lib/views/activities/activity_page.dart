import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_baby_sara/blocs/all_timer/pump_left_side_timer/pump_left_side_timer_bloc.dart'
    as pumpLeft;
import 'package:open_baby_sara/blocs/all_timer/pump_right_side_timer/pump_right_side_timer_bloc.dart'
    as pumpRight;
import 'package:open_baby_sara/blocs/all_timer/pump_total_timer/pump_total_timer_bloc.dart'
    as pumpTotal;
import 'package:open_baby_sara/blocs/all_timer/sleep_timer/sleep_timer_bloc.dart';
import 'package:open_baby_sara/blocs/auth/auth_bloc.dart';
import 'package:open_baby_sara/blocs/baby/baby_bloc.dart';
import 'package:open_baby_sara/core/app_colors.dart';
import 'package:open_baby_sara/core/utils/shared_prefs_helper.dart';
import 'package:open_baby_sara/data/models/activity_model.dart';
import 'package:open_baby_sara/data/models/baby_model.dart';
import 'package:open_baby_sara/data/repositories/locator.dart';
import 'package:open_baby_sara/data/services/firebase/update_service.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_baby_firsts_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_diaper_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_doctor_visit_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_feed_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_fever_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_growth_development_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_medical_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_sleep_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_teething_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_vaccination_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/baby_profile_header.dart';
import 'package:open_baby_sara/widgets/custom_card.dart';
import 'package:open_baby_sara/widgets/bottom_sheets/custom_pump_tracker_bottom_sheet.dart';
import 'package:open_baby_sara/widgets/custom_today_summary_card.dart';
import 'package:open_baby_sara/widgets/customize_growth_card.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BabyBloc>().add(LoadBabies());
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthBloc, AuthState, String?>(
      selector: (state) => state is Authenticated ? state.userModel.firstName : null,
      builder: (context, firstName) {
        return BlocListener<BabyBloc, BabyState>(
          listenWhen: (previous, current) => 
              previous is! BabyLoaded && current is BabyLoaded,
          listener: (context, state) async {
            if (state is BabyLoaded) {
              final savedID = await SharedPrefsHelper.getSelectedBabyID();
              if (savedID != null) {
                final alreadySelected = state.selectedBaby?.babyID == savedID;
                if (!alreadySelected) {
                  final matched = state.babies.firstWhere(
                    (b) => b.babyID == savedID,
                    orElse: () => state.babies.first,
                  );
                  context.read<BabyBloc>().add(
                    SelectBaby(selectBabyModel: matched),
                  );
                }
              }
            }
          },
          child: BlocBuilder<BabyBloc, BabyState>(
            buildWhen: (previous, current) {
              if (current is BabyImagePathLoaded) return false;
              if (previous is BabyLoaded && current is BabyLoaded) {
                return previous.babies.length != current.babies.length ||
                    previous.selectedBaby?.babyID != current.selectedBaby?.babyID ||
                    previous.imagePath != current.imagePath;
              }
              return previous.runtimeType != current.runtimeType;
            },
            builder: (context, babyState) {
              if (babyState is BabyLoading) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              if (babyState is! BabyLoaded) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final babiesList = babyState.babies;
              final selectedBaby = babyState.selectedBaby;
              
              if (selectedBaby == null) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              return Scaffold(
                        resizeToAvoidBottomInset: true,
                        body: SafeArea(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 8.h,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ///
                                  /// Avatar Image, Age, 3 dots.
                                  ///
                                  BabyProfileHeader(babiesList: babiesList),

                                  SizedBox(height: 12.h),

                                  ///
                                  /// Today Summary
                                  ///
                                  SizedBox(
                                    width: double.infinity,
                                    child: CustomTodaySummaryCard(
                                      colorSummaryTitle:
                                          AppColors.summaryHeader,
                                      colorSummaryBody: AppColors.summaryBody,
                                      title: 'title',
                                      babyID: selectedBaby.babyID,
                                      firstName: selectedBaby.firstName,
                                    ),
                                  ),

                                  SizedBox(height: 10.h),

                                  Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      context.tr("track_new_activity"),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 10.h),

                                  ///
                                  /// Track New Activity
                                  ///
                                  _ActivityGrid(
                                    selectedBabyID: selectedBaby.babyID,
                                    firstName: firstName ?? '',
                                  ),

                                  SizedBox(height: 10.h),

                                  Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      context.tr('growth_development'),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 10.h),

                                  ///
                                  /// Growth and Development
                                  ///
                                  SizedBox(
                                    width: double.infinity,
                                    height: 88.h,
                                    child: CustomizeGrowthCard(
                                      color: AppColors.growthColor,
                                      title: 'Weight',
                                      babyID: selectedBaby.babyID,
                                      firstName: firstName ?? '',
                                      imgUrl: 'assets/images/growth_icon.png',
                                      voidCallback: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20.r),
                                            ),
                                          ),
                                          builder: (context) =>
                                              CustomGrowthDevelopmentTrackerBottomSheet(
                                            babyID: selectedBaby.babyID,
                                            firstName: firstName ?? '',
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  SizedBox(height: 6.h),

                                  _GrowthDevelopmentGrid(
                                    selectedBabyID: selectedBaby.babyID,
                                    firstName: firstName ?? '',
                                  ),
                                  SizedBox(height: 10.h),

                                  Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      context.tr('health'),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),

                                  _HealthGrid(
                                    selectedBabyID: selectedBaby.babyID,
                                    firstName: firstName ?? '',
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
      },
    );
  }

  String calculateBabyAge(DateTime birthDate) {
    debugPrint(birthDate.toString());
    final now = DateTime.now();

    if (birthDate.isAfter(now)) {
      return "0 day";
    }

    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    int days = now.day - birthDate.day;

    if (days < 0) {
      final lastDayOfPreviousMonth = DateTime(now.year, now.month, 0).day;
      days += lastDayOfPreviousMonth;
      months--;
    }

    if (months < 0) {
      months += 12;
      years--;
    }

    int totalMonths = years * 12 + months;

    String age = '';
    if (totalMonths > 0) {
      age += '$totalMonths month${totalMonths > 1 ? 's' : ''}';
    }

    if (days > 0) {
      if (age.isNotEmpty) age += ' ';
      age += '$days day${days > 1 ? 's' : ''}';
    }

    return age.isEmpty ? '0 day' : age;
  }
}

// Extracted widgets to prevent unnecessary rebuilds
class _ActivityGrid extends StatelessWidget {
  final String selectedBabyID;
  final String firstName;

  const _ActivityGrid({
    required this.selectedBabyID,
    required this.firstName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SleepTimerBloc, SleepTimerState, bool>(
      selector: (state) => state is TimerRunning,
      builder: (context, isSleepActivityRunning) {
        return BlocBuilder<pumpTotal.PumpTotalTimerBloc,
            pumpTotal.PumpTotalTimerState>(
          buildWhen: (prev, curr) =>
              (prev is pumpTotal.TimerRunning) !=
              (curr is pumpTotal.TimerRunning),
          builder: (context, pumpTotalState) {
            return BlocBuilder<pumpLeft.PumpLeftSideTimerBloc,
                pumpLeft.PumpLeftSideTimerState>(
              buildWhen: (prev, curr) =>
                  (prev is pumpLeft.TimerRunning) !=
                  (curr is pumpLeft.TimerRunning),
              builder: (context, pumpLeftState) {
                return BlocBuilder<pumpRight.PumpRightSideTimerBloc,
                    pumpRight.PumpRightSideTimerState>(
                  buildWhen: (prev, curr) =>
                      (prev is pumpRight.TimerRunning) !=
                      (curr is pumpRight.TimerRunning),
                  builder: (context, pumpRightState) {
                    final isPumpRunning =
                        pumpTotalState is pumpTotal.TimerRunning ||
                            pumpLeftState is pumpLeft.TimerRunning ||
                            pumpRightState is pumpRight.TimerRunning;

                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 6.w,
                      mainAxisSpacing: 6.h,
                      childAspectRatio: 1.6,
                      children: [
                        CustomCard(
                          color: AppColors.feedColor,
                          title: context.tr("feed"),
                          activityType: ActivityType.breastFeed.name,
                          babyID: selectedBabyID,
                          firstName: firstName,
                          imgUrl: 'assets/images/feed_icon.png',
                          voidCallback: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20.r),
                                ),
                              ),
                              builder: (context) => CustomFeedTrackerBottomSheet(
                                babyID: selectedBabyID,
                                firstName: firstName,
                              ),
                            );
                          },
                        ),
                        CustomCard(
                          color: AppColors.pumpColor,
                          title: context.tr("pump"),
                          activityType: ActivityType.pumpTotal.name,
                          babyID: selectedBabyID,
                          firstName: firstName,
                          imgUrl: 'assets/images/pump_icon.png',
                          isActivityRunning: isPumpRunning,
                          voidCallback: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20.r),
                                ),
                              ),
                              builder: (context) => CustomPumpTrackerBottomSheet(
                                babyID: selectedBabyID,
                                firstName: firstName,
                              ),
                            );
                          },
                        ),
                        CustomCard(
                          color: AppColors.diaperColor,
                          title: context.tr("diaper"),
                          activityType: ActivityType.diaper.name,
                          babyID: selectedBabyID,
                          firstName: firstName,
                          imgUrl: 'assets/images/diaper_icon.png',
                          voidCallback: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20.r),
                                ),
                              ),
                              builder: (context) =>
                                  CustomDiaperTrackerBottomSheet(
                                babyID: selectedBabyID,
                                firstName: firstName,
                              ),
                            );
                          },
                        ),
                        CustomCard(
                          color: AppColors.sleepColor,
                          title: context.tr('sleep'),
                          activityType: ActivityType.sleep.name,
                          babyID: selectedBabyID,
                          firstName: firstName,
                          imgUrl: 'assets/images/sleep_icon.png',
                          isActivityRunning: isSleepActivityRunning,
                          voidCallback: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20.r),
                                ),
                              ),
                              builder: (context) => CustomSleepTrackerBottomSheet(
                                babyID: selectedBabyID,
                                firstName: firstName,
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _GrowthDevelopmentGrid extends StatelessWidget {
  final String selectedBabyID;
  final String firstName;

  const _GrowthDevelopmentGrid({
    required this.selectedBabyID,
    required this.firstName,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 6.w,
      mainAxisSpacing: 6.h,
      childAspectRatio: 1.6,
      children: [
        CustomCard(
          color: AppColors.babyFirstsColor,
          title: context.tr('baby_firsts'),
          activityType: ActivityType.babyFirsts.name,
          babyID: selectedBabyID,
          firstName: firstName,
          imgUrl: 'assets/images/baby_firsts_icon.png',
          voidCallback: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20.r),
                ),
              ),
              builder: (context) => CustomBabyFirstsTrackerBottomSheet(
                babyID: selectedBabyID,
                firstName: firstName,
              ),
            );
          },
        ),
        CustomCard(
          color: AppColors.teethingColor,
          title: context.tr('teething'),
          activityType: ActivityType.teething.name,
          babyID: selectedBabyID,
          firstName: firstName,
          imgUrl: 'assets/images/teething_icon.png',
          voidCallback: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20.r),
                ),
              ),
              builder: (context) => CustomTeethingTrackerBottomSheet(
                babyID: selectedBabyID,
                firstName: firstName,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HealthGrid extends StatelessWidget {
  final String selectedBabyID;
  final String firstName;

  const _HealthGrid({
    required this.selectedBabyID,
    required this.firstName,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 6.w,
      mainAxisSpacing: 6.h,
      childAspectRatio: 1.6,
      children: [
        CustomCard(
          color: AppColors.medicalColor,
          title: context.tr('medication'),
          activityType: ActivityType.medication.name,
          babyID: selectedBabyID,
          firstName: firstName,
          imgUrl: 'assets/images/medication_icon.png',
          voidCallback: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20.r),
                ),
              ),
              builder: (context) => CustomMedicalTrackerBottomSheet(
                babyID: selectedBabyID,
                firstName: firstName,
              ),
            );
          },
        ),
        CustomCard(
          color: AppColors.doctorVisitColor,
          title: context.tr('doctor_visit'),
          activityType: ActivityType.doctorVisit.name,
          babyID: selectedBabyID,
          firstName: firstName,
          imgUrl: 'assets/images/doctor_visit_icon.png',
          voidCallback: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20.r),
                ),
              ),
              builder: (context) => CustomDoctorVisitTrackerBottomSheet(
                babyID: selectedBabyID,
                firstName: firstName,
              ),
            );
          },
        ),
        CustomCard(
          color: AppColors.vaccineColor,
          title: context.tr('vaccination'),
          activityType: ActivityType.vaccination.name,
          babyID: selectedBabyID,
          firstName: firstName,
          imgUrl: 'assets/images/vaccine_icon.png',
          voidCallback: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20.r),
                ),
              ),
              builder: (context) => CustomVaccinationTrackerBottomSheet(
                babyID: selectedBabyID,
                firstName: firstName,
              ),
            );
          },
        ),
        CustomCard(
          color: AppColors.feverTrackerColor,
          title: context.tr('fever'),
          activityType: ActivityType.fever.name,
          babyID: selectedBabyID,
          firstName: firstName,
          imgUrl: 'assets/images/fever_icon.png',
          voidCallback: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20.r),
                ),
              ),
              builder: (context) => CustomFeverTrackerBottomSheet(
                babyID: selectedBabyID,
                firstName: firstName,
              ),
            );
          },
        ),
      ],
    );
  }
}
