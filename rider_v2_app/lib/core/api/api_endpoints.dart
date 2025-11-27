class ApiEndpoints {
  static const String baseUrl = 'https://ok-delivery.onrender.com';

  // Auth
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/user';

  // Rider Packages
  static const String riderPackages = '/api/rider/packages';
  static String riderPackage(int id) => '/api/rider/packages/$id';
  static String riderStatus(int id) => '/api/rider/packages/$id/status';
  static String riderReceiveFromOffice(int id) =>
      '/api/rider/packages/$id/receive-from-office';
  static String riderStart(int id) => '/api/rider/packages/$id/start-delivery';
  static String riderContact(int id) =>
      '/api/rider/packages/$id/contact-customer';
  static String riderProof(int id) => '/api/rider/packages/$id/proof';
  static String riderCod(int id) => '/api/rider/packages/$id/cod';
  static String riderConfirmPickup(int merchantId) =>
      '/api/rider/merchants/$merchantId/confirm-pickup';

  // Location
  static const String riderLocation = '/api/rider/location';
}
