/// Small collection helpers.
T? firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}

/// Replaces the element matched by [test]; returns an updated copy.
List<T> replaceWhere<T>(List<T> items, bool Function(T) test, T replacement) {
  final index = items.indexWhere(test);
  if (index < 0) return items;
  final copy = [...items];
  copy[index] = replacement;
  return copy;
}
