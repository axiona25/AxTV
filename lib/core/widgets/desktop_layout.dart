import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';

/// Layout desktop con sidebar per macOS
class DesktopLayout extends ConsumerStatefulWidget {
  final Widget child;
  final int selectedIndex;

  const DesktopLayout({
    super.key,
    required this.child,
    this.selectedIndex = 0,
  });

  @override
  ConsumerState<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends ConsumerState<DesktopLayout> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(DesktopLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _selectedIndex = widget.selectedIndex;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/advert');
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Su mobile/tablet, usa layout normale senza sidebar
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
      return widget.child;
    }

    return Row(
      children: [
        // Sidebar
        Container(
          width: 250,
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            border: Border(
              right: BorderSide(
                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Logo/Header
              Container(
                padding: const EdgeInsets.all(24),
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
              
              // Navigation Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildNavItem(
                      icon: Icons.live_tv,
                      label: 'Live',
                      index: 0,
                    ),
                    const SizedBox(height: 4),
                    _buildNavItem(
                      icon: Icons.ads_click,
                      label: 'Pubblicità',
                      index: 1,
                    ),
                    const SizedBox(height: 4),
                    _buildNavItem(
                      icon: Icons.settings,
                      label: 'Impostazioni',
                      index: 2,
                    ),
                  ],
                ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'v0.1.0',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        
        // Content Area
        Expanded(
          child: widget.child,
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryBlue.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(
                color: AppTheme.primaryBlue,
                width: 1,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : AppTheme.textSecondary,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
