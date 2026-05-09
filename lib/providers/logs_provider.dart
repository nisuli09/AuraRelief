import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogsProvider extends ChangeNotifier {

  List<QueryDocumentSnapshot> logs = [];

  LogsProvider() {
    _listenToLogs();
  }

  void _listenToLogs() {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    FirebaseFirestore.instance
        .collection('logs')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {

      logs = snapshot.docs;

      notifyListeners();
    });
  }
}