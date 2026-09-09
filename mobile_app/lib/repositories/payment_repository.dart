import '../models/api/api_models.dart';
import '../models/api/api_response.dart';
import '../services/api_client.dart';

class PaymentRepository {
  final ApiClient _client;

  PaymentRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  /// Retrieves payment details and authoritative amount for a gig.
  Future<PaymentDto> getGigPayment(String gigId) async {
    final response = await _client.get('/gigs/$gigId/payment');

    final apiResponse = ApiResponse<PaymentDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => PaymentDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// Customer executes payment using CASH or UPI.
  Future<PaymentDto> recordPayment({
    required String gigId,
    required String paymentMethod, // 'CASH' or 'UPI'
  }) async {
    final response = await _client.post(
      '/gigs/$gigId/payment',
      data: PaymentCreateRequestDto(
        paymentMethod: paymentMethod.toUpperCase(),
      ).toJson(),
    );

    final apiResponse = ApiResponse<PaymentDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => PaymentDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// Worker confirms receipt of payment, transitioning gig to fully COMPLETED.
  Future<PaymentDto> confirmPaymentReceipt(String gigId) async {
    final response = await _client.post(
      '/gigs/$gigId/payment/confirm-receipt',
      data: const PaymentReceiptConfirmRequestDto().toJson(),
    );

    final apiResponse = ApiResponse<PaymentDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => PaymentDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }
}
