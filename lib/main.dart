// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Auth Screens
import 'modules/auth/screens/sign_in_screen.dart';

// App Screens
import 'modules/dashboard/home_screen.dart';
import 'modules/resume_progress/resume_prompt_screen.dart';
import 'modules/voice_input/voice_input_screen.dart';
import 'modules/summary/summary_screen.dart';
import 'modules/ai_animation/ai_processing_screen.dart';
import 'modules/cv_preview/preview_screen.dart';
import 'modules/library/screens/library_screen.dart';

// Routes
import 'routes/app_routes.dart';
import 'models/cv_model.dart';
import 'models/pigeon_user_details.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("❌ Firebase initialization error: $e");
  }

  /// 🔥 Automatically sign in test user and fetch user details
 // await signInTestUser();

  runApp(const VoiceCVApp());
}

/// ✅ Automatically sign in test user and load Firestore user details
// Future<PigeonUserDetails?> signInTestUser() async {
//   try {
//     final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
//       email: 'testuser1@example.com',
//       password: 'Test12345',
//     );
//     debugPrint('✅ Test user signed in: ${userCredential.user!.uid}');
//
//     // Fetch user data from Firestore
//     final snapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(userCredential.user!.uid)
//         .get();
//
//     final data = snapshot.data(); // Map<String, dynamic>?
//
//     if (data != null) {
//       final userDetails = PigeonUserDetails.fromMap(data);
//       debugPrint('✅ User details loaded: ${userDetails.name}');
//       return userDetails;
//     }
//   } catch (e) {
//     debugPrint('❌ Error signing in test user: $e');
//   }
//   return null;
// }

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

      /// 🔥 Directly open HomeScreen instead of Splash/Login
      home: const SignInScreen(),

      routes: {
        AppRoutes.login: (_) => const SignInScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.resumePrompt: (_) => const ResumePromptScreen(),
        AppRoutes.voiceInput: (_) => VoiceInputScreen(),
        AppRoutes.library: (_) => const LibraryScreen(),

        /// ✅ Summary Screen now expects a CVModel
        AppRoutes.summary: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as CVModel;
          return SummaryScreen(cv: args);
        },

        /// ✅ AI Processing Screen with CVModel
        AppRoutes.aiProcessing: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as CVModel;
          return AIProcessingScreen(rawCV: args);
        },

        /// ✅ Preview Screen with CVModel
        AppRoutes.preview: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as CVModel;
          return PreviewScreen(cv: args);
        },
      },
    );
  }
}
