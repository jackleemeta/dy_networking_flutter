import 'dart:convert';

extension StringExtension on String {
  static bool isEmpty(String str) {
    if (str == null) {
      return true;
    }
    if (str.length <= 0) {
      return true;
    }

    return false;
  }
}
