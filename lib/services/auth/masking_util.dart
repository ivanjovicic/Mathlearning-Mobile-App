class MaskingUtil {
  static String maskSensitive(String input) {
    if (input.length <= 4) return '*' * input.length;
    return '*' * (input.length - 4) + input.substring(input.length - 4);
  }
}