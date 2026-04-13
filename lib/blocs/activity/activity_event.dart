part of 'activity_bloc.dart';

@immutable
sealed class ActivityEvent {}

class AddActivity extends ActivityEvent {
  final ActivityModel activityModel;
  final String babyName;

  AddActivity({required this.activityModel, this.babyName = ''});
}

class StartAutoSync extends ActivityEvent {}

class StopAutoSync extends ActivityEvent {}

class FetchActivitySleepLoad extends ActivityEvent {
  final String babyID;

  FetchActivitySleepLoad({required this.babyID});
}

class FetchActivityPumpLoad extends ActivityEvent {
  final String babyID;

  FetchActivityPumpLoad({required this.babyID});
}

class FetchAllTypeOfActivity extends ActivityEvent {
  final String babyID;
  final String activityType;

  FetchAllTypeOfActivity({required this.babyID, required this.activityType});
}

class FetchToothIsoNumber extends ActivityEvent {
  final String babyID;
  final String activityType;

  FetchToothIsoNumber({required this.babyID, required this.activityType});
}

class LoadActivitiesWithDate extends ActivityEvent {
  final String babyID;
  final DateTime day;

  LoadActivitiesWithDate({required this.babyID, required this.day});
}

class LoadActivitiesByDateRange extends ActivityEvent {
  final String babyID;
  final DateTime startDay;
  final DateTime endDay;
  final String? activityType;

  LoadActivitiesByDateRange({
    required this.babyID,
    required this.startDay,
    required this.endDay,
    this.activityType,
  });
}

class DeleteActivity extends ActivityEvent {
  final String babyID;
  final String activityID;

  DeleteActivity({required this.babyID, required this.activityID});
}

class UpdateActivity extends ActivityEvent {
  final ActivityModel activityModel;

  UpdateActivity({required this.activityModel});
}
