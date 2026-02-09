class ApiEndpoints {
  // TODO: set from env/config
  static const String baseUrl = 'https://ok-delivery-service.onrender.com';

  // Auth
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/user';

  // Merchant
  static const String merchantPackages = '/api/merchant/packages';
  static const String merchantPackagesBulk = '/api/merchant/packages/bulk';
  static String merchantPackage(int id) => '/api/merchant/packages/$id';
  static String merchantTrack(int id) => '/api/merchant/packages/$id/track';
  static String merchantLiveLocation(int id) =>
      '/api/merchant/packages/$id/live-location';
  static String merchantHistory(int id) => '/api/merchant/packages/$id/history';
}
