import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../config/api_config.dart';

class PaymentService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> payForReservation({
    required int reservationId,
    required double amount,
  }) async {
    final token = await _storage.read(key: 'token');
    if (token == null || token.isEmpty) {
      throw Exception('Nedostaje autentifikacija. Prijavi se ponovo.');
    }

    final dio = Dio();

    try {
      final response = await dio.post(
        '${ApiConfig.baseUrl}/api/payments/create-payment-intent/$reservationId',
        data: {'amount': amount},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final clientSecret = _extractClientSecret(response.data);

      Stripe.publishableKey = ApiConfig.stripePublishableKey;
      await Stripe.instance.applySettings();

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'eRentaCar',
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.light,
          allowsDelayedPaymentMethods: false,
        ),
      );

      try {
        await Stripe.instance.presentPaymentSheet();
      } on StripeException catch (e) {
        if (e.error.code == FailureCode.Canceled) {
          return false;
        }
        rethrow;
      }

      await _confirmPayment(
        reservationId: reservationId,
        token: token,
        clientSecret: clientSecret,
      );

      return true;
    } on DioException catch (e) {
      throw Exception(_readDioError(e));
    }
  }

  String _extractClientSecret(dynamic data) {
    if (data is Map<String, dynamic>) {
      final value = data['clientSecret'] ?? data['client_secret'];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }

    throw Exception('Server nije vratio Stripe client secret.');
  }

  Future<void> _confirmPayment({
    required int reservationId,
    required String token,
    required String clientSecret,
  }) async {
    final dio = Dio();
    final paymentIntentId = clientSecret.split('_secret_').first;

    await dio.post(
      '${ApiConfig.baseUrl}/api/payments/confirm/$reservationId',
      data: {'paymentIntentId': paymentIntentId},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }

  Future<void> refundReservation({
    required int reservationId,
  }) async {
    final token = await _storage.read(key: 'token');
    if (token == null || token.isEmpty) {
      throw Exception('Nedostaje autentifikacija. Prijavi se ponovo.');
    }

    final dio = Dio();

    try {
      await dio.post(
        '${ApiConfig.baseUrl}/api/payments/refund/$reservationId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      throw Exception(_readDioError(e));
    }
  }

  String _readDioError(DioException e) {
    final responseData = e.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    if (e.message != null && e.message!.isNotEmpty) {
      return e.message!;
    }

    return 'Došlo je do greške. Pokušaj ponovo.';
  }
}