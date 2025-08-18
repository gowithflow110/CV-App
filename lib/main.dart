import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// App Screens
import 'modules/dashboard/home_screen.dart';
import 'modules/resume_progress/resume_prompt_screen.dart';
import 'modules/voice_input/voice_input_screen.dart';
import 'modules/summary/summary_screen.dart';

// Routes
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 No Firebase initialization since login is skipped
  runApp(const VoiceCVApp());
}

class VoiceCVApp extends StatelessWidget {
  const VoiceCVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice CV Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      // 🚀 Start directly on HomeScreen
      home: const HomeScreen(),
      routes: {
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.resumePrompt: (_) => const ResumePromptScreen(),
        AppRoutes.voiceInput: (_) => const VoiceInputScreen(),
        AppRoutes.summary: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return SummaryScreen(
            cvData: args['cvData'],
            totalSections: args['totalSections'],
          );
        },
      },
    );
  }
}
