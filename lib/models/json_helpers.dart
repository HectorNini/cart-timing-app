/// Безопасные преобразования для ответов API.
///
/// Бэкенд может отдавать число строкой (например, `kartNumber: "33"`),
/// поэтому жёсткие `json['x'] as int?` падают на таком ответе целиком.
int? asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

String? asString(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

bool? asBool(Object? value) {
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  if (value is num) return value != 0;
  return null;
}
