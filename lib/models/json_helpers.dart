/// Lenient readers for Realtime Database values, which may be missing or
/// stored with a different type than expected (legacy data).
String jsonString(dynamic v) => v?.toString() ?? '';

int jsonInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
