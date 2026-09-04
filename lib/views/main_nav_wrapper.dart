import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'history/history_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'tasks/tasks_screen.dart';

import '../../core/services/kiosk_service.dart';
import '../../core/services/staff_auth_service.dart';
import '../../models/staff_user_model.dart';

class MainNavWrapper extends StatefulWidget {
  final int initialIndex;

  const MainNavWrapper({super.key, this.initialIndex = 0});

  @override
  State<MainNavWrapper> createState() => _MainNavWrapperState();
}

class _MainNavWrapperState extends State<MainNavWrapper> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final staff = StaffAuthService.instance.currentStaff;
      if (staff != null && staff.isKioskMode) {
        KioskService.instance.startKiosk();
      } else {
        KioskService.instance.stopKiosk();
      }
    });
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen(
          onNavigateToTasks: () => _onTabTapped(1),
        );
      case 1:
        return const TasksScreen();
      case 2:
        return const HistoryScreen();
      case 3:
        return const ProfileScreen();
      default:
        return HomeScreen(
          onNavigateToTasks: () => _onTabTapped(1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StaffUserModel?>(
      valueListenable: StaffAuthService.instance.currentStaffNotifier,
      builder: (context, currentStaff, _) {
        final isKiosk = currentStaff != null && currentStaff.isKioskMode;

        return PopScope(
          canPop: !isKiosk,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (isKiosk && _currentIndex != 0) {
              _onTabTapped(0);
            }
            // Silent block in Kiosk mode - no snackbar shown
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: _buildBody(),
            bottomNavigationBar: CustomBottomNav(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
            ),
          ),
        );
      },
    );
  }
}
