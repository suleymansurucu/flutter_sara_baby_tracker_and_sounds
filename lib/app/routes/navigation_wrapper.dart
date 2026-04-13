import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_baby_sara/blocs/activity/activity_bloc.dart';
// Timer bloc'ları alias ile import edilir — her bloc'ta TimerRunning/Stopped/Reset
// aynı isme sahip olduğu için prefix olmadan kullanılırsa Dart derleme hatası verir.
import 'package:open_baby_sara/blocs/all_timer/sleep_timer/sleep_timer_bloc.dart'
    as sleep_timer;
import 'package:open_baby_sara/blocs/all_timer/breasfeed_left_side_timer/breasfeed_left_side_timer_bloc.dart'
    as bf_left;
import 'package:open_baby_sara/blocs/all_timer/breastfeed_right_side_timer/breastfeed_right_side_timer_bloc.dart'
    as bf_right;
import 'package:open_baby_sara/blocs/all_timer/pump_total_timer/pump_total_timer_bloc.dart'
    as pump_total;
import 'package:open_baby_sara/blocs/all_timer/pump_left_side_timer/pump_left_side_timer_bloc.dart'
    as pump_left;
import 'package:open_baby_sara/blocs/all_timer/pump_right_side_timer/pump_right_side_timer_bloc.dart'
    as pump_right;
import 'package:open_baby_sara/blocs/baby/baby_bloc.dart';
import 'package:open_baby_sara/blocs/bottom_nav/bottom_nav_bloc.dart';
import 'package:open_baby_sara/blocs/theme/theme_bloc.dart';
import 'package:open_baby_sara/core/utils/check_for_update.dart';
import 'package:open_baby_sara/core/widget_bridge/widget_bridge_service.dart';
import 'package:open_baby_sara/data/repositories/locator.dart';
import 'package:open_baby_sara/data/services/firebase/analytics_service.dart';
import 'package:open_baby_sara/data/services/notification_service.dart';
import 'package:open_baby_sara/views/account/account_page.dart';
import 'package:open_baby_sara/views/activities/activity_page.dart';
import 'package:open_baby_sara/views/history/history_page.dart';
import 'package:open_baby_sara/views/food_recipes/recipes_page.dart';
import 'package:open_baby_sara/views/background_sounds/baby_relaxing_sounds_page.dart';

class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({super.key});

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper>
    with WidgetsBindingObserver {
  String? _lastScheduledMilestoneBabyId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BabyBloc>().add(LoadBabies());
      // Request notification permission for users who missed the onboarding
      // screen (existing users, Google sign-in users, etc.).
      _ensureNotificationPermission();
    });
    getIt<AnalyticsService>().logScreenView('ActivityPage');
    checkAppUpdate(context);
  }

  /// Silently request notification permission if not yet granted.
  /// Only asks once — subsequent app opens skip if already decided.
  Future<void> _ensureNotificationPermission() async {
    final already = await NotificationService.instance.hasPermission;
    if (already) return;
    await NotificationService.instance.requestPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.resumed && mounted) {
      _refreshWidgets();
    }
  }

  void _refreshWidgets() {
    final babyState = context.read<BabyBloc>().state;
    final themeState = context.read<ThemeBloc>().state;
    if (babyState is! BabyLoaded || babyState.selectedBaby == null) return;
    WidgetBridgeService.refreshAllWidgets(
      babyName: babyState.selectedBaby!.firstName,
      isGirlTheme: themeState is ThemeInitial && themeState.gender == 'Girl',
    );
  }

  void _updateBreastfeedWidget(BuildContext context) {
    final babyState = context.read<BabyBloc>().state;
    final themeState = context.read<ThemeBloc>().state;
    if (babyState is! BabyLoaded || babyState.selectedBaby == null) return;

    final leftState =
        context.read<bf_left.BreasfeedLeftSideTimerBloc>().state;
    final rightState =
        context.read<bf_right.BreastfeedRightSideTimerBloc>().state;

    DateTime? lastEndTime;
    if (leftState is bf_left.TimerStopped && leftState.endTime != null) {
      lastEndTime = leftState.endTime;
    }
    if (rightState is bf_right.TimerStopped && rightState.endTime != null) {
      if (lastEndTime == null || rightState.endTime!.isAfter(lastEndTime)) {
        lastEndTime = rightState.endTime;
      }
    }

    WidgetBridgeService.updateBreastfeedWidget(
      leftRunning: leftState is bf_left.TimerRunning,
      leftStartTime:
          leftState is bf_left.TimerRunning ? leftState.startTime : null,
      rightRunning: rightState is bf_right.TimerRunning,
      rightStartTime:
          rightState is bf_right.TimerRunning ? rightState.startTime : null,
      lastEndTime: lastEndTime,
      babyName: babyState.selectedBaby!.firstName,
      isGirlTheme: themeState is ThemeInitial && themeState.gender == 'Girl',
    );
  }

  /// Pump widget'ını 3 bloc'un (total, left, right) güncel state'iyle günceller.
  /// totalTimer çalışıyorsa mode='total', left/right çalışıyorsa mode='leftRight'.
  void _updatePumpWidget(BuildContext context) {
    final babyState = context.read<BabyBloc>().state;
    final themeState = context.read<ThemeBloc>().state;
    if (babyState is! BabyLoaded || babyState.selectedBaby == null) return;

    final totalState =
        context.read<pump_total.PumpTotalTimerBloc>().state;
    final leftState =
        context.read<pump_left.PumpLeftSideTimerBloc>().state;
    final rightState =
        context.read<pump_right.PumpRightSideTimerBloc>().state;

    final totalRunning = totalState is pump_total.TimerRunning;
    final lrRunning = leftState is pump_left.TimerRunning ||
        rightState is pump_right.TimerRunning;

    final String mode;
    if (totalRunning) {
      mode = 'total';
    } else if (lrRunning) {
      mode = 'leftRight';
    } else {
      mode = totalState is pump_total.TimerStopped ? 'total' : 'leftRight';
    }

    DateTime? lastEndTime;
    if (totalState is pump_total.TimerStopped &&
        totalState.endTime != null) {
      lastEndTime = totalState.endTime;
    }
    if (leftState is pump_left.TimerStopped && leftState.endTime != null) {
      if (lastEndTime == null || leftState.endTime!.isAfter(lastEndTime)) {
        lastEndTime = leftState.endTime;
      }
    }
    if (rightState is pump_right.TimerStopped &&
        rightState.endTime != null) {
      if (lastEndTime == null || rightState.endTime!.isAfter(lastEndTime)) {
        lastEndTime = rightState.endTime;
      }
    }

    WidgetBridgeService.updatePumpWidget(
      isRunning: totalRunning || lrRunning,
      startTime: totalRunning
          ? totalState.startTime
          : leftState is pump_left.TimerRunning
              ? leftState.startTime
              : rightState is pump_right.TimerRunning
                  ? rightState.startTime
                  : null,
      lastEndTime: lastEndTime,
      pumpMode: mode,
      babyName: babyState.selectedBaby!.firstName,
      isGirlTheme: themeState is ThemeInitial && themeState.gender == 'Girl',
    );
  }

  void _scheduleMilestones(
    BuildContext context,
    DateTime birthDate,
    String babyName,
  ) {
    final titles = {
      for (int m = 1; m <= 24; m++)
        m: context.tr(
          'notif_milestone_title',
          namedArgs: {'name': babyName, 'month': '$m'},
        ),
    };
    final bodies = {
      for (int m = 1; m <= 24; m++)
        m: context.tr(
          'notif_milestone_body',
          namedArgs: {'name': babyName, 'month': '$m'},
        ),
    };

    NotificationService.instance.scheduleMilestoneNotifications(
      birthDate: birthDate,
      titleBuilder: (month) => titles[month] ?? '',
      bodyBuilder: (month) => bodies[month] ?? '',
    );
  }

  Future<void> _handleActivityAdded(
    BuildContext context,
    ActivityAdded state,
  ) async {
    final babyState = context.read<BabyBloc>().state;
    final fallbackName = babyState is BabyLoaded
        ? (babyState.selectedBaby?.firstName ?? '')
        : '';
    final babyName =
        state.babyName.isNotEmpty ? state.babyName : fallbackName;
    final type = state.activityType;

    final isFeed = type == 'breastFeed' ||
        type == 'bottleFeed' ||
        type == 'solids' ||
        type == 'pumpTotal' ||
        type == 'pumpLeftRight';
    final isSleep = type == 'sleep';

    final sleepTitle = context.tr('notif_sleep_title');
    final sleepBody =
        context.tr('notif_sleep_body', namedArgs: {'name': babyName});
    final feedTitle = context.tr('notif_feed_title');
    final feedBody =
        context.tr('notif_feed_body', namedArgs: {'name': babyName});

    final settings = await NotificationService.instance.loadSettings();

    if (isSleep && settings.sleepRemindersEnabled) {
      await NotificationService.instance.scheduleSleepReminder(
        babyName: babyName,
        title: sleepTitle,
        body: sleepBody,
      );
    }

    if (isFeed && settings.feedRemindersEnabled) {
      await NotificationService.instance.scheduleFeedReminder(
        title: feedTitle,
        body: feedBody,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HistoryPage(),
      BabyRelaxingSoundsPage(),
      ActivityPage(),
      RecipesPage(),
      AccountPage(),
    ];
    return MultiBlocListener(
      listeners: [
        BlocListener<BabyBloc, BabyState>(
          listenWhen: (_, s) => s is BabyLoaded,
          listener: (context, state) {
            if (state is BabyLoaded && state.selectedBaby != null) {
              final baby = state.selectedBaby!;
              if (baby.babyID == _lastScheduledMilestoneBabyId) return;
              _lastScheduledMilestoneBabyId = baby.babyID;
              _scheduleMilestones(context, baby.dateTime, baby.firstName);
            }
          },
        ),
        BlocListener<ActivityBloc, ActivityState>(
          listenWhen: (_, s) => s is ActivityAdded,
          listener: (context, state) {
            if (state is ActivityAdded) {
              _handleActivityAdded(context, state);
            }
          },
        ),

        // ── Sleep widget ──────────────────────────────────────────────────
        BlocListener<sleep_timer.SleepTimerBloc, sleep_timer.SleepTimerState>(
          listenWhen: (prev, curr) {
            if (curr is sleep_timer.TimerReset) return true;
            if (prev is sleep_timer.TimerRunning &&
                curr is sleep_timer.TimerStopped) return true;
            if (prev is! sleep_timer.TimerRunning &&
                curr is sleep_timer.TimerRunning) return true;
            return false;
          },
          listener: (context, sleepState) {
            final babyState = context.read<BabyBloc>().state;
            final themeState = context.read<ThemeBloc>().state;
            if (babyState is! BabyLoaded || babyState.selectedBaby == null) {
              return;
            }
            final babyName = babyState.selectedBaby!.firstName;
            final isGirlTheme =
                themeState is ThemeInitial && themeState.gender == 'Girl';

            if (sleepState is sleep_timer.TimerRunning) {
              WidgetBridgeService.updateSleepWidget(
                isRunning: true,
                startTime: sleepState.startTime,
                babyName: babyName,
                isGirlTheme: isGirlTheme,
              );
            } else if (sleepState is sleep_timer.TimerStopped) {
              WidgetBridgeService.updateSleepWidget(
                isRunning: false,
                lastDurationSeconds: sleepState.duration.inSeconds,
                lastEndTime: sleepState.endTime,
                babyName: babyName,
                isGirlTheme: isGirlTheme,
              );
            } else if (sleepState is sleep_timer.TimerReset) {
              WidgetBridgeService.updateSleepWidget(
                isRunning: false,
                babyName: babyName,
                isGirlTheme: isGirlTheme,
              );
            }
          },
        ),

        // ── Breastfeed widget — sol taraf ─────────────────────────────────
        BlocListener<bf_left.BreasfeedLeftSideTimerBloc,
            bf_left.BreasfeedLeftSideTimerState>(
          listenWhen: (prev, curr) {
            if (curr is bf_left.TimerReset) { return true; }
            if (prev is bf_left.TimerRunning && curr is bf_left.TimerStopped) {
              return true;
            }
            if (prev is! bf_left.TimerRunning && curr is bf_left.TimerRunning) {
              return true;
            }
            return false;
          },
          listener: (context, _) => _updateBreastfeedWidget(context),
        ),

        // ── Breastfeed widget — sağ taraf ─────────────────────────────────
        BlocListener<bf_right.BreastfeedRightSideTimerBloc,
            bf_right.BreastfeedRightSideTimerState>(
          listenWhen: (prev, curr) {
            if (curr is bf_right.TimerReset) { return true; }
            if (prev is bf_right.TimerRunning && curr is bf_right.TimerStopped) {
              return true;
            }
            if (prev is! bf_right.TimerRunning && curr is bf_right.TimerRunning) {
              return true;
            }
            return false;
          },
          listener: (context, _) => _updateBreastfeedWidget(context),
        ),

        // ── Pump widget — total timer ──────────────────────────────────────
        BlocListener<pump_total.PumpTotalTimerBloc,
            pump_total.PumpTotalTimerState>(
          listenWhen: (prev, curr) {
            if (curr is pump_total.TimerReset) { return true; }
            if (prev is pump_total.TimerRunning && curr is pump_total.TimerStopped) {
              return true;
            }
            if (prev is! pump_total.TimerRunning && curr is pump_total.TimerRunning) {
              return true;
            }
            return false;
          },
          listener: (context, _) => _updatePumpWidget(context),
        ),

        // ── Pump widget — sol taraf ────────────────────────────────────────
        BlocListener<pump_left.PumpLeftSideTimerBloc,
            pump_left.PumpLeftSideTimerState>(
          listenWhen: (prev, curr) {
            if (curr is pump_left.TimerReset) { return true; }
            if (prev is pump_left.TimerRunning && curr is pump_left.TimerStopped) {
              return true;
            }
            if (prev is! pump_left.TimerRunning && curr is pump_left.TimerRunning) {
              return true;
            }
            return false;
          },
          listener: (context, _) => _updatePumpWidget(context),
        ),

        // ── Pump widget — sağ taraf ────────────────────────────────────────
        BlocListener<pump_right.PumpRightSideTimerBloc,
            pump_right.PumpRightSideTimerState>(
          listenWhen: (prev, curr) {
            if (curr is pump_right.TimerReset) { return true; }
            if (prev is pump_right.TimerRunning && curr is pump_right.TimerStopped) {
              return true;
            }
            if (prev is! pump_right.TimerRunning && curr is pump_right.TimerRunning) {
              return true;
            }
            return false;
          },
          listener: (context, _) => _updatePumpWidget(context),
        ),
      ],
      child: BlocBuilder<BottomNavBloc, BottomNavState>(
        builder: (context, state) {
          final int currentIndex =
              state is BottomNavNext ? state.selectedIndex : 2;

          return Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: true,
            bottomNavigationBar: _FloatingNavBar(
              currentIndex: currentIndex,
              onTap: (int index) {
                context.read<BottomNavBloc>().add(NavItemSelected(index));
                const screenNames = [
                  'HistoryPage',
                  'BabyRelaxingSoundsPage',
                  'ActivityPage',
                  'RecipesPage',
                  'AccountPage',
                ];
                getIt<AnalyticsService>().logScreenView(screenNames[index]);
              },
              labels: [
                context.tr('history'),
                context.tr('sounds'),
                context.tr('activity'),
                context.tr('recipes'),
                context.tr('profile'),
              ],
            ),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF5E6E8), Color(0xFFF6F5F5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(child: pages[currentIndex]),
            ),
          );
        },
      ),
    );
  }
}

// ── Custom bottom navigation bar ──────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<String> labels;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.labels,
  });

  static const _navBg = Colors.deepPurpleAccent;

  // Outlined: seçilmemiş, Filled: seçili — görsel ayrım için
  static const _iconsOutlined = [
    Icons.history_outlined,
    Icons.surround_sound_outlined,
    Icons.local_activity_outlined,
    Icons.receipt_long_outlined,
    Icons.account_circle_outlined,
  ];

  static const _iconsFilled = [
    Icons.history,
    Icons.surround_sound,
    Icons.local_activity,
    Icons.receipt_long,
    Icons.account_circle,
  ];

  @override
  Widget build(BuildContext context) {
    final indicatorColor = Theme.of(context).colorScheme.primary;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _navBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          // Sabit 60dp — viewport-relative değil, tüm ekranlarda aynı yükseklik
          height: 60,
          child: Row(
            children: List.generate(labels.length, (i) {
              return Expanded(
                child: Semantics(
                  label: labels[i],
                  selected: i == currentIndex,
                  button: true,
                  child: _NavItem(
                    iconOutlined: _iconsOutlined[i],
                    iconFilled: _iconsFilled[i],
                    label: labels[i],
                    isSelected: i == currentIndex,
                    indicatorColor: indicatorColor,
                    onTap: () => onTap(i),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData iconOutlined;
  final IconData iconFilled;
  final String label;
  final bool isSelected;
  final Color indicatorColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.iconOutlined,
    required this.iconFilled,
    required this.label,
    required this.isSelected,
    required this.indicatorColor,
    required this.onTap,
  });

  // Unselected: icon ve text aynı opacity — tutarlılık
  static const _unselectedColor = Color(0xADFFFFFF); // white %68

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 52,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected
                  ? indicatorColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isSelected ? iconFilled : iconOutlined,
              size: 20,
              color: isSelected ? Colors.white : _unselectedColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : _unselectedColor,
              fontSize: 11.5.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
