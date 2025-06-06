import 'dart:io';

import 'package:flutter_sara_baby_tracker_and_sound/data/models/baby_model.dart';

abstract class BabyRepository{
  Future<void> createBaby(BabyModel baby);
  Future<BabyModel?> getSelectedBaby(String? babyID);
  Future<List<BabyModel>> getBabies();
  Future<String?> uploadBabyImage(String babyID);
  Future<void> updateBaby(String babyID, Map<String, dynamic> updatedFields);
  Future<void> deleteBaby(String babyID);
  Future<String?> uploadBabyImageToFile(String babyID, File file);



}