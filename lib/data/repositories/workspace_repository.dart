import '../remote/api_client.dart';

class WorkspaceRepository {
  WorkspaceRepository(this.api);
  final ApiClient api;
  Future<Map<String, dynamic>> me() => api.getObject('/admin/auth/me');
  Future<Map<String, dynamic>> profile() => api.getObject('/api/profile');
  Future<void> updateProfile(String name) async =>
      api.sendObject('/api/profile', {'name': name}, method: 'PATCH');
  Future<void> changePassword(
    String current,
    String password,
    String confirm,
  ) async => api.sendObject('/api/password/change', {
    'currentPassword': current,
    'password': password,
    'confirmPassword': confirm,
  });
  Future<List<Map<String, dynamic>>> list(String path) => api.getList(path);
  Future<Map<String, dynamic>> get(String path) => api.getObject(path);
  Future<Map<String, dynamic>> save(
    String path,
    Map<String, dynamic> data, {
    String method = 'POST',
  }) => api.sendObject(path, data, method: method);
  Future<void> remove(String path) => api.delete(path);
}
