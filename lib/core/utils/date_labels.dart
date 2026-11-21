// Short, friendly date and time labels for lists.

/// Section label for a day: Today, Yesterday, a weekday within the past
/// week, otherwise "18 Nov 2026".
String dayLabel(DateTime when, {DateTime? now}) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final n = now ?? DateTime.now();
  final local = when.toLocal();
  final day = DateTime(local.year, local.month, local.day);
  final today = DateTime(n.year, n.month, n.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff > 1 && diff < 7) return weekdays[local.weekday - 1];
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

String timeLabel(DateTime when) {
  final l = when.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:'
      '${l.minute.toString().padLeft(2, '0')}';
}
