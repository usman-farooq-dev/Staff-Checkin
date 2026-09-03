import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/staff_auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pin_keypad_widget.dart';
import '../alert/staff_alert_dialog.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  bool _isLoading = false;
  static const int _maxPinLength = 4;

  void _onDigitPressed(String digit) {
    if (_isLoading) return;
    if (_pin.length < _maxPinLength) {
      setState(() {
        _pin += digit;
      });
    }
  }

  void _onDeletePressed() {
    if (_isLoading) return;
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _verifyPinAndProceed() async {
    if (_pin.length < _maxPinLength || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final result = await StaffAuthService.instance.authenticateWithPin(_pin);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    switch (result.status) {
      case StaffAuthStatus.success:
        // Show short success feedback and navigate
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Welcome, ${result.staff?.fullName ?? "Staff"}!'),
              ],
            ),
            backgroundColor: const Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.of(context).pushReplacementNamed(AppRoutes.mainNav);
        break;

      case StaffAuthStatus.invalidPin:
        await StaffAlertDialog.showInvalidPin(
          context,
          message: result.message,
          onDismiss: () {
            if (mounted) {
              setState(() {
                _pin = '';
              });
            }
          },
        );
        break;

      case StaffAuthStatus.inactiveAccount:
        await StaffAlertDialog.showInactiveAccount(
          context,
          staffName: result.staff?.fullName ?? 'Staff',
          staffId: result.staff?.staffId,
          onDismiss: () {
            if (mounted) {
              setState(() {
                _pin = '';
              });
            }
          },
        );
        break;

      case StaffAuthStatus.error:
        await StaffAlertDialog.showError(
          context,
          message: result.message,
          onDismiss: () {
            if (mounted) {
              setState(() {
                _pin = '';
              });
            }
          },
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top App Logo & Name
                    Column(
                      children: [
                        const SizedBox(height: 12),
                        Image.asset(
                          AppAssets.icStaffCheckin,
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Staff Check-In',
                          style: AppStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    // Center Content: Title, Subtitle, Dots, Keypad
                    Column(
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          'Enter Your PIN',
                          style: AppStyles.heading1.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your PIN links compliance evidence to you.',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // PIN indicator dots
                        PinIndicatorDots(
                          length: _maxPinLength,
                          filledCount: _pin.length,
                        ),
                        const SizedBox(height: 28),

                        // Numeric Keypad
                        AbsorbPointer(
                          absorbing: _isLoading,
                          child: PinKeypadWidget(
                            onDigitPressed: _onDigitPressed,
                            onDeletePressed: _onDeletePressed,
                          ),
                        ),
                      ],
                    ),

                    // Bottom Continue Button
                    Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 8),
                      child: CustomButton(
                        text: _isLoading ? 'VERIFYING...' : 'CONTINUE',
                        isLoading: _isLoading,
                        height: 50,
                        borderRadius: 10,
                        onPressed: _pin.length == _maxPinLength && !_isLoading
                            ? _verifyPinAndProceed
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
