class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.100.100.216:5091',
  );
static const String stripePublishableKey = 'pk_test_51R15iKQeAv5CVrKBNRdp2W0gI6lLWp51wvb3uuO8BHCl6mZeiYILwRnF6xAxWclDYyxdeAt2ogqvRsl00d9W3iTp00c4ay8P62';
  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String logout = '/api/auth/logout';

  // Vehicles
  static const String vehicles = '/api/vehicles';

  // Reservations
  static const String reservations = '/api/reservations';
  static const String myReservations = '/api/reservations/my';

  // Users
  static const String me = '/api/users/me';

  // Notifications
  static const String notifications = '/api/notifications';
  static const String unreadCount = '/api/notifications/unread-count';

  // News
  static const String news = '/api/news';

  // Reference
  static const String categories = '/api/reference/categories';
  static const String brands = '/api/reference/brands';
  static const String fuelTypes = '/api/reference/fueltypes';
  static const String transmissions = '/api/reference/transmissions';
  static const String cities = '/api/reference/cities';
  static const String extraServices = '/api/reference/extraservices';
  static const String locations = '/api/reference/locations';

  // Reviews
  static const String reviews = '/api/reviews';

  // Recommendations
  static const String recommendations = '/api/recommendations';
}