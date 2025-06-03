// lib/widgets/checklist_item_card.dart

import 'package:flutter/material.dart';
import '../models/checklist_item.dart';
import '../theme/app_theme.dart';

/// Individual checklist item card widget
class ChecklistItemCard extends StatelessWidget {
  final ChecklistItem item;
  final int index;
  final int totalItems;
  final VoidCallback onTap;

  const ChecklistItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.totalItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: index < totalItems - 1 ? 16 : 0),
      decoration: BoxDecoration(
        color: item.isCompleted ? AppTheme.primaryTeal.withOpacity(0.1) : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isCompleted ? AppTheme.primaryTeal : AppTheme.goldenAccent.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Custom animated checkbox
                _buildAnimatedCheckbox(item.isCompleted),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with priority emoji
                      Row(
                        children: [
                          Text(
                            item.priorityEmoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.title,
                              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                color: item.isCompleted
                                    ? AppTheme.secondaryText
                                    : AppTheme.primaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Benefits
                      Text(
                        item.benefits,
                        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: item.isCompleted
                              ? AppTheme.secondaryText
                              : AppTheme.secondaryText,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCheckbox(bool isChecked) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isChecked ? AppTheme.primaryTeal : Colors.transparent,
        border: Border.all(
          color: isChecked ? AppTheme.primaryTeal : AppTheme.secondaryText,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: isChecked
          ? const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            )
          : null,
    );
  }
}
