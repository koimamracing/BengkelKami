import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_kelompok/config/api_config.dart';
import 'package:mobile_kelompok/ui/sidebar/sidebar.dart';
import 'package:mobile_kelompok/services/order_session.dart';
import 'package:mobile_kelompok/ui/menunggu_pembayaran_screen.dart';
import 'package:mobile_kelompok/services/auth_session.dart';

class PembayaranScreen extends StatefulWidget {
  const PembayaranScreen({super.key});

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  String? metodeTerpilih;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    metodeTerpilih = OrderSession.paymentMethod;
  }

  String _formatTanggalApi(DateTime tanggal) {
    final mm = tanggal.month.toString().padLeft(2, '0');
    final dd = tanggal.day.toString().padLeft(2, '0');
    return '${tanggal.year}-$mm-$dd';
  }

  Future<void> submitPembayaran() async {
    if (metodeTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih metode pembayaran')),
      );
      return;
    }

    if (OrderSession.selectedDate == null ||
        OrderSession.selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi tanggal dan barang terlebih dahulu'),
        ),
      );
      return;
    }

    if (!AuthSession.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi login habis, silakan login ulang')),
      );
      return;
    }

    OrderSession.paymentMethod = metodeTerpilih;

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.pesananUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_pemesan': AuthSession.id,
          'tanggal_reservasi': _formatTanggalApi(OrderSession.selectedDate!),
          'tanggal_estimasi': _formatTanggalApi(OrderSession.estimasiSelesai!),
          'metode_pembayaran': metodeTerpilih,
          'subtotal_pengerjaan': OrderSession.subtotalPengerjaan,
          'items': OrderSession.selectedItems
              .map((item) => {'id_barang': item['id_barang'] ?? item['id']})
              .toList(),
        }),
      );

      final data = json.decode(response.body);

      if (data['status'] != true) {
        throw Exception(data['message'] ?? 'Gagal membuat pesanan');
      }

      OrderSession.idPesanan = data['data']['id_pesanan'];

      if (OrderSession.idPesanan == null) {
        throw Exception(
          'Response API tidak berisi id_pesanan. Balikan server: ${response.body}',
        );
      }

      debugPrint('Pesanan dibuat, id_pesanan: ${OrderSession.idPesanan}');

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MenungguPembayaranScreen(idPesanan: OrderSession.idPesanan!),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuat pesanan: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildOpsi(String label, String value) {
    final terpilih = metodeTerpilih == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          metodeTerpilih = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: terpilih ? const Color(0xFF1E88E5) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/images/dollar.png',
              width: 20,
              height: 20,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.attach_money,
                size: 20,
                color: Colors.black54,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      drawer: const SidebarWidget(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            _buildKembali(context),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Metode Pembayaran',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildOpsi('Pembayaran online', 'online'),
                        _buildOpsi('Pembayaran offline', 'offline'),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : submitPembayaran,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                              disabledBackgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'OK',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87, size: 28),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BENGKEL KITA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
              const Text(
                'BENGKEL OTOMOTIF',
                style: TextStyle(
                  fontSize: 6,
                  color: Colors.black54,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Container(height: 1, color: Colors.grey.shade300, width: 60),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKembali(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE5E5E5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: () => Navigator.pop(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.arrow_back, size: 18, color: Colors.black87),
            SizedBox(width: 8),
            Text(
              'Kembali',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
