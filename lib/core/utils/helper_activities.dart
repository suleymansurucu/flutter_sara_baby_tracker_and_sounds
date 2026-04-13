import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:open_baby_sara/core/constant/iso_tooth_descriptions_constants.dart';
import 'package:open_baby_sara/data/models/activity_model.dart';

/// Calculates the total feed amount from a list of feed activities.
double calculateTotalFeedAmount(List<ActivityModel> feedActivities) {
  return feedActivities.fold(
    0.0,
    (sum, activity) => sum + ((activity.data['totalAmount'] ?? 0).toDouble()),
  );
}

String getFeedUnit(List<ActivityModel> feedActivities) {
  for (final activity in feedActivities) {
    final unit = activity.data['totalUnit'];
    if (unit != null && unit is String && unit.trim().isNotEmpty) {
      return unit;
    }
  }
  return 'ml';
}

double calculateTotalPumpAmount(List<ActivityModel> pumpActivities) {
  return pumpActivities.fold(
    0.0,
    (sum, activity) => sum + ((activity.data['totalAmount'] ?? 0).toDouble()),
  );
}

String? getPumpUnit(List<ActivityModel> pumpActivities) {
  return pumpActivities.isNotEmpty
      ? pumpActivities.first.data['totalUnit'] as String?
      : null;
}

String formatSleepDuration(List<ActivityModel> sleepActivities) {
  final totalMillis = sleepActivities.fold<int>(
    0,
    (sum, activity) => sum + ((activity.data['totalTime'] ?? 0) as int),
  );
  final duration = Duration(milliseconds: totalMillis);
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  return '${hours}h ${minutes}m';
}

String summarizeDiaperTypes(
  List<ActivityModel> diaperActivities,
  BuildContext context,
) {
  int wetOnly = 0, dirtyOnly = 0, wetAndDirty = 0, dry = 0;

  for (final activity in diaperActivities) {
    final List selectedTypes = activity.data['mainSelection'] ?? [];
    final hasWet = selectedTypes.contains('Wet');
    final hasDirty = selectedTypes.contains('Dirty');
    final hasDry = selectedTypes.contains('Dry');

    if (hasWet && hasDirty) {
      wetAndDirty++;
    } else if (hasWet) {
      wetOnly++;
    } else if (hasDirty) {
      dirtyOnly++;
    } else if (hasDry) {
      dry++;
    }
  }

  final parts = <String>[];
  if (wetAndDirty > 0) parts.add('$wetAndDirty ${context.tr('mixed')}');
  if (wetOnly > 0) parts.add('$wetOnly ${context.tr('wet')}');
  if (dirtyOnly > 0) parts.add('$dirtyOnly ${context.tr('dirty')}');
  if (dry > 0) parts.add('$dry ${context.tr('dry')}');

  return parts.join(', ');
}

/// Calculates to Last Activities

ActivityModel? getLastActivity(List<ActivityModel> activities) {
  if (activities.isEmpty) return null;

  return activities.reduce(
    (a, b) => a.activityDateTime.isAfter(b.activityDateTime) ? a : b,
  );
}

/// Formats a date/time smartly relative to today, fully localized.
String? formatSmartDate(DateTime time, BuildContext context) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateOnly = DateTime(time.year, time.month, time.day);
  final diff = today.difference(dateOnly).inDays;

  if (diff > 7) return null;

  final locale = context.locale.toLanguageTag();
  final timeStr = DateFormat.jm(locale).format(time);

  if (diff == 0) {
    return timeStr;
  } else if (diff == 1) {
    return context.tr('yesterday_at', namedArgs: {'time': timeStr});
  } else {
    return '${DateFormat.MMMd(locale).format(time)}, $timeStr';
  }
}

String? getLastFeedSummary(
  List<ActivityModel> activities,
  BuildContext context,
) {
  final last = getLastActivity(activities);
  if (last == null) return '➕ ${context.tr('tap_to_start_only')}';

  final timeText = formatSmartDate(last.activityDateTime, context);
  if (timeText == null) return '➕\n${context.tr('tap_to_start_only')}';

  // Bug #2 fix: show left/right side duration for breastFeed activities
  if (last.activityType == 'breastFeed') {
    final leftMs = (last.data['leftSideTotalTime'] as num?)?.toInt() ?? 0;
    final rightMs = (last.data['rightSideTotalTime'] as num?)?.toInt() ?? 0;
    final parts = <String>[];
    if (leftMs > 0) {
      final d = Duration(milliseconds: leftMs);
      final m = d.inMinutes;
      final s = d.inSeconds % 60;
      parts.add('L: ${m > 0 ? '${m}m ' : ''}${s}s');
    }
    if (rightMs > 0) {
      final d = Duration(milliseconds: rightMs);
      final m = d.inMinutes;
      final s = d.inSeconds % 60;
      parts.add('R: ${m > 0 ? '${m}m ' : ''}${s}s');
    }
    if (parts.isNotEmpty) {
      return '${parts.join(' · ')}\n$timeText';
    }
    return '${context.tr('last_feed')} at\n$timeText';
  }

  final amount = last.data['totalAmount']?.toString() ?? '';
  final unit = last.data['totalUnit']?.toString() ?? '';

  if (amount.isNotEmpty && unit.isNotEmpty && amount != '0' && amount != '0.0') {
    return '${context.tr('last_feed')} $amount $unit\nat $timeText';
  }

  return '${context.tr('last_feed')} at\n$timeText';
}

String? getLastSleepSummary(
  List<ActivityModel> activities,
  bool? isRunning,
  BuildContext context,
) {
  debugPrint(isRunning.toString());
  if (isRunning == true) {
    return '💤 ${context.tr('your_baby_is_now_sleeping')}';
  } else if (isRunning == false) {
    final last = getLastActivity(activities);
    if (last == null) return '➕ ${context.tr('tap_to_start_only')}';

    final endHour = last.data['endTimeHour'];
    final endMin = last.data['endTimeMin'];

    if (endHour == null || endMin == null) {
      return '➕\n${context.tr('tap_to_start_only')}';
    }

    final timeOfDay = TimeOfDay(hour: endHour, minute: endMin);
    final timeText = timeOfDay.format(context);

    final durationMs = last.data['totalTime'] ?? 0;
    final duration = Duration(milliseconds: durationMs);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    final durationText =
        hours > 0 && minutes > 0
            ? '${hours}h ${minutes}m'
            : hours > 0
            ? '${hours}h'
            : '${minutes}m';

    return '${context.tr('woke_up_at')} $timeText\n($durationText ${context.tr('sleep')})';
  }
  return null;
}

String? getLastDiaperSummary(
  List<ActivityModel> activities,
  BuildContext context,
) {
  final last = getLastActivity(activities);
  if (last == null) return '➕ ${context.tr('tap_to_start_only')}';

  final timeText = formatSmartDate(last.activityDateTime, context);
  if (timeText == null) return '➕\n${context.tr('tap_to_start_only')}';

  final types = (last.data['mainSelection'] ?? []).join(' & ');
  return '$types \nat $timeText';
}

String? getLastPumpSummary(
  List<ActivityModel> activities,
  BuildContext context,
) {
  final last = getLastActivity(activities);
  if (last == null) return '➕ ${context.tr('tap_to_start_only')}';

  final timeText = formatSmartDate(last.activityDateTime, context);
  if (timeText == null) return '➕\n${context.tr('tap_to_start_only')}';

  final amount = last.data['totalAmount'] ?? '';
  final unit = last.data['totalUnit'] ?? '';

  if (amount.toString().isNotEmpty && unit.toString().isNotEmpty) {
    return '${context.tr('last_pump')} $amount $unit\nat $timeText';
  }

  return '${context.tr('last_pump')} at\n$timeText';
}

String? getLastWeight(List<ActivityModel> activities, BuildContext context) {
  final weightActivities =
      activities
          .where(
            (a) =>
                a.data['weight'] != null &&
                a.data['weight'].toString().trim().isNotEmpty,
          )
          .toList();

  final last = getLastActivity(weightActivities);
  if (last == null) return '➕\n ${context.tr('tap_to_start_only')}';

  final timeText = formatSmartDate(last.activityDateTime, context);
  if (timeText == null) return '➕ \n${context.tr('tap_to_start_only')}';

  final weight = last.data['weight'] ?? '';
  final unit = last.data['weightUnit'] ?? '';
  return '$weight $unit \nat $timeText';
}

String? getLastHeight(List<ActivityModel> activities, BuildContext context) {
  final heightActivities =
      activities
          .where(
            (a) =>
                a.data.containsKey('height') &&
                a.data['height'] != null &&
                a.data['height'].toString().trim().isNotEmpty,
          )
          .toList();
  final last = getLastActivity(heightActivities);
  if (last == null) return '➕\n ${context.tr('tap_to_start_only')}';

  final timeText = formatSmartDate(last.activityDateTime, context);
  if (timeText == null) return '➕\n ${context.tr('tap_to_start_only')}';

  final height = last.data['height'] ?? '';
  final heightUnit = last.data['heightUnit'] ?? '';
  return '$height $heightUnit \nat $timeText';
}

String? getLastHeadSize(List<ActivityModel> activities, BuildContext context) {
  final headSizeActivities =
      activities
          .where(
            (a) =>
                a.data.containsKey('headSize') &&
                a.data['headSize'] != null &&
                a.data['headSize'].toString().trim().isNotEmpty,
          )
          .toList();
  final last = getLastActivity(headSizeActivities);
  if (last == null) return '➕\n ${context.tr('tap_to_start_only')}';

  final timeText = formatSmartDate(last.activityDateTime, context);
  if (timeText == null) return '➕\n ${context.tr('tap_to_start_only')}';

  final headSize = last.data['headSize'] ?? '';
  final headSizeUnit = last.data['headSizeUnit'] ?? '';
  return '$headSize $headSizeUnit \nat $timeText';
}

String? getLastBabyFirstsSummary(
  List<ActivityModel> activities,
  BuildContext context,
) {
  final last = getLastActivity(activities);
  if (last == null) return '➕ ${context.tr('tap_to_start_only')}';

  final timeText = formatSmartDate(last.activityDateTime, context);
  if (timeText == null) return '➕\n ${context.tr('tap_to_start_only')}';

  final milestoneTitle = (last.data['milestoneTitle'] ?? []).join(' & ');
  final milestoneDesc = (last.data['milestoneDesc'] ?? []).join(' & ');

  return '${context.tr(milestoneTitle)}\n${context.tr(milestoneDesc)}';
}

String? getLastTeethingSummary(
  List<ActivityModel> activities,
  BuildContext context,
) {
  final last = getLastActivity(activities);
  if (last == null) return '➕ ${context.tr('tap_to_start_only')}';

  final timeText = formatSmartDate(last.activityDateTime, context);
  if (timeText == null) return '➕\n${context.tr('tap_to_start_only')}';

  final rawTeethingData = last.data['teethingIsoNumber'];
  List<String> teethingNumbers;

  if (rawTeethingData is List) {
    teethingNumbers = rawTeethingData.map((e) => e.toString()).toList();
  } else if (rawTeethingData is String) {
    teethingNumbers = rawTeethingData.split(',').map((e) => e.trim()).toList();
  } else {
    teethingNumbers = [];
  }

  final isErupted = last.data['isErupted'] == true;
  final isShed = last.data['isShed'] == true;

  String status = '';
  if (isErupted) {
    status = context.tr('Tooth erupted');
  } else if (isShed) {
    status = context.tr('Tooth shed');
  } else {
    status = context.tr('Teething activity');
  }

  final List<String> descriptions =
      teethingNumbers.map((isoNum) {
        final key = isoToothDescriptions[isoNum];
        return key != null ? context.tr(key) : '${context.tr('tooth')} $isoNum';
      }).toList();

  final descriptionText = descriptions.join(', ');

  return '$status\n$descriptionText';
}

String? getLastFeverSummary(
  List<ActivityModel> activities,
  BuildContext context,
) {
  final last = getLastActivity(activities);
  if (last == null) return '➕ ${context.tr('tap_to_start_only')}';

  final timeText = formatSmartDate(last.activityDateTime, context);
  if (timeText == null) return '➕ ${context.tr('tap_to_start_only')}';

  final temperature = last.data['temperature']?.toString();
  final unit = last.data['temperatureUnit']?.toString();

  if (temperature == null || temperature.isEmpty) {
    return '➕ ${context.tr('tap_to_start_only')}';
  }

  return '$temperature${unit != null ? ' $unit' : ''}\n$timeText';
}

String? getLastVaccinationSummary(
  List<ActivityModel> activities,
  BuildContext context,
) {
  final last = getLastActivity(activities);
  if (last == null) return '➕ ${context.tr('tap_to_start_only')}';

  final timeText = formatSmartDate(last.activityDateTime, context);
  if (timeText == null) return '➕ ${context.tr('tap_to_start_only')}';

  final vaccinations =
      (last.data['medications'] as List<dynamic>?)
          ?.map((e) => e['name'] as String?)
          .where((name) => name != null && name.trim().isNotEmpty)
          .toList();

  if (vaccinations == null || vaccinations.isEmpty) {
    return '➕ ${context.tr('tap_to_start_only')}';
  }

  final vaccinationNames = vaccinations.join(', ');
  return '$vaccinationNames\n$timeText';
}

String? getLastDoctorVisitSummary(
  List<ActivityModel> activities,
  BuildContext context,
) {
  final last = getLastActivity(activities);
  if (last == null) return '➕ ${context.tr('tap_to_start_only')}';

  final timeText = formatSmartDate(last.activityDateTime, context);
  if (timeText == null) return '➕\n ${context.tr('tap_to_start_only')}';

  final reason = last.data['reason'] ?? '';
  final reaction = last.data['reaction'] ?? '';
  final diagnosis = last.data['diagnosis'] ?? '';
  final notes = last.data['notes'] ?? '';

  final parts = <String>[];
  if (reason.toString().isNotEmpty) {
    parts.add('${context.tr('reason_label')}: $reason');
  }
  if (reaction.toString().isNotEmpty) {
    parts.add('${context.tr('reaction_label')}: $reaction');
  }
  if (diagnosis.toString().isNotEmpty) {
    parts.add('${context.tr('diagnosis_label')}: $diagnosis');
  }
  if (notes.toString().isNotEmpty) {
    parts.add('${context.tr('notes_label')}: $notes');
  }

  final joined = parts.join(' · ');

  return joined.isEmpty ? '➕ ${context.tr('tap_to_start_only')}' : '$joined\n$timeText';
}

String? getLastMedicationSummary(
  List<ActivityModel> list,
  BuildContext context,
) {
  final last = getLastActivity(list);
  if (last == null) return '➕ ${context.tr('tap_to_start_only')}';

  final timeText = formatSmartDate(last.activityDateTime, context);
  if (timeText == null) return '➕\n ${context.tr('tap_to_start_only')}';

  final List<dynamic>? meds = last.data['medications'];
  if (meds == null || meds.isEmpty) {
    return context.tr('no_medication_details');
  }

  final medsSummary = meds
      .map((med) {
        final name = med['name'] ?? '';
        final amount = med['amount'] ?? '';
        final unit = med['unit'] ?? '';
        return '$name: $amount $unit';
      })
      .join(', ');

  return '$medsSummary\n$timeText';
}

String? getLastGrowthMetricSummary({
  required List<ActivityModel> activities,
  required String fieldKey,
  required String unitKey,
}) {
  final filtered =
      activities
          .where(
            (a) =>
                a.data.containsKey(fieldKey) &&
                a.data[fieldKey] != null &&
                a.data[fieldKey].toString().trim().isNotEmpty,
          )
          .toList();

  final last = getLastActivity(filtered);
  if (last == null) return null;

  final value = last.data[fieldKey]?.toString() ?? '';
  final unit = last.data[unitKey]?.toString() ?? '';

  return '$value $unit';
}

String? getActivitySummary(ActivityModel activity, BuildContext context) {
  switch (activity.activityType) {
    case 'feed':
    case 'breastFeed':
    case 'bottleFeed':
    case 'solids':
      return getLastFeedSummary([activity], context);

    case 'pumpLeftRight':
    case 'pumpTotal':
      return getLastPumpSummary([activity], context);

    case 'sleep':
      return getLastSleepSummary([activity], false, context);

    case 'diaper':
      return getLastDiaperSummary([activity], context);

    case 'medication':
      return getLastMedicationSummary([activity], context);

    case 'growth':
      final weightSummary = getLastGrowthMetricSummary(
        activities: [activity],
        fieldKey: 'weight',
        unitKey: 'weightUnit',
      );
      final heightSummary = getLastGrowthMetricSummary(
        activities: [activity],
        fieldKey: 'height',
        unitKey: 'heightUnit',
      );
      final headSizeSummary = getLastGrowthMetricSummary(
        activities: [activity],
        fieldKey: 'headSize',
        unitKey: 'headSizeUnit',
      );

      final parts = [
        if (weightSummary != null && weightSummary.isNotEmpty)
          '${context.tr('weight')}: $weightSummary',
        if (heightSummary != null && heightSummary.isNotEmpty)
          '${context.tr('height')}: $heightSummary',
        if (headSizeSummary != null && headSizeSummary.isNotEmpty)
          '${context.tr('head_size')}: $headSizeSummary',
      ];
      return parts.isEmpty ? null : parts.join('\n');

    case 'babyFirsts':
      return getLastBabyFirstsSummary([activity], context);

    case 'teething':
      return getLastTeethingSummary([activity], context);

    case 'vaccination':
      return getLastVaccinationSummary([activity], context);

    case 'doctorVisit':
      return getLastDoctorVisitSummary([activity], context);

    case 'fever':
      return getLastFeverSummary([activity], context);

    default:
      return context.tr('activity_recorded');
  }
}
