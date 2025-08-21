import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

class DownloadJsonScreen extends StatefulWidget {
  @override
  _DownloadJsonScreenState createState() => _DownloadJsonScreenState();
}

class _DownloadJsonScreenState extends State<DownloadJsonScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> downloadUserDocument(String userId) async {
    try {
      DocumentSnapshot doc = await firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document not found!')),
        );
        return;
      }

      // Cast doc.data() to Map<String, dynamic>
      final data = doc.data() as Map<String, dynamic>;

      // Convert Timestamp to ISO string
      String jsonData = jsonEncode(
        data.map((key, value) {
          if (value is Timestamp) {
            return MapEntry(key, value.toDate().toIso8601String());
          } else {
            return MapEntry(key, value);
          }
        }),
      );

      // Save JSON to file
      Directory dir = await getApplicationDocumentsDirectory();
      String filePath = '${dir.path}/user_$userId.json';

      File file = File(filePath);
      await file.writeAsString(jsonData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document saved as $filePath')),
      );

      print('JSON saved at: $filePath');
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving document')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Download Firestore JSON')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            downloadUserDocument('R7jTBrc8aOOSdZLOMHLBm9GkuIN2'); // Replace with actual user ID
          },
          child: Text('Download JSON'),
        ),
      ),
    );
  }
}

