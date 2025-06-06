import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/repositories/locator.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/repositories/baby_repository.dart';
import 'package:gender_picker/source/enums.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_sara_baby_tracker_and_sound/data/models/baby_model.dart';
import 'package:meta/meta.dart';

part 'baby_event.dart';

part 'baby_state.dart';

class BabyBloc extends Bloc<BabyEvent, BabyState> {
  final BabyRepository _babyRepository = getIt<BabyRepository>();

  BabyBloc() : super(BabyInitial()) {

    on<RegisterBaby>((event, emit) async {
      emit(BabyLoading());
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      var userMap =
          (await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get())
              .data();
      final String parentID = userMap!['parentID'];
      final babyId = const Uuid().v4(); // v4 = random ID
      final baby = BabyModel(
        firstName: event.firstName,
        gender: event.gender,
        userID: user.uid,
        parentID: parentID,
        babyID: babyId,
        dateTime: event.dateTime,
      );

      await _babyRepository.createBaby(baby);
      emit(BabySuccess());
    });

    // Fetch babies from user account...
    on<LoadBabies>((event, emit) async {
      emit(BabyLoading());
      final babies = await _babyRepository.getBabies();
      emit(
        BabyLoaded(
          babies: babies,
          selectedBaby: babies.isNotEmpty ? babies.first : null,
        ),
      );
    });
    on<GetBabyInfo>((event, emit) async {
      emit(BabyLoading());
      try{
        final babyModel = await _babyRepository.getSelectedBaby(event.babyID);
        if (babyModel != null) {
          emit(GotBabyInfo(babyModel: babyModel));
        }
      } catch(e){
        debugPrint(e.toString());
        emit(BabyFailure('Get Baby selected Error!: ${e.toString()}'));
      }
    });
    on<onGenderSelectedEvent>((event, emit) {
      emit(onGenderSelectedState(newGender: event.gender));
    });
    on<UploadBabyImage>((event, emit) async {
      emit(BabyLoading());
      final newImageUrl = await _babyRepository.uploadBabyImage(event.babyID);
      if (newImageUrl != null) {
        final updatedBaby = await _babyRepository.getSelectedBaby(event.babyID);
        if (updatedBaby != null) {
          emit(GotBabyInfo(babyModel: updatedBaby));
        } else {
          emit(BabyFailure('Baby not found'));
        }
      } else {
        emit(BabyFailure('Image upload failed'));
      }
    });
    on<UpdatedBaby>((event, emit) async {
      emit(BabyLoading());
      try {
        await _babyRepository.updateBaby(event.babyID, event.updatedFields);
        emit(BabyUpdated());
      } catch (e) {
        emit(BabyFailure(e.toString()));
      }
    });
    on<DeletedBaby>((event, emit) async {
      emit(BabyLoading());
      try {
        await _babyRepository.deleteBaby(event.babyID);
        emit(BabyDeleted());
      } catch (e) {
        emit(BabyFailure(e.toString()));
      }
    });
    on<AddBaby>((event, emit) async {
      emit(BabyLoading());
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      var userMap =
          (await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .get())
              .data();
      final String parentID = userMap!['parentID'].toString();
      final babyId = const Uuid().v4(); // v4 = random ID
      if (event.file != null) {
        final getImageUrl = await _babyRepository.uploadBabyImageToFile(
          babyId,
          event.file!,
        );
        if (getImageUrl != null) {
          final imgUrl = getImageUrl;
          final baby = BabyModel(
            firstName: event.firstName,
            gender: event.gender,
            userID: user.uid,
            babyID: babyId,
            parentID: parentID,
            dateTime: event.dateTime,
            nighttimeHours: event.nighttimeHours,
            imageUrl: imgUrl,
          );
          await _babyRepository.createBaby(baby);
          emit(AddedBaby());
        }
      } else {
        final baby = BabyModel(
          firstName: event.firstName,
          gender: event.gender,
          userID: user.uid,
          babyID: babyId,
          parentID: parentID,
          dateTime: event.dateTime,
          nighttimeHours: event.nighttimeHours,
          imageUrl: '',
        );
        await _babyRepository.createBaby(baby);
        emit(AddedBaby());
      }
    });
    on<SelectBaby>((event, emit){
      if (state is BabyLoaded) {
        final currentState=state as BabyLoaded;
        emit(BabyLoaded(babies: currentState.babies,selectedBaby: event.selectBabyModel));
      }
    });
    on<LoadBabyImagePath>((event, emit) async {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = '${directory.path}/baby_images/${event.babyID}.jpg';
        final file = File(imagePath);

        if (await file.exists()) {
          emit(BabyImagePathLoaded(babyID: event.babyID, imagePath: imagePath));
        } else {
          emit(BabyFailure('Image not found for baby.'));
        }
      } catch (e) {
        emit(BabyFailure('Error loading baby image: ${e.toString()}'));
      }
    });
    on<SaveBabyImage>((event, emit) async {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final savePath = '${directory.path}/baby_images';
        final folder = Directory(savePath);

        if (!await folder.exists()) {
          await folder.create(recursive: true);
        }

        final filePath = '$savePath/${event.babyID}.jpg';
        await event.imageFile.copy(filePath);

        emit(BabyImagePathLoaded(babyID: event.babyID, imagePath: filePath));
      } catch (e) {
        emit(BabyFailure('Failed to save image: ${e.toString()}'));
      }
    });
    on<UpdateBabyImageLocal>((event, emit) async {
      emit(BabyLoading());
      try {
        await _babyRepository.updateBaby(event.babyID, {'localImagePath': event.imagePath});
        emit(BabyUpdated());
        add(LoadBabyImagePath(babyID: event.babyID));
      } catch (e) {
        emit(BabyFailure('Local image update failed: $e'));
      }
    });
  }
}
