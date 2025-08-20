// lib/modules/voice_input/edit_mode_manager.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/cv_model.dart';
import '../../../services/firestore_service.dart';
import 'controller/voice_input_controller.dart';

class EditModeManager {
  final VoiceInputController controller;
  final BuildContext context;
  final FirestoreService _firestoreService = FirestoreService();

  bool isEditMode = false;
  int? editEntryIndex; // null means new entry; int means editing existing entry
  String? editField;
  dynamic previousData;

  TextEditingController manualController = TextEditingController();

  EditModeManager({required this.controller, required this.context});

  void dispose() {
    manualController.dispose();
  }

  /// Initialize edit mode variables and preload data if applicable
  Future<void> initializeEditMode(Map<String, dynamic>? args) async {
    if (args == null || args['forceEdit'] != true) return;

    isEditMode = true;
    editField = args['editField'] as String?;
    previousData = args['previousData'];
    controller.isManualInput = false;

    if (editField == null) return;

    const headerFields = ['name', 'summary'];

    if (headerFields.contains(editField)) {
      // Handle header separately
      controller.userData['header'] ??= {};
      final headerMap = controller.userData['header'] as Map<String, dynamic>;

      if (previousData != null) {
        headerMap[editField!] = previousData.toString();
      }

      controller.transcription = headerMap[editField!] ?? '';
      editEntryIndex = null;
    } else {
      // Normal sections
      final idx = controller.sections.indexWhere((s) => s['key'] == editField);
      if (idx == -1) {
        debugPrint("Warning: editField '$editField' not found in sections.");
        return;
      }

      controller.currentIndex = idx;
      final section = controller.sections[idx];
      final isMultiple = section['multiple'] as bool? ?? false;

      if (isMultiple) {
        if (previousData is List<String>) {
          controller.userData[editField!] = List<String>.from(previousData);
        } else if (previousData is String && previousData.isNotEmpty) {
          controller.userData[editField!] = [previousData];
        } else {
          controller.userData[editField!] = <String>[];
        }

        if (args.containsKey('editIndex') && args['editIndex'] != null) {
          final idxEntry = args['editIndex'] as int;
          final list = (controller.userData[editField!] as List?)?.cast<String>() ?? [];

          if (idxEntry >= 0 && idxEntry < list.length) {
            editEntryIndex = idxEntry;
            controller.transcription = list[idxEntry];
          } else {
            editEntryIndex = null;
            controller.transcription = '';
          }
        } else {
          editEntryIndex = null;
          controller.transcription = '';
        }
      } else {
        final safePrevious = (previousData?.toString() ?? '').trim();
        controller.transcription = safePrevious;
        controller.userData[editField!] = safePrevious;
        editEntryIndex = null;
      }
    }
  }




  /// Save updates for the current edit and exit (pop)
  Future<void> saveUpdatesAndExit() async {
    if (!isEditMode || editField == null) return;

    final trimmedValue = manualController.text.trim();
    controller.transcription = trimmedValue;

    bool hasValidData = false;

    // Define header fields
    const headerFields = ['name', 'summary'];

    if (headerFields.contains(editField)) {
      // Handle header fields
      controller.userData['header'] ??= <String, dynamic>{};
      final headerMap = controller.userData['header'] as Map<String, dynamic>;

      if (trimmedValue.isNotEmpty) {
        headerMap[editField!] = trimmedValue;
        hasValidData = true;
      } else {
        headerMap.remove(editField);
        hasValidData = false;
      }
    } else {
      // Handle normal sections
      final sectionIndex = controller.sections.indexWhere((s) => s['key'] == editField);
      if (sectionIndex == -1) {
        debugPrint("Warning: editField '$editField' not found anywhere.");
        return;
      }

      final section = controller.sections[sectionIndex];
      final key = section['key'];
      final isMultiple = section['multiple'] as bool? ?? false;
      final required = section['required'] as bool? ?? false;

      if (isMultiple) {
        final entries = List<String>.from(controller.userData[key] ?? []);
        if (trimmedValue.isNotEmpty) {
          final isEditing = editEntryIndex != null &&
              editEntryIndex! >= 0 &&
              editEntryIndex! < entries.length;

          if (isEditing) {
            entries[editEntryIndex!] = trimmedValue;
          } else {
            entries.add(trimmedValue);
          }
        }
        hasValidData = entries.isNotEmpty;
        if (hasValidData) {
          controller.userData[key] = entries;
        } else {
          controller.userData.remove(key);
        }
      } else {
        hasValidData = trimmedValue.isNotEmpty;
        if (hasValidData) {
          controller.userData[key] = trimmedValue;
        } else {
          controller.userData.remove(key);
        }
      }

      if (required && !hasValidData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text("This section is required. Please enter at least one value."),
          ),
        );
        return;
      }
    }

    // Save to database
    try {
      await controller.saveCurrentData();
    } catch (e) {
      debugPrint("Error saving updates: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save updates: $e")),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final cvId = controller.cvId;

    final cvModel = CVModel(
      cvId: cvId,
      userId: userId,
      cvData: Map<String, dynamic>.from(controller.userData),
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context, cvModel);
  }



}