import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:open_baby_sara/core/constant/activity_constants.dart';
import 'package:open_baby_sara/data/repositories/locator.dart';
import 'package:open_baby_sara/data/models/activity_model.dart';
import 'package:open_baby_sara/data/repositories/activity_reposityory.dart';
import 'package:open_baby_sara/data/services/firebase/analytics_service.dart';
import 'package:open_baby_sara/data/services/review_service.dart';

part 'activity_event.dart';

part 'activity_state.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ActivityRepository _activityRepository = getIt<ActivityRepository>();
  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  ActivityBloc() : super(ActivityInitial()) {
    on<AddActivity>((event, emit) async {
      try {
        _activityRepository.saveLocallyActivity(event.activityModel);
        getIt<AnalyticsService>().logActivitySaved(
          event.activityModel.babyID,
          event.activityModel.activityType,
        );
        await ReviewService().incrementRecordCount();
        emit(ActivityAdded(
          activityType: event.activityModel.activityType,
          babyName: event.babyName,
        ));
        add(LoadActivitiesWithDate(
          babyID: event.activityModel.babyID,
          day: DateTime.now(),
        ));
      } catch (e) {
        emit(ActivityError(e.toString()));
      }
    });

    on<StartAutoSync>((event, emit) {
      _syncTimer?.cancel();
      _connectivitySubscription?.cancel();

      // Immediately sync when connectivity is restored
      _connectivitySubscription = Connectivity()
          .onConnectivityChanged
          .listen((results) async {
        final isOnline =
            results.isNotEmpty &&
            !results.contains(ConnectivityResult.none);
        if (isOnline) {
          try {
            await _activityRepository.syncActivities();
          } catch (e) {
            debugPrint('Connectivity-triggered sync error: $e');
          }
        }
      });

      // Periodic fallback every 5 minutes (handles staying online)
      _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
        try {
          final connectivityResults =
              await Connectivity().checkConnectivity();
          if (!connectivityResults.contains(ConnectivityResult.none) &&
              connectivityResults.isNotEmpty) {
            await _activityRepository.syncActivities();
          }
        } catch (e) {
          debugPrint('Periodic sync error: $e');
        }
      });
    });

    on<StopAutoSync>((event, emit) {
      _syncTimer?.cancel();
      _connectivitySubscription?.cancel();
      _syncTimer = null;
      _connectivitySubscription = null;
    });

    on<FetchActivitySleepLoad>((event, emit) async {
      final result = await _activityRepository.fetchLastSleepActivity(
        event.babyID,
      );
      emit(SleepActivityLoaded(activityModel: result));
    });

    on<FetchActivityPumpLoad>((event, emit) async {
      final result = await _activityRepository.fetchLastPumpActivity(
        event.babyID,
      );
      emit(PumpActivityLoaded(activityModel: result));
    });

    on<FetchToothIsoNumber>((event, emit) async {
      try {
        emit(TeethingLoading());

        final List<ActivityModel>? result = await _activityRepository
            .fetchAllTypeOfActivity(event.babyID, event.activityType);

        final List<String> toothIsoNumberList = [];

        if (result != null) {
          for (final activity in result) {
            final dynamic teeth = activity.data['teethingIsoNumber'];
            if (teeth is List) {
              toothIsoNumberList.addAll(teeth.map((e) => e.toString()));
            } else if (teeth is String) {
              toothIsoNumberList.add(teeth);
            }
          }
        }

        emit(
          FetchToothIsoNumberLoaded(
            toothIsoNumber: toothIsoNumberList,
            toothActivities: result ?? [],
          ),
        );
      } catch (e) {
        emit(ActivityError(e.toString()));
      }
    });

    on<LoadActivitiesWithDate>((event, emit) async {
      emit(ActivityLoading());
      try {
        // Pull latest from Firestore first when online (two-way sync)
        final connectivityResults = await Connectivity().checkConnectivity();
        if (!connectivityResults.contains(ConnectivityResult.none) &&
            connectivityResults.isNotEmpty) {
          await _activityRepository.fullSync(event.babyID);
        }

        final allActivity = await _activityRepository.fetchActivity(
          event.day,
          event.babyID,
        );
        if (allActivity != null) {
          final sleepActivities =
              allActivity.where((a) => a.activityType == 'sleep').toList();
          final diaperActivities =
              allActivity.where((a) => a.activityType == 'diaper').toList();

          final pumpTotalActivities =
              allActivity.where((a) => a.activityType == 'pumpTotal').toList();
          final pumpLeftRightActivities =
              allActivity
                  .where((a) => a.activityType == 'pumpLeftRight')
                  .toList();
          final List<ActivityModel> pumpActivities = [];
          pumpActivities.addAll(pumpTotalActivities);
          pumpActivities.addAll(pumpLeftRightActivities);

          final breastFeedActivities =
              allActivity
                  .where((a) => a.activityType == 'breastFeed')
                  .toList();
          final bottleFeedActivities =
              allActivity
                  .where((a) => a.activityType == 'bottleFeed')
                  .toList();
          final solidsActivities =
              allActivity.where((a) => a.activityType == 'solids').toList();
          final List<ActivityModel> feedActivities = [];
          feedActivities.addAll(breastFeedActivities);
          feedActivities.addAll(bottleFeedActivities);
          feedActivities.addAll(solidsActivities);

          final growthActivities =
              allActivity.where((a) => a.activityType == 'growth').toList();
          final babyFirstsActivities =
              allActivity
                  .where((a) => a.activityType == 'babyFirsts')
                  .toList();
          final teethingActivities =
              allActivity.where((a) => a.activityType == 'teething').toList();
          final medicationActivities =
              allActivity
                  .where((a) => a.activityType == 'medication')
                  .toList();
          final feverActivities =
              allActivity.where((a) => a.activityType == 'fever').toList();
          final vaccinationActivities =
              allActivity
                  .where((a) => a.activityType == 'vaccination')
                  .toList();
          final doctorVisitActivities =
              allActivity
                  .where((a) => a.activityType == 'doctorVisit')
                  .toList();

          emit(
            ActivitiesWithDateLoaded(
              sleepActivities: sleepActivities,
              diaperActivities: diaperActivities,
              growthActivities: growthActivities,
              babyFirstsActivities: babyFirstsActivities,
              pumpActivities: pumpActivities,
              teethingActivities: teethingActivities,
              medicationActivities: medicationActivities,
              feverActivities: feverActivities,
              vaccinationActivities: vaccinationActivities,
              doctorVisitActivities: doctorVisitActivities,
              feedActivities: feedActivities,
            ),
          );
        }
      } catch (e) {
        emit(ActivityError('Error, ${e.toString()}'));
      }
    });

    on<LoadActivitiesByDateRange>((event, emit) async {
      emit(ActivityLoading());

      try {
        final selectedDisplayType = event.activityType ?? 'All Activities';
        final dbTypes = activityTypeMap[selectedDisplayType] ?? [];

        final results = await _activityRepository.fetchActivityByDateRange(
          start: event.startDay,
          end: event.endDay,
          babyID: event.babyID,
          activityTypes: dbTypes.isEmpty ? null : dbTypes,
        );
        emit(ActivityByDateRangeLoaded(activities: results ?? []));
      } catch (e) {
        emit(ActivityError('Error, ${e.toString()}'));
      }
    });

    on<DeleteActivity>((event, emit) async {
      emit(ActivityLoading());
      try {
        await _activityRepository.deleteActivity(
          event.babyID,
          event.activityID,
        );
        emit(ActivityDeleted());
      } catch (e) {
        emit(ActivityError('Error ${e.toString()}'));
      }
    });

    on<UpdateActivity>((event, emit) async {
      emit(ActivityLoading());
      try {
        await _activityRepository.updateActivity(event.activityModel);
        emit(ActivityUpdated());
      } catch (e) {
        emit(ActivityUpdateError(e.toString()));
      }
    });
  }

  @override
  Future<void> close() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
