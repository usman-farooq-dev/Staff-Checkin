import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';
import '../core/constants/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBg,
        border: Border(
          top: BorderSide(
            color: AppColors.navBorder,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                selectedAsset: AppAssets.navHomeSelected,
                unselectedAsset: AppAssets.navHomeNon,
              ),
              _buildNavItem(
                index: 1,
                selectedAsset: AppAssets.navTaskSelected,
                unselectedAsset: AppAssets.navTaskNon,
              ),
              _buildNavItem(
                index: 2,
                selectedAsset: AppAssets.navHistorySelected,
                unselectedAsset: AppAssets.navHistoryNon,
              ),
              _buildNavItem(
                index: 3,
                selectedAsset: AppAssets.navProfileSelected,
                unselectedAsset: AppAssets.navProfileNon,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String selectedAsset,
    required String unselectedAsset,
  }) {
    final bool isSelected = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Center(
          child: Image.asset(
            isSelected ? selectedAsset : unselectedAsset,
            height: 60,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
