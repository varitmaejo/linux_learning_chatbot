import '../constants/app_constants.dart';

class ValidationUtils {
  ValidationUtils._();

  // Email validation
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'กรุณาระบุอีเมล';
    }

    if (email.length > AppConstants.maxEmailLength) {
      return 'อีเมลยาวเกินไป (สูงสุด ${AppConstants.maxEmailLength} ตัวอักษร)';
    }

    if (!RegExp(AppConstants.emailPattern).hasMatch(email)) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'กรุณาระบุรหัสผ่าน';
    }

    if (password.length < AppConstants.minPasswordLength) {
      return 'รหัสผ่านต้องมีอย่างน้อย ${AppConstants.minPasswordLength} ตัวอักษร';
    }

    if (password.length > AppConstants.maxPasswordLength) {
      return 'รหัสผ่านยาวเกินไป (สูงสุด ${AppConstants.maxPasswordLength} ตัวอักษร)';
    }

    // Check for at least one letter and one number
    if (!password.contains(RegExp(r'[a-zA-Z]'))) {
      return 'รหัสผ่านต้องมีตัวอักษรอย่างน้อย 1 ตัว';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'รหัสผ่านต้องมีตัวเลขอย่างน้อย 1 ตัว';
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'กรุณายืนยันรหัสผ่าน';
    }

    if (password != confirmPassword) {
      return 'รหัสผ่านไม่ตรงกัน';
    }

    return null;
  }

  // Username validation
  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'กรุณาระบุชื่อผู้ใช้';
    }

    if (username.length < AppConstants.minUsernameLength) {
      return 'ชื่อผู้ใช้ต้องมีอย่างน้อย ${AppConstants.minUsernameLength} ตัวอักษร';
    }

    if (username.length > AppConstants.maxUsernameLength) {
      return 'ชื่อผู้ใช้ยาวเกินไป (สูงสุด ${AppConstants.maxUsernameLength} ตัวอักษร)';
    }

    if (!RegExp(AppConstants.usernamePattern).hasMatch(username)) {
      return 'ชื่อผู้ใช้สามารถใช้ได้เฉพาะตัวอักษร ตัวเลข และ _ เท่านั้น';
    }

    return null;
  }

  // Display name validation
  static String? validateDisplayName(String? displayName) {
    if (displayName == null || displayName.isEmpty) {
      return 'กรุณาระบุชื่อที่แสดง';
    }

    if (displayName.length > 50) {
      return 'ชื่อที่แสดงยาวเกินไป (สูงสุด 50 ตัวอักษร)';
    }

    // Check for inappropriate characters
    if (displayName.contains(RegExp(r'[<>"/\\|?*]'))) {
      return 'ชื่อที่แสดงมีตัวอักษรที่ไม่อนุญาต';
    }

    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return null; // Phone number is optional
    }

    // Remove all non-digit characters
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');

    if (!RegExp(AppConstants.phonePattern).hasMatch(cleanPhone)) {
      return 'หมายเลขโทรศัพท์ไม่ถูกต้อง (ต้องเป็น 10 หลัก)';
    }

    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณาระบุ$fieldName';
    }
    return null;
  }

  // Message validation
  static String? validateMessage(String? message) {
    if (message == null || message.trim().isEmpty) {
      return 'กรุณาพิมพ์ข้อความ';
    }

    if (message.length > AppConstants.maxMessageLength) {
      return 'ข้อความยาวเกินไป (สูงสุด ${AppConstants.maxMessageLength} ตัวอักษร)';
    }

    return null;
  }

  // Feedback validation
  static String? validateFeedback(String? feedback) {
    if (feedback == null || feedback.trim().isEmpty) {
      return 'กรุณาระบุข้อเสนอแนะ';
    }

    if (feedback.length > AppConstants.maxFeedbackLength) {
      return 'ข้อเสนอแนะยาวเกินไป (สูงสุด ${AppConstants.maxFeedbackLength} ตัวอักษร)';
    }

    return null;
  }

  // Linux command validation
  static String? validateLinuxCommand(String? command) {
    if (command == null || command.trim().isEmpty) {
      return 'กรุณาระบุคำสั่ง';
    }

    // Check for potentially dangerous commands
    final dangerousCommands = ['rm -rf /', 'dd if=', 'mkfs', 'fdisk', 'format'];
    final lowerCommand = command.toLowerCase();

    for (final dangerous in dangerousCommands) {
      if (lowerCommand.contains(dangerous)) {
        return 'คำสั่งนี้อาจเป็นอันตรายและไม่อนุญาตให้ใช้ในโหมดฝึกฝน';
      }
    }

    return null;
  }

  // File size validation
  static String? validateFileSize(int fileSizeBytes, int maxSizeBytes) {
    if (fileSizeBytes > maxSizeBytes) {
      final maxSizeMB = (maxSizeBytes / (1024 * 1024)).toStringAsFixed(1);
      return 'ไฟล์ขนาดใหญ่เกินไป (สูงสุด ${maxSizeMB}MB)';
    }
    return null;
  }

  // Age validation
  static String? validateAge(String? age) {
    if (age == null || age.isEmpty) {
      return 'กรุณาระบุอายุ';
    }

    final ageInt = int.tryParse(age);
    if (ageInt == null) {
      return 'อายุต้องเป็นตัวเลข';
    }

    if (ageInt < 13) {
      return 'อายุต้องมากกว่า 13 ปี';
    }

    if (ageInt > 100) {
      return 'อายุไม่ถูกต้อง';
    }

    return null;
  }

  // URL validation
  static String? validateUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null; // URL is optional
    }

    final urlRegex = RegExp(
        r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)
    );

    if (!urlRegex.hasMatch(url)) {
      return 'URL ไม่ถูกต้อง';
    }

    return null;
  }

  // Numeric validation
  static String? validateNumeric(String? value, String fieldName, {int? min, int? max}) {
    if (value == null || value.isEmpty) {
      return 'กรุณาระบุ$fieldName';
    }

    final number = int.tryParse(value);
    if (number == null) {
      return '$fieldName ต้องเป็นตัวเลข';
    }

    if (min != null && number < min) {
      return '$fieldName ต้องมีค่าอย่างน้อย $min';
    }

    if (max != null && number > max) {
      return '$fieldName ต้องมีค่าไม่เกิน $max';
    }

    return null;
  }

  // Double validation
  static String? validateDouble(String? value, String fieldName, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return 'กรุณาระบุ$fieldName';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName ต้องเป็นตัวเลข';
    }

    if (min != null && number < min) {
      return '$fieldName ต้องมีค่าอย่างน้อย $min';
    }

    if (max != null && number > max) {
      return '$fieldName ต้องมีค่าไม่เกิน $max';
    }

    return null;
  }

  // Date validation
  static String? validateDate(String? date) {
    if (date == null || date.isEmpty) {
      return 'กรุณาระบุวันที่';
    }

    try {
      final parsedDate = DateTime.parse(date);
      final now = DateTime.now();

      if (parsedDate.isAfter(now)) {
        return 'วันที่ไม่สามารถเป็นอนาคตได้';
      }

      // Check if date is too far in the past (more than 100 years)
      final hundredYearsAgo = now.subtract(const Duration(days: 365 * 100));
      if (parsedDate.isBefore(hundredYearsAgo)) {
        return 'วันที่ไม่ถูกต้อง';
      }

    } catch (e) {
      return 'รูปแบบวันที่ไม่ถูกต้อง';
    }

    return null;
  }

  // Multiple choice validation
  static String? validateMultipleChoice(List<String>? selectedValues, {int? minSelections, int? maxSelections}) {
    if (selectedValues == null || selectedValues.isEmpty) {
      if (minSelections != null && minSelections > 0) {
        return 'กรุณาเลือกอย่างน้อย $minSelections รายการ';
      }
      return null;
    }

    if (minSelections != null && selectedValues.length < minSelections) {
      return 'กรุณาเลือกอย่างน้อย $minSelections รายการ';
    }

    if (maxSelections != null && selectedValues.length > maxSelections) {
      return 'สามารถเลือกได้สูงสุด $maxSelections รายการ';
    }

    return null;
  }

  // Credit card validation (for future premium features)
  static String? validateCreditCard(String? cardNumber) {
    if (cardNumber == null || cardNumber.isEmpty) {
      return 'กรุณาระบุหมายเลขบัตร';
    }

    // Remove spaces and dashes
    final cleanCard = cardNumber.replaceAll(RegExp(r'[\s-]'), '');

    // Check if all digits
    if (!RegExp(r'^\d+).hasMatch(cleanCard)) {
        return 'หมายเลขบัตรต้องเป็นตัวเลขเท่านั้น';
    }

  // Check length (13-19 digits for most cards)
  if (cleanCard.length < 13 || cleanCard.length > 19) {
  return 'หมายเลขบัตรไม่ถูกต้อง';
  }

  // Luhn algorithm validation
  if (!_luhnCheck(cleanCard)) {
  return 'หมายเลขบัตรไม่ถูกต้อง';
  }

  return null;
}

// Luhn algorithm for credit card validation
static bool _luhnCheck(String cardNumber) {
int sum = 0;
bool alternate = false;

for (int i = cardNumber.length - 1; i >= 0; i--) {
int digit = int.parse(cardNumber[i]);

if (alternate) {
digit *= 2;
if (digit > 9) {
digit = (digit % 10) + 1;
}
}

sum += digit;
alternate = !alternate;
}

return (sum % 10) == 0;
}

// CVV validation
static String? validateCVV(String? cvv) {
if (cvv == null || cvv.isEmpty) {
return 'กรุณาระบุ CVV';
}

if (!RegExp(r'^\d{3,4}).hasMatch(cvv)) {
return 'CVV ต้องเป็นตัวเลข 3-4 หลัก';
}

return null;
}

// Custom regex validation
static String? validateRegex(String? value, String pattern, String errorMessage) {
if (value == null || value.isEmpty) {
return null;
}

if (!RegExp(pattern).hasMatch(value)) {
return errorMessage;
}

return null;
}

// Combine multiple validators
static String? combineValidators(String? value, List<String? Function(String?)> validators) {
for (final validator in validators) {
final result = validator(value);
if (result != null) {
return result;
}
}
return null;
}

// Sanitize input
static String sanitizeInput(String input) {
return input
    .trim()
    .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
    .replaceAll(RegExp(r'[<>"&]'), ''); // Remove potentially dangerous characters
}

// Check if string contains only Thai characters
static bool isThaiText(String text) {
return RegExp(r'^[\u0E00-\u0E7F\s]+).hasMatch(text);
}

// Check if string contains only English characters
static bool isEnglishText(String text) {
return RegExp(r'^[a-zA-Z\s]+).hasMatch(text);
}

// Validate Thai ID card number
static String? validateThaiId(String? idNumber) {
if (idNumber == null || idNumber.isEmpty) {
return null; // Optional field
}

// Remove all non-digit characters
final cleanId = idNumber.replaceAll(RegExp(r'\D'), '');

if (cleanId.length != 13) {
return 'เลขบัตรประชาชนต้องเป็น 13 หลัก';
}

// Validate checksum
int sum = 0;
for (int i = 0; i < 12; i++) {
sum += int.parse(cleanId[i]) * (13 - i);
}

final checkDigit = (11 - (sum % 11)) % 10;
final lastDigit = int.parse(cleanId[12]);

if (checkDigit != lastDigit) {
return 'เลขบัตรประชาชนไม่ถูกต้อง';
}

return null;
}
}