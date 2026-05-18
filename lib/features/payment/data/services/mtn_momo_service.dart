import 'dart:convert';
import 'package:http/http.dart' as http;

/// MTN Mobile Money Collections API
/// Docs: https://momodeveloper.mtn.com/docs/services/collection
class MtnMomoService {
  static const String _sandboxBase = 'https://sandbox.momodeveloper.mtn.com';
  static const String _productionBase = 'https://proxy.momoapi.mtn.com';

  final String subscriptionKey;
  final String apiUserId;
  final String apiKey;
  final String targetEnvironment;

  MtnMomoService({
    required this.subscriptionKey,
    required this.apiUserId,
    required this.apiKey,
    required this.targetEnvironment,
  });

  String get _base =>
      targetEnvironment == 'sandbox' ? _sandboxBase : _productionBase;

  Future<String?> _getAccessToken() async {
    final credentials = base64Encode(utf8.encode('$apiUserId:$apiKey'));
    try {
      final response = await http.post(
        Uri.parse('$_base/collection/token/'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Ocp-Apim-Subscription-Key': subscriptionKey,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['access_token'] as String?;
      }
    } catch (_) {}
    return null;
  }

  /// Initiate a payment request. Returns true if the request was accepted (202).
  Future<({bool success, String? error})> requestToPay({
    required String referenceId,
    required String customerPhone,
    required double amount,
    String? payerMessage,
    String? payeeNote,
  }) async {
    final token = await _getAccessToken();
    if (token == null) {
      return (success: false, error: 'Impossible d\'obtenir le token MTN');
    }

    // Format phone: ensure it starts with country code (237 for Cameroon)
    final msisdn = _formatPhone(customerPhone);

    try {
      final response = await http.post(
        Uri.parse('$_base/collection/v1_0/requesttopay'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Reference-Id': referenceId,
          'X-Target-Environment': targetEnvironment,
          'Ocp-Apim-Subscription-Key': subscriptionKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount.round().toString(),
          'currency': targetEnvironment == 'sandbox' ? 'EUR' : 'XAF',
          'externalId': referenceId,
          'payer': {
            'partyIdType': 'MSISDN',
            'partyId': msisdn,
          },
          'payerMessage': payerMessage ?? 'Paiement Gestock+',
          'payeeNote': payeeNote ?? 'Vente POS',
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 202) {
        return (success: true, error: null);
      }
      return (
        success: false,
        error: 'Erreur MTN ${response.statusCode}: ${response.body}'
      );
    } catch (e) {
      return (success: false, error: 'Réseau indisponible: $e');
    }
  }

  /// Poll the payment status. Returns 'SUCCESSFUL', 'PENDING', 'FAILED'
  Future<({String status, String? financialTxId, String? error})> getPaymentStatus(
      String referenceId) async {
    final token = await _getAccessToken();
    if (token == null) return (status: 'UNKNOWN', financialTxId: null, error: 'Token error');

    try {
      final response = await http.get(
        Uri.parse('$_base/collection/v1_0/requesttopay/$referenceId'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Target-Environment': targetEnvironment,
          'Ocp-Apim-Subscription-Key': subscriptionKey,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return (
          status: (body['status'] as String?)?.toUpperCase() ?? 'UNKNOWN',
          financialTxId: body['financialTransactionId'] as String?,
          error: null,
        );
      }
      return (status: 'UNKNOWN', financialTxId: null, error: 'HTTP ${response.statusCode}');
    } catch (e) {
      return (status: 'UNKNOWN', financialTxId: null, error: e.toString());
    }
  }

  static String _formatPhone(String phone) {
    // Remove spaces, dashes, parentheses
    var clean = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    // If starts with 237, keep as is; if starts with 6/2, prepend 237
    if (clean.startsWith('237')) return clean;
    return '237$clean';
  }

  bool get isConfigured =>
      subscriptionKey.isNotEmpty && apiUserId.isNotEmpty && apiKey.isNotEmpty;
}
