class EmailValidator {
  const EmailValidator._();

  static final _pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static bool isValid(String value) {
    return _pattern.hasMatch(value.trim());
  }
}
