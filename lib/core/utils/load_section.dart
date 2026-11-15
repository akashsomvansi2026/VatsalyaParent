Future<List<T>> loadSection<T>(
  bool allowed,
  Future<List<T>> Function() fetch,
  List<String> warnings,
  String label,
) async {
  if (!allowed) return [];
  try {
    return await fetch();
  } catch (e) {
    warnings.add('$label: $e');
    return [];
  }
}
