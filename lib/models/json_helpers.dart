/// Lenient readers for Realtime Database values, which may be missing or
/// stored with a different type than expected (legacy data).
String jsonString(dynamic v) => v?.toString() ?? '';

int jsonInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

/// A database node as a JSON map. `firebase_database` returns
/// `Map<Object?, Object?>`, and returns a `List` when a node's keys look like
/// array indices; anything else (including a missing node) is null.
Map<String, dynamic>? asJsonMap(Object? value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  if (value is List) {
    return {
      for (var i = 0; i < value.length; i++)
        if (value[i] != null) '$i': value[i],
    };
  }
  return null;
}

/// The child maps of a database node, e.g. every booking under
/// `appointments/<uid>`. Non-map children are skipped.
Iterable<Map<String, dynamic>> jsonChildren(Object? node) =>
    asJsonMap(node)?.values.map(asJsonMap).whereType<Map<String, dynamic>>() ??
    const [];
