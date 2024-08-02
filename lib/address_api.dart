import 'package:http/http.dart' as http;
import 'dart:convert';

class APIHelper {
  static const String baseUrl = 'https://kodpocztowy.intami.pl/api';

  static Future<Map<String, dynamic>> fetchAddressData(String postalCode) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$postalCode'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data.isNotEmpty) {
          return data[0];
        }
      }
    } catch (e) {
      print('Error fetching address data: $e');
    }
    return {};
  }
}