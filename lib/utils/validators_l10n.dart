import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';

/// Form Validators with Localization Support
/// 
/// Use these validators when you have access to BuildContext for localized error messages.
/// For validators without context, use the Validators class.

class ValidatorsL10n {
  // Email validation
  static String? Function(String?) email(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return (String? value) {
      if (value == null || value.isEmpty) {
        return l10n.emailRequired;
      }
      
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      
      if (!emailRegex.hasMatch(value.trim())) {
        return l10n.emailInvalid;
      }
      
      return null;
    };
  }

  // Password validation (minimum 6 characters)
  static String? Function(String?) password(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return (String? value) {
      if (value == null || value.isEmpty) {
        return l10n.passwordRequired;
      }
      
      if (value.length < 6) {
        return l10n.passwordMinLength;
      }
      
      return null;
    };
  }

  // Strong password validation
  static String? Function(String?) strongPassword(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return (String? value) {
      if (value == null || value.isEmpty) {
        return l10n.passwordRequired;
      }
      
      if (value.length < 8) {
        return l10n.passwordMinLength8;
      }
      
      // Check for at least one uppercase letter
      if (!RegExp(r'[A-Z]').hasMatch(value)) {
        return l10n.passwordRequireUppercase;
      }
      
      // Check for at least one lowercase letter
      if (!RegExp(r'[a-z]').hasMatch(value)) {
        return l10n.passwordRequireLowercase;
      }
      
      // Check for at least one digit
      if (!RegExp(r'[0-9]').hasMatch(value)) {
        return l10n.passwordRequireDigit;
      }
      
      return null;
    };
  }

  // Password confirmation validation
  static String? Function(String?) confirmPassword(
    BuildContext context,
    String originalPassword,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return (String? value) {
      if (value == null || value.isEmpty) {
        return l10n.passwordConfirmRequired;
      }
      
      if (value != originalPassword) {
        return l10n.passwordNotMatch;
      }
      
      return null;
    };
  }

  // Name validation
  static String? Function(String?) name(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return (String? value) {
      if (value == null || value.isEmpty) {
        return l10n.nameRequired;
      }
      
      final trimmed = value.trim();
      
      if (trimmed.isEmpty) {
        return l10n.nameRequired;
      }
      
      if (trimmed.length < 2) {
        return l10n.nameMinLength;
      }
      
      if (trimmed.length > 50) {
        return l10n.nameMaxLength;
      }
      
      // Allow letters, spaces, and Vietnamese characters
      final nameRegex = RegExp(
        r'^[a-zA-ZÀ-ỹ\s]+$',
      );
      
      if (!nameRegex.hasMatch(trimmed)) {
        return l10n.nameLettersOnly;
      }
      
      return null;
    };
  }

  // Required field validation
  static String? Function(String?) required(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return (String? value) {
      if (value == null || value.isEmpty) {
        return l10n.fieldRequired;
      }
      
      if (value.trim().isEmpty) {
        return l10n.fieldRequired;
      }
      
      return null;
    };
  }

  // Phone number validation
  static String? Function(String?) phoneNumber(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return (String? value) {
      if (value == null || value.isEmpty) {
        return l10n.phoneNumberRequired;
      }
      
      // Remove spaces and special characters
      final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      
      // Vietnamese phone number: 10-11 digits, starts with 0
      final phoneRegex = RegExp(r'^0[0-9]{9,10}$');
      
      if (!phoneRegex.hasMatch(cleaned)) {
        return l10n.phoneNumberInvalid;
      }
      
      return null;
    };
  }

  // URL validation
  static String? Function(String?) url(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return (String? value) {
      if (value == null || value.isEmpty) {
        return l10n.urlRequired;
      }
      
      final urlRegex = RegExp(
        r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
      );
      
      if (!urlRegex.hasMatch(value.trim())) {
        return l10n.urlInvalid;
      }
      
      return null;
    };
  }

  // Number validation
  static String? Function(String?) number(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return (String? value) {
      if (value == null || value.isEmpty) {
        return l10n.numberRequired;
      }
      
      if (double.tryParse(value) == null) {
        return l10n.numberInvalid;
      }
      
      return null;
    };
  }

  // Integer validation
  static String? Function(String?) integer(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return (String? value) {
      if (value == null || value.isEmpty) {
        return l10n.numberRequired;
      }
      
      if (int.tryParse(value) == null) {
        return l10n.integerInvalid;
      }
      
      return null;
    };
  }

  // Workspace name validation
  static String? Function(String?) workspaceName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return (String? value) {
      if (value == null || value.isEmpty) {
        return l10n.workspaceNameRequired;
      }
      
      final trimmed = value.trim();
      
      if (trimmed.isEmpty) {
        return l10n.workspaceNameRequired;
      }
      
      if (trimmed.length < 3) {
        return l10n.workspaceNameMinLength;
      }
      
      if (trimmed.length > 50) {
        return l10n.workspaceNameMaxLength;
      }
      
      return null;
    };
  }

  // Task title validation
  static String? Function(String?) taskTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return (String? value) {
      if (value == null || value.isEmpty) {
        return l10n.taskTitleRequired;
      }
      
      final trimmed = value.trim();
      
      if (trimmed.isEmpty) {
        return l10n.taskTitleRequired;
      }
      
      if (trimmed.length > 200) {
        return l10n.taskTitleMaxLength;
      }
      
      return null;
    };
  }

  // Combine multiple validators
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) {
          return error;
        }
      }
      return null;
    };
  }

  // Optional validator (only validates if value is not empty)
  static String? Function(String?) optional(
    String? Function(String?) validator,
  ) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      return validator(value);
    };
  }
}
