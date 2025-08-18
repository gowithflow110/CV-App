import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// App Screens
import 'modules/dashboard/home_screen.dart';
import 'modules/resume_progress/resume_prompt_screen.dart';
import 'modules/voice_input/voice_input_screen.dart';
import 'modules/summary/summary_screen.dart';
import 'modules/cv_preview/preview_screen.dart';
import 'modules/edit_cv/edit_cv_screen.dart';

// Models
import 'models/cv_model.dart';

// Routes
import 'routes/app_routes.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Sign in test user for bypassing Google
  User? currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    try {
      currentUser = (await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'testuser@example.com', // <-- Replace with your Firebase test user email
        password: 'TestPassword123',    // <-- Replace with your Firebase test user password
      ))
          .user;
      print("Test user signed in: ${currentUser?.email}");
    } catch (e) {
      print("Failed to sign in test user: $e");
    }
  } else {
    print("User already signed in: ${currentUser.email}");
  }

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
      // ✅ Skip login and go straight to HomeScreen
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
        AppRoutes.preview: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

          final cvData = CVModel(
            name: args['name'] as String?,
            title: args['title'] as String?,
            email: args['email'] as String?,
            phone: args['phone'] as String?,
            location: args['location'] as String?,
            linkedin: args['linkedin'] as String?,
            summary: args['summary'] as String?,
            skills: (args['skills'] as List<dynamic>?)?.cast<String>(),
            experiences: (args['experiences'] as List<dynamic>?)
                ?.map((e) => CVExperience.fromMap(e as Map<String, dynamic>))
                .toList(),
          );

          return CVPreviewScreen(cvData: cvData);
        },
        AppRoutes.editCV: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return EditCVSectionScreen(
            sectionKey: args['sectionKey'],
            sectionValue: args['sectionValue'],
          );
        },
      },
    );
  }
}
