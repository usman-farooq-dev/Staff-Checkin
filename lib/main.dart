import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'core/routes/app_routes.dart';
import 'core/services/kiosk_service.dart';
import 'core/services/reminder_sound_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'models/check_task_model.dart';
import 'models/history_record_model.dart';
import 'models/scheduled_checkin_model.dart';
import 'views/alert/compliance_alert_dialog.dart';
import 'views/auth/pin_screen.dart';
import 'views/camera/camera_capture_screen.dart';
import 'views/checklist/hygiene_checklist_screen.dart';
import 'views/history/history_detail_screen.dart';
import 'views/main_nav_wrapper.dart';
import 'views/profile/reminder_tune_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Initialize reminder sound service
  await ReminderSoundService.instance.init();

  // Initialize device Kiosk mode (Lock Task Mode / Immersive Screen Lock)
  await KioskService.instance.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const StaffCheckInApp());
}

class StaffCheckInApp extends StatelessWidget {
  const StaffCheckInApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.pin,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.pin:
            return MaterialPageRoute(
              builder: (_) => const PinScreen(),
            );
          case AppRoutes.mainNav:
            final initialIndex = settings.arguments as int? ?? 0;
            return MaterialPageRoute(
              builder: (_) => MainNavWrapper(initialIndex: initialIndex),
            );
          case AppRoutes.checklist:
            final check = settings.arguments as ScheduledCheckInModel?;
            return MaterialPageRoute(
              builder: (_) => HygieneChecklistScreen(check: check),
            );
          case AppRoutes.alertModal:
            return MaterialPageRoute(
              builder: (_) => const ComplianceAlertScreen(),
            );
          case AppRoutes.historyDetail:
            final record = settings.arguments as HistoryRecordModel?;
            return MaterialPageRoute(
              builder: (_) => HistoryDetailScreen(record: record),
            );
          case AppRoutes.cameraCapture:
            final task = settings.arguments as CheckTaskModel?;
            return MaterialPageRoute(
              builder: (_) => CameraCaptureScreen(task: task),
            );
          case AppRoutes.reminderTune:
            return MaterialPageRoute(
              builder: (_) => const ReminderTuneScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const PinScreen(),
            );
        }
      },
    );
  }
}
