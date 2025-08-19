// lib/modules/voice_input/voice_input_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../routes/app_routes.dart';
import 'controller/voice_input_controller.dart';
import 'widgets/section_progress_bar.dart';
import 'widgets/section_list_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/cv_model.dart';
import 'edit_mode_manager.dart';  // NEW import

class VoiceInputScreen extends StatefulWidget {
  final String? startSectionKey; // ✅ Existing optional param

  VoiceInputScreen({Key? key, this.startSectionKey}) : super(key: key);

  @override
  State<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends State<VoiceInputScreen> {
  late VoiceInputController _controller;
  late EditModeManager _editModeManager; // NEW manager instance
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final ScrollController _scrollController = ScrollController();
  final Map<String, double> _sectionPositions = {};


  Map<String, dynamic> _cvData = {};
  String? _cvId;
  String? _userId;

  final Map<String, GlobalKey> _sectionKeys = {
    'header': GlobalKey(),
    'contact': GlobalKey(),
    'skills': GlobalKey(),
    'experience': GlobalKey(),
    'projects': GlobalKey(),
    'education': GlobalKey(),
    'certification': GlobalKey(),
    'languages': GlobalKey(),
  };

  bool _useKeyboardInput = false; // toggle between keyboard & voice
  final TextEditingController _keyboardController = TextEditingController();

  void _autoScrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildHeaderSection() => Container();

  Widget _buildContactSection() => Container();

  Widget _buildSkillsSection() => Container();

  Widget _buildExperienceSection() => Container();

  Widget _buildProjectsSection() => Container();

  Widget _buildEducationSection() => Container();

  Widget _buildCertificationsSection() => Container();

  Widget _buildLanguagesSection() => Container();


  void _updateControllersForCurrentSection() {
    // Update keyboard controller
    _keyboardController.text = _controller.transcription;
    _keyboardController.selection = TextSelection.fromPosition(
      TextPosition(offset: _keyboardController.text.length),
    );

    // Update manual controller
    _editModeManager.manualController.text = _controller.transcription;
    _editModeManager.manualController.selection = TextSelection.fromPosition(
      TextPosition(offset: _editModeManager.manualController.text.length),
    );
  }

  @override
  @override
  void initState() {
    super.initState();

    // 1️⃣ Initialize the controller first
    _controller = VoiceInputController();

    // 2️⃣ Initialize EditModeManager with the controller
    _editModeManager = EditModeManager(
      controller: _controller,
      context: context, // safe here because it's just storing context
    );

    // 3️⃣ Handle arguments passed via Navigator
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final cvData = args?['cvData'] ?? {};
      final cvId = args?['cvId'];
      final userId = args?['userId'];
      final focusedEdit = args?['focusedEdit'] ?? false;
      final editSection = args?['editSection'];

// ✅ Always initialize userData with empty lists for every section
      _controller.userData = {
        for (final section in _controller.sections)
          section['key']: List<String>.from(
            (cvData[section['key']] as List<dynamic>? ?? []).map((e) => e.toString()),
          ),
      };





      // Scroll to a section if requested
      if (focusedEdit && editSection != null) {
        _scrollToSection(editSection);
      }

      // Update text controllers safely
      _editModeManager.manualController.text = _controller.transcription;
      _editModeManager.manualController.selection = TextSelection.fromPosition(
        TextPosition(offset: _editModeManager.manualController.text.length),
      );
    });
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute
        .of(context)
        ?.settings
        .arguments;
    if (args is Map<String, dynamic>) {
      final Map<String, dynamic> cvData = args['cvData'] ?? {};
      final bool focusedEdit = args['focusedEdit'] ?? false;
      final String? editSection = args['editSection'];

      // 1. Update controller userData if different
      if (_controller.userData != cvData) {
        setState(() {
          _controller.userData = Map<String, dynamic>.from(cvData);
        });
      }

      // 2. Sync manualController text
      if (_editModeManager.manualController.text != _controller.transcription) {
        _editModeManager.manualController.text = _controller.transcription;
        _editModeManager.manualController.selection =
            TextSelection.fromPosition(
              TextPosition(
                  offset: _editModeManager.manualController.text.length),
            );
      }

      // 3. Sync keyboardController text
      if (_keyboardController.text != _controller.transcription) {
        _keyboardController.text = _controller.transcription;
        _keyboardController.selection = TextSelection.fromPosition(
          TextPosition(offset: _keyboardController.text.length),
        );
      }
      if (focusedEdit && editSection != null &&
          _sectionPositions.containsKey(editSection)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final offset = _sectionPositions[editSection]!;
          _scrollController.animateTo(
            offset.clamp(0.0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
    }
  }


  void _scrollToSection(String section) {
    final key = _sectionKeys[section];
    if (key == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context == null) return;

      final box = context.findRenderObject() as RenderBox;
      final pos = box
          .localToGlobal(Offset.zero)
          .dy;

      _scrollController.animateTo(
        _scrollController.offset + pos - 100, // optional padding
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _keyboardController.dispose();
    _scrollController.dispose();
    _controller.disposeController();
    _editModeManager.dispose();
    super.dispose();
  }


  Future<void> _logEvent(String name, {Map<String, dynamic>? params}) async {
    try {
      await _analytics.logEvent(name: name, parameters: params);
    } catch (_) {}
  }

  Future<void> _saveUpdatesAndExit() async {
    await _editModeManager.saveUpdatesAndExit();
  }


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<VoiceInputController>(
        builder: (context, controller, _) {
          final section = controller.sections[controller.currentIndex];
          final String key = section['key'];
          final bool multiple = section['multiple'];
          final bool required = section['required'];
          final String hint = section['hint'];

          final hasCompleted = multiple
              ? ((controller.userData[key] as List?)?.isNotEmpty ?? false)
              : (controller.userData[key]?.toString().trim().isNotEmpty ?? false);


          return Scaffold(
            appBar: AppBar(
              title: Text(
                _editModeManager.isEditMode
                    ? 'Edit Section: ${section['title']}'
                    : 'Voice Input',
              ),

              backgroundColor: const Color(0xFFE8F3F8),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: controller.isLoading
                    ? null
                    : () async {
                  if (_editModeManager.isEditMode) {
                    Navigator.pop(context); // Just pop, no saving here
                  } else {
                    await controller.resetSpeech(clearTranscription: false);
                    if (!mounted) return;
                    Navigator.pop(
                      context,
                      CVModel(
                        cvId: _controller.cvId,
                        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                        cvData: Map<String, dynamic>.from(_controller.userData),
                        isCompleted: false,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    );
                  }
                },
              ),
              actions: [
                if (_editModeManager.isEditMode)
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 4,
                      ),
                      onPressed: controller.isLoading
                          ? null
                          : () async {
                        await _saveUpdatesAndExit();
                      },
                      child: const Text(
                        "Save Updates",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            body: Builder(
              builder: (context) {
                // Call _autoScrollToBottom AFTER the frame renders
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _autoScrollToBottom();
                });

                return controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery
                          .of(context)
                          .viewInsets
                          .bottom + 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ================= WRAPPED SECTIONS WITH KEYS =================
                        Container(key: _sectionKeys['header'],
                            child: _buildHeaderSection()),
                        Container(key: _sectionKeys['contact'],
                            child: _buildContactSection()),
                        Container(key: _sectionKeys['skills'],
                            child: _buildSkillsSection()),
                        Container(key: _sectionKeys['experience'],
                            child: _buildExperienceSection()),
                        Container(key: _sectionKeys['projects'],
                            child: _buildProjectsSection()),
                        Container(key: _sectionKeys['education'],
                            child: _buildEducationSection()),
                        Container(key: _sectionKeys['certification'],
                            child: _buildCertificationsSection()),
                        Container(key: _sectionKeys['languages'],
                            child: _buildLanguagesSection()),
                        // ============================================================

                        SectionProgressBar(
                          currentIndex: controller.currentIndex,
                          totalSections: controller.sections.length,
                          title: section['title'],
                          required: required,
                          hasCompleted: hasCompleted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          hint,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        if (multiple)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.add_circle,
                                    size: 14, color: Colors.blue),
                                SizedBox(width: 4),
                                Text(
                                  "You can add multiple entries",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.blue),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),


                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Voice'),
                              selected: !_useKeyboardInput,
                              onSelected: (sel) {
                                if (sel) {
                                  setState(() => _useKeyboardInput = false);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Keyboard'),
                              selected: _useKeyboardInput,
                              onSelected: (sel) {
                                if (sel) {
                                  // Stop listening if active
                                  if (_controller.isListening) {
                                    _controller.stopListening();
                                  }
                                  setState(() {
                                    _useKeyboardInput = true;
                                    _keyboardController.text =
                                        _controller.transcription;
                                    _keyboardController.selection =
                                        TextSelection.fromPosition(
                                          TextPosition(
                                              offset: _keyboardController.text
                                                  .length),
                                        );
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            if (_useKeyboardInput)
                              const Text(
                                'Typing mode enabled',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),


                        if (_editModeManager.isEditMode)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text("Manual Edit"),
                              Switch(
                                value: controller.isManualInput,
                                onChanged: (val) {
                                  setState(() {
                                    controller.isManualInput = val;
                                    if (!controller.isManualInput) {
                                      controller.transcription = '';
                                    }
                                  });
                                },
                              ),
                            ],
                          ),

                        const SizedBox(height: 10),

                        _useKeyboardInput
                            ? TextField(
                          controller: _keyboardController,
                          onChanged: (val) {
                            controller.transcription =
                                val; // sync with controller
                          },
                          maxLines: null,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            hintText: 'Type here… (feeds transcription)',
                            suffixIcon: _keyboardController.text.isNotEmpty
                                ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _keyboardController.clear();
                                controller.transcription = '';
                                setState(() {});
                              },
                            )
                                : null,
                          ),
                        )
                            : controller.isManualInput
                            ? TextField(
                          autofocus: true,
                          maxLines: null,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            hintText: 'Edit text manually...',
                            suffixIcon:
                            _editModeManager.manualController.text.isNotEmpty
                                ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _editModeManager.manualController.clear();
                                controller.transcription = '';
                                setState(() {});
                              },
                            )
                                : null,
                          ),
                          controller: _editModeManager.manualController,
                          onChanged: (val) {
                            controller.transcription = val;
                          },
                        )
                            : Container(
                          width: double.infinity,
                          height: 120,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blueGrey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            child: Text(
                              controller.transcription.isNotEmpty
                                  ? controller.transcription
                                  : multiple
                                  ? (controller.userData[key] as List<String>).isNotEmpty
                                  ? (controller.userData[key] as List<String>).join(', ')
                                  : 'Your voice input will appear here...'
                                  : (controller.userData[key]?.toString().trim().isNotEmpty ?? false)
                                  ? controller.userData[key].toString()
                                  : 'Your voice input will appear here...',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),

                        ),


                        if (multiple &&
                            controller.transcription
                                .trim()
                                .isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: controller.isLoading
                                    ? null
                                    : () {
                                  _editModeManager.editEntryIndex = null;
                                  controller.addToMultipleList(key);
                                },
                                icon: const Icon(Icons.add,
                                    color: Colors.blue, size: 20),
                                label: const Text(
                                  'Add Entry',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  foregroundColor: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),

                        if (!controller.isManualInput &&
                            !controller.isSpeechAvailable)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Mic not available or failed (give Mic Permission). Please type your response:",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.red),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                onChanged: (value) =>
                                controller.transcription = value,
                                controller:
                                TextEditingController(
                                    text: controller.transcription),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Enter response manually...',
                                ),
                                maxLines: null,
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),

                        if (!controller.isManualInput &&
                            controller.isSpeechAvailable)
                          Center(
                            child: IconButton(
                              iconSize: 60,
                              icon: Icon(
                                controller.isListening ? Icons.mic_off : Icons
                                    .mic,
                                size: 50,
                                color:
                                controller.isListening ? Colors.red : Colors
                                    .blue,
                              ),
                              onPressed: controller.isLoading
                                  ? null
                                  : () async {
                                final hasNet = await controller.hasInternet();
                                if (!hasNet) {
                                  showDialog(
                                    context: context,
                                    builder: (_) =>
                                        AlertDialog(
                                          title: const Text(
                                              "🎙️ Internet Required"),
                                          content: const Text(
                                              "Voice input needs internet connection. Please reconnect."),
                                          actions: [
                                            TextButton(
                                              child: const Text("OK"),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                            ),
                                          ],
                                        ),
                                  );
                                  return;
                                }

                                if (!controller.isListening) {
                                  await _logEvent("start_listening",
                                      params: {"section": key});
                                } else {
                                  await _logEvent("stop_listening",
                                      params: {"section": key});
                                }

                                await controller.startListening(context);
                              },
                            ),
                          ),

                        const SizedBox(height: 20),

                        if (!_editModeManager.isEditMode)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Back'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                ),
                                onPressed: controller.currentIndex == 0 ||
                                    controller.isLoading
                                    ? null
                                    : controller.backSection,
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh,
                                    color: Colors.blue, size: 32),
                                onPressed: controller.isLoading
                                    ? null
                                    : () async {
                                  await controller.resetSpeech(
                                      clearTranscription: true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Retrying current text")),
                                  );
                                },
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                ),
                                icon: Icon(
                                  controller.currentIndex ==
                                      controller.sections.length - 1
                                      ? Icons.check
                                      : Icons.arrow_forward,
                                ),
                                label: Text(
                                  controller.currentIndex ==
                                      controller.sections.length - 1
                                      ? 'Finish'
                                      : 'Next',
                                ),
                                onPressed: controller.isLoading
                                    ? null
                                    : () async {
                                  final hasInternet =
                                  await controller.hasInternet();
                                  if (!hasInternet) {
                                    showDialog(
                                      context: context,
                                      builder: (_) =>
                                          AlertDialog(
                                            title: const Text("⚠️ No Internet"),
                                            content: const Text(
                                                "Please connect to the internet to proceed to the next section."),
                                            actions: [
                                              TextButton(
                                                child: const Text("OK"),
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                              ),
                                            ],
                                          ),
                                    );
                                    return;
                                  }

                                  final result = await controller.nextSection(context);
                                  _updateControllersForCurrentSection();
                                  if (result == "completed") {
                                    final userId =
                                        FirebaseAuth.instance.currentUser
                                            ?.uid ??
                                            '';
                                    final cvId =
                                        'cv_${DateTime
                                        .now()
                                        .millisecondsSinceEpoch}';

                                    final cvModel = CVModel(
                                      cvId: cvId,
                                      userId: userId,
                                      cvData: controller.userData,
                                      isCompleted: false,
                                      createdAt: DateTime.now(),
                                      updatedAt: DateTime.now(),
                                    );

                                    if (_editModeManager.isEditMode) {
                                      Navigator.pop(context,
                                          cvModel); // Pop and send back updated CV if editing
                                    } else {
                                      Navigator.pushNamed(
                                          context, AppRoutes.summary,
                                          arguments: cvModel);
                                    }
                                  }
                                },
                              ),
                            ],
                          ),

                        const SizedBox(height: 20),

                        if (multiple &&
                            ((controller.userData[key] as List?)?.isNotEmpty ?? false))
                          SectionListItem(
                            entries: (controller.userData[key] is List)
                                ? List<String>.from(controller.userData[key] as List)
                                : [], // fallback if null or not a list
                            onEdit: (index) {
                              _editModeManager.editEntryIndex = index;
                              controller.editEntry(context, key, index);
                            },
                            onDelete: (index) => controller.deleteEntry(key, index),
                          ),


                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}