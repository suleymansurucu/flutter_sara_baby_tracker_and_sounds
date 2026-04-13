import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:open_baby_sara/data/models/invite_model.dart';
import 'package:open_baby_sara/data/models/user_model.dart';
import 'package:open_baby_sara/data/repositories/caregiver_repository.dart';

class CaregiverRepositoryImpl extends CaregiverRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<void> createCaregiver(InviteModel caregiver) async {
    await _firestore
        .collection('invites')
        .doc(caregiver.caregiverID)
        .set(caregiver.toMap());
  }

  @override
  Future<void> signUpCaregiverAndCheck(
    String firstName,
    String email,
    String password,
  ) async {
    try {
      var caregiver =
          await _firestore
              .collection('invites')
              .where('receiverEmail', isEqualTo: email)
              .where('status', isEqualTo: 'pending')
              .get();

      var caregiverActive =
          await _firestore
              .collection('invites')
              .where('receiverEmail', isEqualTo: email)
              .where('status', isEqualTo: 'active')
              .get();

      if (caregiver.docs.isEmpty && caregiverActive.docs.isEmpty) {
        throw Exception('There is no invitation found for this email.');
      } else if (caregiverActive.docs.isNotEmpty && caregiver.docs.isEmpty) {
        throw Exception(
          'This email is already linked to an active caregiver. Please sign in.',
        );
      } else if (caregiver.docs.isNotEmpty && caregiverActive.docs.isEmpty) {
        var caregiverAuth = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (caregiverAuth.user?.uid != null) {
          var caregiverMap = caregiver.docs.first.data();
          var userID = caregiverMap['senderID'];
          final userDoc =
              await _firestore.collection('users').doc(userID).get();
          List<dynamic> caregivers = userDoc.data()?['caregivers'] ?? [];
          String parentID = userDoc.data()!['parentID'];
          caregivers.removeWhere((cg) => cg['receiverEmail'] == email);
          caregivers.add(
            InviteModel(
              senderID: userID,
              receiverEmail: email,
              status: 'active',
              parentID: parentID,
              firstName: firstName,
              createdAt: DateTime.now(),
              caregiverID: caregiverAuth.user!.uid,
            ).toMap(),
          );
          await _firestore.collection('users').doc(userID).update({
            'caregivers': caregivers,
          });
          await _firestore
              .collection('invites')
              .doc(caregiverMap['caregiverID'])
              .delete();
          UserModel userModel = UserModel(
            userID: caregiverAuth.user!.uid,
            email: email,
            firstName: firstName,
            parentID: parentID,
          );
          await _firestore
              .collection('users')
              .doc(caregiverAuth.user!.uid)
              .set(userModel.toMap());
        }
      }
    } on FirebaseAuthException catch (e) {
      throw Exception('Authentication failed. ${e.message}');
    } catch (e) {
      throw Exception('Authentication failed. ${e.toString()}');
    }
  }

  @override
  Future<void> signUpCaregiverWithGoogle(
    String firstName,
    String email,
  ) async {
    try {
      var caregiver =
          await _firestore
              .collection('invites')
              .where('receiverEmail', isEqualTo: email)
              .where('status', isEqualTo: 'pending')
              .get();

      var caregiverActive =
          await _firestore
              .collection('invites')
              .where('receiverEmail', isEqualTo: email)
              .where('status', isEqualTo: 'active')
              .get();

      if (caregiver.docs.isEmpty && caregiverActive.docs.isEmpty) {
        throw Exception('There is no invitation found for this email.');
      } else if (caregiverActive.docs.isNotEmpty && caregiver.docs.isEmpty) {
        throw Exception(
          'This email is already linked to an active caregiver. Please sign in.',
        );
      } else if (caregiver.docs.isNotEmpty && caregiverActive.docs.isEmpty) {
        // Google Sign-In zaten yapılmış, sadece Firestore işlemlerini yap
        final currentUser = _auth.currentUser;
        if (currentUser == null || currentUser.uid.isEmpty) {
          throw Exception('User not authenticated');
        }

        var caregiverMap = caregiver.docs.first.data();
        var userID = caregiverMap['senderID'];
        final userDoc =
            await _firestore.collection('users').doc(userID).get();
        List<dynamic> caregivers = userDoc.data()?['caregivers'] ?? [];
        String parentID = userDoc.data()!['parentID'];
        caregivers.removeWhere((cg) => cg['receiverEmail'] == email);
        caregivers.add(
          InviteModel(
            senderID: userID,
            receiverEmail: email,
            status: 'active',
            parentID: parentID,
            firstName: firstName,
            createdAt: DateTime.now(),
            caregiverID: currentUser.uid,
          ).toMap(),
        );
        await _firestore.collection('users').doc(userID).update({
          'caregivers': caregivers,
        });
        await _firestore
            .collection('invites')
            .doc(caregiverMap['caregiverID'])
            .delete();
        UserModel userModel = UserModel(
          userID: currentUser.uid,
          email: email,
          firstName: firstName,
          parentID: parentID,
        );
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .set(userModel.toMap());
      }
    } catch (e) {
      throw Exception('Google Sign-In failed. ${e.toString()}');
    }
  }

  @override
  Future<List<InviteModel>?> getCaregiverList() async {
    var userID = _auth.currentUser!.uid;

    var userMap =
        (await _firestore.collection('users').doc(userID).get()).data();

    if (userMap != null && userMap.containsKey('caregivers')) {
      final caregivers = userMap['caregivers'] as List<dynamic>;
      return caregivers
          .map((data) => InviteModel.fromMap(data as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<void> deleteCaregiver(String caregiverID) async {
    var userID = _auth.currentUser?.uid;

    List caregiversList =
        (await _firestore.collection('users').doc(userID).get())
            .data()?['caregivers'] ??
        [];
    String? isCaregiverActive;
    for (var cg in caregiversList) {
      if (cg['caregiverID'] == caregiverID) {
        isCaregiverActive = cg['status'];
      }
    }
    try {
      if (isCaregiverActive == 'active') {
        caregiversList.removeWhere((cg) => cg['caregiverID'] == caregiverID);
        await _firestore.collection('users').doc(userID).update({
          'caregivers': caregiversList,
        });

        await _firestore.collection('users').doc(caregiverID).delete();
      } else {
        caregiversList.removeWhere((cg) => cg['caregiverID'] == caregiverID);
        await _firestore.collection('users').doc(userID).update({
          'caregivers': caregiversList,
        });
        await _firestore.collection('invites').doc(caregiverID).delete();
      }
    } on FirebaseAuthException catch (e) {
      throw e.toString();
    } catch (e) {
      throw e.toString();
    }
  }
}
