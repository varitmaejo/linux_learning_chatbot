import 'package:intl/intl.dart';

class DateUtils {
  DateUtils._();

  // Thai month names
  static const List<String> thaiMonths = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน',
    'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม',
    'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
  ];

  // Thai short month names
  static const List<String> thaiShortMonths = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.',
    'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.',
    'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
  ];

  // Thai day names
  static const List<String> thaiDays = [
    'จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี',
    'ศุกร์', 'เสาร์', 'อาทิตย์'
  ];

  // Thai short day names
  static const List<String> thaiShortDays = [
    'จ.', 'อ.', 'พ.', 'พฤ.',
    'ศ.', 'ส.', 'อา.'
  ];

  // Format date in Thai
  static String formatThaiDate(DateTime date) {
    final day = date.day;
    final month = thaiMonths[date.month - 1];
    final year = date.year + 543; // Convert to Buddhist Era

    return '$day $month $year';
  }

  // Format short Thai date
  static String formatShortThaiDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = thaiShortMonths[date.month - 1];
    final year = (date.year + 543).toString().substring(2); // Last 2 digits

    return '$day $month $year';
  }

  // Format date with day name in Thai
  static String formatThaiDateWithDay(DateTime date) {
    final dayName = thaiDays[date.weekday - 1];
    final formattedDate = formatThaiDate(date);

    return 'วัน$dayName ที่ $formattedDate';
  }

  // Format time in Thai format
  static String formatThaiTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute น.';
  }

  // Format date and time in Thai
  static String formatThaiDateTime(DateTime dateTime) {
    final date = formatThaiDate(dateTime);
    final time = formatThaiTime(dateTime);

    return '$date เวลา $time';
  }

  // Get relative time in Thai (e.g., "2 นาทีที่แล้ว")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'เมื่อสักครู่';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '${minutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '${hours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '${days} วันที่แล้ว';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks} สัปดาห์ที่แล้ว';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months} เดือนที่แล้ว';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years} ปีที่แล้ว';
    }
  }

  // Get time ago with more precision
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 30) {
      return 'ตอนนี้';
    } else if (difference.inMinutes < 1) {
      return '${difference.inSeconds} วินาทีที่แล้ว';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else {
      return formatShortThaiDate(dateTime);
    }
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  // Check if date is this week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return date.isAfter(startOfWeek) && date.isBefore(endOfWeek);
  }

  // Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  // Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: daysFromMonday)));
  }

  // Get end of week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    final daysUntilSunday = 7 - date.weekday;
    return endOfDay(date.add(Duration(days: daysUntilSunday)));
  }

  // Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Get end of month
  static DateTime endOfMonth(DateTime date) {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1));
  }

  // Get age in years
  static int getAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;

    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  // Format duration in Thai
  static String formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds} วินาที';
    } else if (duration.inMinutes < 60) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      if (seconds == 0) {
        return '$minutes นาที';
      }
      return '$minutes นาที $seconds วินาที';
    } else if (duration.inHours < 24) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes == 0) {
        return '$hours ชั่วโมง';
      }
      return '$hours ชั่วโมง $minutes นาที';
    } else {
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      if (hours == 0) {
        return '$days วัน';
      }
      return '$days วัน $hours ชั่วโมง';
    }
  }

  // Format study time (for learning statistics)
  static String formatStudyTime(int seconds) {
    if (seconds < 60) {
      return '$seconds วินาที';
    } else if (seconds < 3600) {
      final minutes = (seconds / 60).floor();
      final remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '$minutes นาที';
      }
      return '$minutes นาที $remainingSeconds วินาที';
    } else {
      final hours = (seconds / 3600).floor();
      final remainingMinutes = ((seconds % 3600) / 60).floor();
      if (remainingMinutes == 0) {
        return '$hours ชั่วโมง';
      }
      return '$hours ชั่วโมง $remainingMinutes นาที';
    }
  }

  // Get greeting based on time
  static String getTimeGreeting() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour < 6) {
      return 'สวัสดียามดึก';
    } else if (hour < 12) {
      return 'สวัสดีตอนเช้า';
    } else if (hour < 17) {
      return 'สวัสดีตอนบ่าย';
    } else if (hour < 20) {
      return 'สวัสดีตอนเย็น';
    } else {
      return 'สวัสดีตอนค่ำ';
    }
  }

  // Parse Thai date string
  static DateTime? parseThaiDate(String thaiDateString) {
    try {
      // Handle various Thai date formats
      final patterns = [
        RegExp(r'(\d{1,2})\s+(มกราคม|กุมภาพันธ์|มีนาคม|เมษายน|พฤษภาคม|มิถุนายน|กรกฎาคม|สิงหาคม|กันยายน|ตุลาคม|พฤศจิกายน|ธันวาคม)\s+(\d{4})'),
        RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})'),
        RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(thaiDateString);
        if (match != null) {
          if (pattern == patterns[0]) {
            // Thai month name format
            final day = int.parse(match.group(1)!);
            final monthName = match.group(2)!;
            final year = int.parse(match.group(3)!) - 543; // Convert from Buddhist Era
            final month = thaiMonths.indexOf(monthName) + 1;

            return DateTime(year, month, day);
          } else {
            // Numeric formats
            final parts = match.groups([1, 2, 3]).map((g) => int.parse(g!)).toList();
            if (pattern == patterns[1]) {
              // DD/MM/YYYY
              return DateTime(parts[2], parts[1], parts[0]);
            } else {
              // YYYY-MM-DD
              return DateTime(parts[0], parts[1], parts[2]);
            }
          }
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // Get calendar week number
  static int getWeekNumber(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  // Check if year is leap year
  static bool isLeapYear(int year) {
    return (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0);
  }

  // Get days in month
  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  // Add business days (excluding weekends)
  static DateTime addBusinessDays(DateTime date, int businessDays) {
    DateTime result = date;
    int addedDays = 0;

    while (addedDays < businessDays) {
      result = result.add(const Duration(days: 1));
      if (result.weekday < 6) { // Monday = 1, Friday = 5
        addedDays++;
      }
    }

    return result;
  }

  // Count business days between two dates
  static int countBusinessDays(DateTime startDate, DateTime endDate) {
    if (startDate.isAfter(endDate)) {
      return 0;
    }

    int businessDays = 0;
    DateTime current = startDate;

    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      if (current.weekday < 6) { // Monday = 1, Friday = 5
        businessDays++;
      }
      current = current.add(const Duration(days: 1));
    }

    return businessDays;
  }

  // Format for API (ISO 8601)
  static String formatForApi(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  // Parse from API (ISO 8601)
  static DateTime? parseFromApi(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Get learning streak display text
  static String getStreakText(int days) {
    if (days == 0) {
      return 'ยังไม่เริ่มต้น';
    } else if (days == 1) {
      return '1 วัน';
    } else {
      return '$days วันต่อเนื่อง';
    }
  }

  // Get next reminder time (for notifications)
  static DateTime getNextReminderTime({int hour = 19, int minute = 0}) {
    final now = DateTime.now();
    DateTime reminderTime = DateTime(now.year, now.month, now.day, hour, minute);

    // If the reminder time has passed today, schedule for tomorrow
    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }

    return reminderTime;
  }

  // Format birthday (hide year if needed)
  static String formatBirthday(DateTime birthday, {bool showYear = true}) {
    if (showYear) {
      return formatThaiDate(birthday);
    } else {
      final day = birthday.day;
      final month = thaiMonths[birthday.month - 1];
      return '$day $month';
    }
  }
}