double? parseNumber(String? value) {
  if (value == null) {
    return null;
  }

  return double.tryParse(value.trim().replaceAll(',', '.'));
}
