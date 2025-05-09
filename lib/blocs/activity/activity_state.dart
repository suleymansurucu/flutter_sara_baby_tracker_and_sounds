part of 'activity_bloc.dart';

@immutable
sealed class ActivityState {}

final class ActivityInitial extends ActivityState {}

final class ActivityAdded extends ActivityState {
  final String message;

  ActivityAdded({this.message = 'Successfully'});
}

class ActivityError extends ActivityState {
  final String message;

  ActivityError(this.message);
}

class SleepActivityLoaded extends ActivityState {
  final ActivityModel? activityModel;

  SleepActivityLoaded({this.activityModel});
}

class PumpActivityLoaded extends ActivityState{
  final ActivityModel? activityModel;

  PumpActivityLoaded({required this.activityModel});

}
