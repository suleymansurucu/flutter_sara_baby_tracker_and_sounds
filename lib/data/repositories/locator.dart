import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/repositories/activity_repository_impl.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/repositories/activity_reposityory.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/repositories/baby_repository.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/repositories/baby_repsitory_impl.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/repositories/caregiver_repository.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/repositories/caregiver_repository_impl.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/repositories/medication_repository.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/repositories/medication_repository_impl.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/repositories/recipe_repository.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/repositories/recipe_repository_impl.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/repositories/relaxing_sound_repository.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/repositories/relaxing_sound_repository_impl.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/repositories/timer_repository.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/repositories/timer_repository_impl.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/repositories/user_repository.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/repositories/user_repository_impl.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/repositories/vaccination_repository.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/repositories/vaccination_repository_impl.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/services/firebase/activity_service.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/services/firebase/activity_service_impl.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/services/firebase/auth_service.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/services/local_database/milestone_service.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/services/local_database/milestone_service_impl.dart';
import 'package:get_it/get_it.dart';

import '../services/local_database/local_database_service.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  final database = await LocalDatabaseService.database;

  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<UserRepository>(() => UserRepositoryImpl());
  getIt.registerLazySingleton<BabyRepository>(() => BabyRepositoryImpl());
  getIt.registerLazySingleton<CaregiverRepository>(
    () => CaregiverRepositoryImpl(),
  );
  getIt.registerLazySingleton<TimerRepository>(
    () => TimerRepositoryImpl(database: database),
  );
  getIt.registerLazySingleton<ActivityRepository>(
    () => ActivityRepositoryImpl(database: database),
  );
  getIt.registerLazySingleton<ActivityService>(() => ActivityServiceImpl());
  getIt.registerLazySingleton<MilestoneService>(() => MilestoneServiceImpl(database: database));
  getIt.registerLazySingleton<MedicationRepository>(()=>MedicationRepositoryImpl(database: database));
  getIt.registerLazySingleton<VaccinationRepository>(()=>VaccinationRepositoryImpl(database: database));
  getIt.registerLazySingleton<RelaxingSoundRepository>(()=>RelaxingSoundRepositoryImpl(database: database));

  getIt.registerLazySingleton<AudioPlayer>(() => AudioPlayer());
  getIt.registerLazySingleton<RecipeRepository>(() => RecipeRepositoryImpl());

}
