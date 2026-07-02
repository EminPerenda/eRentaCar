import 'package:flutter/foundation.dart';

class ApiConfig {
  static final String baseUrl = _resolveBaseUrl();
  static const String stripePublishableKey = 'pk_test_51R15iKQeAv5CVrKBNRdp2W0gI6lLWp51wvb3uuO8BHCl6mZeiYILwRnF6xAxWclDYyxdeAt2ogqvRsl00d9W3iTp00c4ay8P62';

  static String _resolveBaseUrl() {
    const envBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:5091';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5091';
      case TargetPlatform.iOS:
        return 'http://localhost:5091';
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://localhost:5091';
    }
  }

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