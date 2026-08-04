import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:mobile_kelompok/config/api_config.dart';

class DetailPesananScreen extends StatefulWidget {
  final int idPesanan;

  const DetailPesananScreen({super.key, required this.idPesanan});

  @override
  State<DetailPesananScreen> createState() => _DetailPesananScreenState();
}

class _DetailPesananScreenState extends State<DetailPesananScreen> {
  bool loading = true;

  Map<String, dynamic>? data;

  List items = [];

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.pesananUrl}/${widget.idPesanan}"),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      if (json["status"] == true) {
        data = json["data"];
        items = data!["items"];
      }
    }

    setState(() {
      loading = false;
    });
  }

  String rupiah(dynamic angka) {
    return NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp ",
      decimalDigits: 0,
    ).format(int.parse(angka.toString()));
  }

  String tanggal(String value) {
    try {
      return DateFormat(
        "EEEE, dd MMMM yyyy",
        "id_ID",
      ).format(DateTime.parse(value));
    } catch (e) {
      return value;
    }
  }

  Color statusColor(String text) {
    if (text == "dibayar" || text == "selesai") return Colors.green;
    if (text == "sedang_dikerjakan") return Colors.orange;
    if (text == "belum_dikerjakan") return Colors.red;
    return Colors.orange;
  }

  String statusLabel(String text) {
    switch (text) {
      case "dibayar":
        return "Dibayar";
      case "menunggu_pembayaran":
        return "Pending";
      case "selesai":
        return "Selesai";
      case "sedang_dikerjakan":
        return "Sedang Dikerjakan";
      case "belum_dikerjakan":
        return "Belum Dikerjakan";
      default:
        return text.replaceAll("_", " ");
    }
  }

  Widget infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.black),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight: valueColor != null
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1F7),
      appBar: AppBar(
        title: const Text("Detail Pesanan"),
        backgroundColor: const Color(0xFF3C3C3C),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7E5EC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Detail Pengguna",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        infoRow("Email", data!["email"]?.toString() ?? "-"),
                        infoRow("Total Barang", items.length.toString()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pesanan #${data!["id_pesanan"]}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),

                        infoRow(
                          "Tanggal Reservasi",
                          tanggal(data!["tanggal_reservasi"]),
                        ),
                        infoRow(
                          "Tanggal Estimasi",
                          tanggal(data!["tanggal_estimasi"]),
                        ),
                        infoRow(
                          "Status Pembayaran",
                          statusLabel(data!["status_pembayaran"]),
                          valueColor: statusColor(data!["status_pembayaran"]),
                        ),
                        infoRow(
                          "Status Pengerjaan",
                          statusLabel(data!["status_pengerjaan"]),
                          valueColor: statusColor(data!["status_pengerjaan"]),
                        ),

                        const Divider(height: 24),

                        const Text(
                          "Barang Pesanan",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Column(
                            children: [
                              Container(
                                color: const Color(0xFF2196F3),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: const Row(
                                  children: [
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        "Gambar",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        "Nama Barang",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "Harga",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...items.map(
                                (item) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Image.network(
                                            "${ApiConfig.baseUrl}/imgbarang/${item["gambar"]}",
                                            width: 44,
                                            height: 44,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                  width: 44,
                                                  height: 44,
                                                  color: Colors.grey.shade300,
                                                  child: const Icon(
                                                    Icons.image,
                                                    size: 18,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          item["nama_barang"],
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Text(
                                        rupiah(item["harga_pesanan"]),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          "Total Harga Barang: ${rupiah(data!["subtotal_barang"])}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Harga Pemasangan: ${rupiah(data!["subtotal_pengerjaan"])}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Total Harga:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          rupiah(data!["total_pesanan"]),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Kembali ke Riwayat Pesanan"),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
