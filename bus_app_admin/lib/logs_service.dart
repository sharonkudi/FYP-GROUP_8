import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> addLog(String action) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final snapshot = await FirebaseFirestore.instance
      .collection('admins')
      .doc(user.uid)
      .get();

  if (!snapshot.exists) return;

  final data = snapshot.data()!;
  final adminId = data['admin_id'];
  final adminName = data['name'];

  await FirebaseFirestore.instance.collection('logs').add({
    'admin_id': adminId,
    'name': adminName,
    'action': action,
    'timestamp': FieldValue.serverTimestamp(),
    'localTime': DateTime.now(),
  });
}
