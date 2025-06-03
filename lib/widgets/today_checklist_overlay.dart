// lib/widgets/today_checklist_overlay.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../models/checklist_item.dart';
import '../services/checklist_service.dart';
import '../theme/app_theme.dart';
import 'checklist_item_card.dart';

/// Rich, animated checklist overlay that appears post-onboarding
class TodayChecklistOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final List<ChecklistItem>? testItems; // For testing purposes

  const TodayChecklistOverlay({
    super.key,
    required this.onComplete,
    required this.onSkip,
    this.testItems,
  });

  @override
  State<TodayChecklistOverlay> createState() => _TodayChecklistOverlayState();
}

class _TodayChecklistOverlayState extends State<TodayChecklistOverlay>
    with TickerProviderStateMixin {
  late AnimationController _overlayController;
  late AnimationController _cardController;
  late AnimationController _itemsController;

  late Animation<double> _overlayAnimation;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;
  late Animation<double> _itemsAnimation;

  List<ChecklistItem> _checklistItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadChecklist();
  }

  void _setupAnimations() {
    // Overlay backdrop animation
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _overlayAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _overlayController, curve: Curves.easeOut),
    );

    // Card slide-up animation
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardSlideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );
    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOut),
    );

    // Items staggered animation
    _itemsController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _itemsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _itemsController, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _loadChecklist() async {
    try {
      final items = widget.testItems ?? await ChecklistService.instance.getTodaysChecklist();
      setState(() {
        _checklistItems = items.take(3).toList(); // always show three
        _isLoading = false;
      });
      _startAnimations();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error gracefully
    }
  }

  void _startAnimations() {
    _overlayController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      _cardController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _itemsController.forward();
    });
  }

  Future<void> _closeOverlay() async {
    await _itemsController.reverse();
    await _cardController.reverse();
    await _overlayController.reverse();

    // Use Navigator.pop to properly close the overlay
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _overlayController.dispose();
    _cardController.dispose();
    _itemsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _overlayAnimation,
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Backdrop with blur
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 10.0 * _overlayAnimation.value,
                    sigmaY: 10.0 * _overlayAnimation.value,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.4 * _overlayAnimation.value),
                  ),
                ),
              ),

              // Main content - properly centered
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _cardController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 50 * _cardSlideAnimation.value),
                          child: Opacity(
                            opacity: _cardFadeAnimation.value,
                            child: _buildChecklistCard(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChecklistCard() {
    // Margin now only 24 px; we'll add *internal* space in step 3.
    return Container(
      key: const ValueKey('ChecklistCard'),
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      constraints: BoxConstraints(
        maxWidth: 400,
        maxHeight: MediaQuery.of(context).size.height * 0.8, // Limit to 80% of screen height
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: AppTheme.goldenBorder,
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 32),        // 3️⃣ internal white-space
          _buildHeader(),
          if (_isLoading)
            _buildLoadingState()
          else
            Flexible(child: _buildChecklistContent()),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryTeal, AppTheme.deepTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.checklist_rtl,
            color: AppTheme.lightText,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            'Today\'s Sunnah Checklist',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightText,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Start your day with these blessed practices',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightText.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
          ),
          const SizedBox(height: 16),
          Text(
            'Preparing your Sunnah checklist...',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AnimatedBuilder(
        animation: _itemsAnimation,
        builder: (context, child) {
          return Column(
            children: _checklistItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final delay = index * 0.2;
              final itemAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _itemsAnimation,
                  curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
                ),
              );

              return AnimatedBuilder(
                animation: itemAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - itemAnimation.value)),
                    child: Opacity(
                      opacity: itemAnimation.value,
                      child: ChecklistItemCard(
                        item: item,
                        index: index,
                        totalItems: _checklistItems.length,
                        onTap: () => _toggleItemCompletion(item),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }



  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Complete/Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: AppTheme.lightText,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                _getCompletedCount() > 0 ? 'Start Your Day' : 'Start Your Day',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Skip button
          TextButton(
            onPressed: _handleSkip,
            child: Text(
              'Skip for now',
              style: TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleItemCompletion(ChecklistItem item) async {
    final newStatus = !item.isCompleted;

    // Add haptic feedback
    if (newStatus) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }

    // Update local state immediately for smooth UX
    setState(() {
      final index = _checklistItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _checklistItems[index] = item.copyWith(isCompleted: newStatus);
      }
    });

    // Update persistent storage
    await ChecklistService.instance.updateItemCompletion(item.id, newStatus);
  }

  int _getCompletedCount() {
    return _checklistItems.where((item) => item.isCompleted).length;
  }

  Future<void> _handleComplete() async {
    print('TodayChecklistOverlay._handleComplete: starting completion process');

    // Sync completed checklist items to dashboard
    await _syncCompletedItemsToDashboard();

    await ChecklistService.instance.markChecklistShown();

    print('TodayChecklistOverlay._handleComplete: calling onComplete callback');
    widget.onComplete();

    await _closeOverlay();
  }

  /// Sync completed checklist items to dashboard as active habits
  Future<void> _syncCompletedItemsToDashboard() async {
    final completedItems = _checklistItems.where((item) => item.isCompleted).toList();

    print('TodayChecklistOverlay._syncCompletedItemsToDashboard: found ${completedItems.length} completed items');
    for (final item in completedItems) {
      print('TodayChecklistOverlay._syncCompletedItemsToDashboard: completed item: "${item.title}" (${item.category})');
    }

    if (completedItems.isNotEmpty) {
      await ChecklistService.instance.syncCompletedItemsToDashboard(completedItems);
    } else {
      print('TodayChecklistOverlay._syncCompletedItemsToDashboard: no completed items to sync');
    }
  }

  Future<void> _handleSkip() async {
    await ChecklistService.instance.markChecklistShown();
    widget.onSkip();
    await _closeOverlay();
  }

}

/// Show the checklist overlay
Future<void> showTodayChecklistOverlay(
  BuildContext context, {
  required VoidCallback onComplete,
  required VoidCallback onSkip,
}) async {
  // Use Navigator.push instead of showDialog to avoid focus issues
  await Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => TodayChecklistOverlay(
        onComplete: onComplete,
        onSkip: onSkip,
      ),
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      opaque: false, // Allow background to show through
      barrierDismissible: false,
    ),
  );
}
