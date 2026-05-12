import 'package:flutter/material.dart';

/// Tasks Screen — Task tracking UI matching Stitch Design System
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textVariantColor = isDark
        ? const Color(0xFFc2c6d2)
        : const Color(0xFF424751);
    final scaffoldBg = isDark
        ? const Color(0xFF0F0F1A)
        : const Color(0xFFfcf8ff);
    final cardColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final primaryColor = const Color(0xFF004782);
    final primaryContainer = const Color(0xFF185FA5);
    final outlineColor = const Color(0xFF727782);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tasks',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryContainer,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Weekly Calendar Strip
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _calendarDay(
                      'Mon',
                      '12',
                      false,
                      cardColor,
                      textColor,
                      outlineColor,
                    ),
                    _calendarDay(
                      'Tue',
                      '13',
                      false,
                      cardColor,
                      textColor,
                      outlineColor,
                    ),
                    _calendarDay(
                      'Wed',
                      '14',
                      true,
                      primaryColor,
                      Colors.white,
                      Colors.white,
                    ),
                    _calendarDay(
                      'Thu',
                      '15',
                      false,
                      cardColor,
                      textColor,
                      outlineColor,
                    ),
                    _calendarDay(
                      'Fri',
                      '16',
                      false,
                      cardColor,
                      textColor,
                      outlineColor,
                    ),
                    _calendarDay(
                      'Sat',
                      '17',
                      false,
                      cardColor,
                      textColor,
                      outlineColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _filterChip(
                      'All',
                      true,
                      primaryContainer,
                      cardColor,
                      textVariantColor,
                    ),
                    _filterChip(
                      'Today',
                      false,
                      primaryContainer,
                      cardColor,
                      textVariantColor,
                    ),
                    _filterChip(
                      'Upcoming',
                      false,
                      primaryContainer,
                      cardColor,
                      textVariantColor,
                    ),
                    _filterChip(
                      'Done',
                      false,
                      primaryContainer,
                      cardColor,
                      textVariantColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Today Section
              Text(
                'Today',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              _taskCard(
                'Review Q3 Marketing Deck',
                '10:00 AM',
                'High',
                const Color(0xFFffdad6),
                const Color(0xFF93000a),
                false,
                cardColor,
                textColor,
                outlineColor,
                primaryColor,
              ),
              const SizedBox(height: 12),
              _taskCard(
                'Team Sync',
                '2:30 PM',
                'Medium',
                const Color(0xFFe2e0fc),
                const Color(0xFF424751),
                false,
                cardColor,
                textColor,
                outlineColor,
                primaryColor,
              ),
              const SizedBox(height: 12),
              _taskCard(
                'Reply to Client Emails',
                '9:00 AM',
                'Low',
                const Color(0xFFe2e0fc),
                const Color(0xFF424751),
                true,
                cardColor,
                textColor,
                outlineColor,
                primaryColor,
              ),

              const SizedBox(height: 32),

              // Tomorrow Section
              Text(
                'Tomorrow',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              _taskCard(
                'Draft Budget Proposal',
                '11:00 AM',
                'High',
                const Color(0xFFffdad6),
                const Color(0xFF93000a),
                false,
                cardColor,
                textColor,
                outlineColor,
                primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _calendarDay(
    String day,
    String date,
    bool isSelected,
    Color bgColor,
    Color textColor,
    Color subColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 48,
      height: 64,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(day, style: TextStyle(fontSize: 12, color: subColor)),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    String text,
    bool isSelected,
    Color primaryColor,
    Color bgColor,
    Color textVariantColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor : bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isSelected
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          color: isSelected ? Colors.white : textVariantColor,
        ),
      ),
    );
  }

  Widget _taskCard(
    String title,
    String time,
    String priority,
    Color badgeBg,
    Color badgeText,
    bool isDone,
    Color cardColor,
    Color textColor,
    Color outlineColor,
    Color primaryColor,
  ) {
    return Opacity(
      opacity: isDone ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone ? primaryColor : Colors.transparent,
                border: Border.all(
                  color: isDone ? primaryColor : outlineColor,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: isDone
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: outlineColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(fontSize: 12, color: outlineColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                priority,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: badgeText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
