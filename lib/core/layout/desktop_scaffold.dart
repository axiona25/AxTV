import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

/// Scaffold desktop con sidebar laterale
class DesktopScaffold extends StatelessWidget {
  final Widget body;
  final String currentPath;

  const DesktopScaffold({
    super.key,
    required this.body,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(context),
          // Vertical divider
          Container(
            width: 1,
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
          ),
          // Main content
          Expanded(
            child: body,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 240,
      color: AppTheme.cardBackground,
      child: Column(
        children: [
          // Logo/Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: AppTheme.blueGlow,
                  ),
                  child: const Icon(
                    Icons.bolt,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AxTV',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            color: AppTheme.textSecondary,
            thickness: 0.5,
          ),
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.live_tv,
                  label: 'Live',
                  path: '/',
                  isActive: currentPath == '/',
                ),
                const SizedBox(height: 8),
                _buildNavItem(
                  context,
                  icon: Icons.ads_click,
                  label: 'Pubblicità',
                  path: '/advert',
                  isActive: currentPath == '/advert',
                ),
                const SizedBox(height: 8),
                _buildNavItem(
                  context,
                  icon: Icons.settings,
                  label: 'Impostazioni',
                  path: '/settings',
                  isActive: currentPath == '/settings',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String path,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryBlue.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(
                color: AppTheme.primaryBlue,
                width: 1,
              )
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary,
          ),
        ),
        onTap: () {
          if (path != currentPath) {
            context.go(path);
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
