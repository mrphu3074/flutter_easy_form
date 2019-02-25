part of easy_form;

Map<K, V> flattenMap<K, V>(Map<K, V> raw, {String parentKey}) {
  Map output = Map<K, V>();
  raw.forEach((key, value) {
    String keyO = parentKey != null ? "$parentKey.$key" : key;
    if (value is Map) {
      output.addAll(flattenMap(value, parentKey: keyO));
    } else {
      output[keyO] = value;
    }
  });
  return output;
}

Map _buildMapFromPath(Map root, List<String> paths, value) {
  if (paths.length == 1) {
    root.putIfAbsent(paths[0], () => value);
  } else {
    Map nested = root.containsKey(paths[0]) ? root[paths[0]] : Map();
    root[paths[0]] = _buildMapFromPath(nested, paths.getRange(1, paths.length).toList(), value);
  }
  return root;
}

Map<K, V> buildNestedMap<K, V>(Map<K, V> raw) {
  Map<K, V> output = Map<K, V>();
  raw.forEach((key, value) {
    if (key is String) {
      List<String> paths = key.split(".");
      if (paths.length > 1) {
        output = _buildMapFromPath(output, paths, value);
      } else {
        output[key] = value;
      }
    }
  });
  return output;
}

Function _listEquals = DeepCollectionEquality.unordered().equals;

bool deepMapEquals(Map map1, Map map2) {
  /// Comparison Strategies
  // 1: compare Map keys count
  if (map1.keys.length != map2.keys.length) return false;

  // 2: compare key names
  if (!_listEquals(map1.keys, map2.keys)) return false;

  // 3: compare values in root level
  for (String key in map1.keys) {
    var value1 = map1[key];
    var value2 = map2[key];
    if (value1.runtimeType != value2.runtimeType) {
      return false;
    } else if (value1 is List) {
      if (_listEquals(value1, value2))
        continue;
      else
        return false;
    } else if (value1 is Map) {
      return deepMapEquals(value1, value2);
    } else if (value1 != value2) {
      return false;
    }
  }
  return true;
}
