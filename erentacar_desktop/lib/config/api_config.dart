class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5091',
  );

  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String logout = '/api/auth/logout';
  static const String vehicles = '/api/vehicles';
  static const String reservations = '/api/reservations';
  static const String reservationReject = '/api/reservations/{id}/reject';
  static const String reservationActivate = '/api/reservations/{id}/activate';
  static const String myReservations = '/api/reservations/my';
  static const String me = '/api/users/me';
  static const String users = '/api/users';
  static const String notifications = '/api/notifications';
  static const String unreadCount = '/api/notifications/unread-count';
  static const String news = '/api/news';
  static const String categories = '/api/reference/categories';
  static const String brands = '/api/reference/brands';
  static const String fuelTypes = '/api/reference/fueltypes';
  static const String transmissions = '/api/reference/transmissions';
  static const String cities = '/api/reference/cities';
  static const String extraServices = '/api/reference/extraservices';
  static const String extraServicesAdmin = '/api/reference/extraservices/all';
  static const String reports = '/api/reports';
  static const String notificationsAdmin = '/api/notifications/admin';
  static const String notificationsSend = '/api/notifications/send';
  static const String locations = '/api/locations';
  static const String reviews = '/api/reviews';
  static const String recommendations = '/api/recommendations';
  static const String countries = '/api/reference/countries';
}