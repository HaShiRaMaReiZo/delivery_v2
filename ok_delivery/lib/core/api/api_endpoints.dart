class ApiEndpoints {
  static const String baseUrl = 'https://ok-delivery-service.onrender.com';

  // Auth
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/user';

  // Merchant
  static const String merchantPackages = '/api/merchant/packages';
  static const String merchantPackagesBulk = '/api/merchant/packages/bulk';
  static String merchantPackage(int id) => '/api/merchant/packages/$id';
  static const String merchantDashboard = '/api/merchant/dashboard';

  // Draft
  static const String merchantDrafts = '/api/merchant/packages/draft';
  static const String merchantDraftsSubmit =
      '/api/merchant/packages/draft/submit';
  static String merchantDraftUpdate(int id) =>
      '/api/merchant/packages/draft/$id';
  static String merchantDraftDelete(int id) =>
      '/api/merchant/packages/draft/$id';

  // Tracking
  static String merchantPackageLiveLocation(int id) =>
      '/api/merchant/packages/$id/live-location';

  // Socket.io (JavaScript Location Tracker server)
  static const String websocketBaseUrl =
      'https://location-tracker-js.onrender.com';
}
