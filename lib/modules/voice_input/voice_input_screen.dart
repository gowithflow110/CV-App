// lib/modules/voice_input/voice_input_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../routes/app_routes.dart';
import 'controller/voice_input_controller.dart';
import 'widgets/section_progress_bar.dart';

class VoiceInputScreen extends StatefulWidget {
  const VoiceInputScreen({Key? key}) : super(key: key);

  @override
  State<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends State<VoiceInputScreen> {
  late VoiceInputController _controller;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final ScrollController _scrollController = ScrollController();
  late TextEditingController _textController;

  void _autoScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = VoiceInputController();
    _textController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.initializeSpeech();
      await _controller.loadCVData(
        args: ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?,
      );
      _textController.text = _controller.transcription;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _controller.disposeController();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _logEvent(String name, {Map<String, dynamic>? params}) async {
    try {
      await _analytics.logEvent(name: name, parameters: params);
    } catch (_) {}
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
              ? (controller.userData[key] as List).isNotEmpty
              : (controller.userData[key]?.toString().trim().isNotEmpty ?? false);

          _autoScrollToBottom();

          return Scaffold(
            appBar: AppBar(
              title: const Text('Voice Input'),
              backgroundColor: const Color(0xFFE8F3F8),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: controller.isLoading
                    ? null
                    : () async {
                  await controller.resetSpeech(clearTranscription: false);
                  if (!mounted) return;
                  Navigator.pop(context);
                },
              ),
            ),
            body: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add_circle, size: 14, color: Colors.blue),
                            SizedBox(width: 4),
                            Text(
                              "You can add multiple entries",
                              style: TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Always show TextField for keyboard input
                    TextField(
                      controller: _textController,
                      onChanged: (value) => controller.transcription = value,
                      maxLines: null,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter your response here...',
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (multiple && controller.transcription.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: controller.isLoading
                                ? null
                                : () {
                              controller.addToMultipleList(key);
                              _textController.clear();
                            },
                            icon: const Icon(Icons.add, color: Colors.blue, size: 20),
                            label: const Text(
                              'Add Entry',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              foregroundColor: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Mic button (optional, keeps existing functionality)
                    if (controller.isSpeechAvailable)
                      Center(
                        child: IconButton(
                          iconSize: 60,
                          icon: Icon(
                            controller.isListening ? Icons.mic_off : Icons.mic,
                            size: 50,
                            color: controller.isListening ? Colors.red : Colors.blue,
                          ),
                          onPressed: controller.isLoading
                              ? null
                              : () async {
                            final hasNet = await controller.hasInternet();
                            if (!hasNet) {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("🎙️ Internet Required"),
                                  content: const Text(
                                      "Voice input needs internet connection. Please reconnect."),
                                  actions: [
                                    TextButton(
                                      child: const Text("OK"),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            if (!controller.isListening) {
                              await _logEvent("start_listening", params: {"section": key});
                            } else {
                              await _logEvent("stop_listening", params: {"section": key});
                            }

                            await controller.startListening(context);
                          },
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Navigation buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          onPressed: controller.currentIndex == 0 || controller.isLoading
                              ? null
                              : controller.backSection,
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.blue, size: 32),
                          onPressed: controller.isLoading
                              ? null
                              : () async {
                            await controller.resetSpeech(clearTranscription: true);
                            _textController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Retrying current text")),
                            );
                          },
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          icon: Icon(
                            controller.currentIndex == controller.sections.length - 1
                                ? Icons.check
                                : Icons.arrow_forward,
                          ),
                          label: Text(
                            controller.currentIndex == controller.sections.length - 1 ? 'Finish' : 'Next',
                          ),
                          onPressed: controller.isLoading
                              ? null
                              : () async {
                            final result = await controller.nextSection(context);
                            if (result == "completed") {
                              if (!mounted) return;
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.preview,
                                          arguments: {"cvData": controller.userData},
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        "Generate CV",
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              _textController.clear();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
