import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:mobile_kelompok/config/api_config.dart';
import 'package:mobile_kelompok/models/pesanan_model.dart';
import 'auth_session.dart';

class PesananService {
  static Future<List<Pesanan>> getPesanan() async {
    final url = Uri.parse(
      "${ApiConfig.pesananUrl}?id_pemesan=${AuthSession.id}",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      if (json["status"] == true) {
        List list = json["data"];

        return list.map((e) => Pesanan.fromJson(e)).toList();
      }
    }

    return [];
  }
}
