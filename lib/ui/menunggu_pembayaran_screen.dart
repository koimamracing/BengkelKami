import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_kelompok/config/api_config.dart';
import 'package:mobile_kelompok/services/order_session.dart';
import 'package:mobile_kelompok/ui/sidebar/sidebar.dart';
import 'package:mobile_kelompok/ui/pembayaran_selesai_screen.dart';

class MenungguPembayaranScreen extends StatefulWidget {
  final int idPesanan;

  const MenungguPembayaranScreen({super.key, required this.idPesanan});

  @override
  State<MenungguPembayaranScreen> createState() =>
      _MenungguPembayaranScreenState();
}

class _MenungguPembayaranScreenState extends State<MenungguPembayaranScreen> {
  bool isProsesBayar = false;
  Timer? pollingTimer;

  String formatRupiah(int angka) {
    return "Rp ${angka.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  @override
  void dispose() {
    pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> mulaiBayar() async {
    if (OrderSession.paymentMethod == 'offline') {
      await bayarOffline();
    } else {
      await bayarOnline();
    }
  }

  Future<void> bayarOffline() async {
    setState(() => isProsesBayar = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.pesananUrl}/${widget.idPesanan}/bayar'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      if (data['status'] != true) {
        throw Exception(data['message'] ?? 'Gagal konfirmasi pesanan');
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const PembayaranSelesaiScreen(judul: 'Silakan membayar di kasir'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memproses pesanan: $e')));
    } finally {
      if (mounted) setState(() => isProsesBayar = false);
    }
  }

  Future<void> bayarOnline() async {
    setState(() => isProsesBayar = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.midtransChargeUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id_pesanan': widget.idPesanan}),
      );

      final data = json.decode(response.body);

      if (data['status'] != true) {
        throw Exception(data['message'] ?? 'Gagal membuat transaksi');
      }

      final qrImageUrl = data['data']['qr_image_url'] as String?;
      final qrImageUrlMidtrans =
          data['data']['qr_image_url_midtrans'] as String?;
      final orderIdMidtrans = data['data']['order_id_midtrans'] as String;
      final simulatorUrl = data['data']['simulator_url'] as String;

      if (qrImageUrl == null) {
        throw Exception('QR code gagal diambil dari Midtrans, coba lagi');
      }

      OrderSession.midtransOrderId = orderIdMidtrans;

      if (!mounted) return;
      tampilkanPopupQr(
        qrImageUrl,
        qrImageUrlMidtrans,
        orderIdMidtrans,
        simulatorUrl,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memulai pembayaran: $e')));
    } finally {
      if (mounted) setState(() => isProsesBayar = false);
    }
  }

  void salinKeClipboard(String teks, String label) {
    Clipboard.setData(ClipboardData(text: teks));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label disalin ke clipboard'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void tampilkanPopupQr(
    String qrImageUrl,
    String? qrImageUrlMidtrans,
    String orderIdMidtrans,
    String simulatorUrl,
  ) {
    mulaiPolling(orderIdMidtrans);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Scan QR untuk Bayar',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  qrImageUrl,
                  width: 220,
                  height: 220,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      width: 220,
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(child: Text('QR gagal dimuat')),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sedang menunggu pembayaran...',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mode development',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Buka link simulator ini di browser:',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      _buildLinkBaris(simulatorUrl, 'Link simulator'),

                      if (qrImageUrlMidtrans != null) ...[
                        const SizedBox(height: 10),
                        const Text(
                          '2. Atau tempel ke kolom "QR Code Image Url" di simulator:',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        _buildLinkBaris(qrImageUrlMidtrans, 'Link QR image'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                pollingTimer?.cancel();
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLinkBaris(String url, String label) {
    return Row(
      children: [
        Expanded(
          child: SelectableText(
            url,
            style: const TextStyle(fontSize: 10, color: Color(0xFF1E88E5)),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 16, color: Color(0xFF1E88E5)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => salinKeClipboard(url, label),
        ),
      ],
    );
  }

  void mulaiPolling(String orderIdMidtrans) {
    pollingTimer?.cancel();
    pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final response = await http.get(
          Uri.parse(ApiConfig.midtransStatusUrl(orderIdMidtrans)),
        );
        final data = json.decode(response.body);
        final isPaid = data['data']?['is_paid'] == true;

        if (isPaid) {
          timer.cancel();
          if (!mounted) return;
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PembayaranSelesaiScreen(),
            ),
          );
        }
      } catch (e) {
        debugPrint('Gagal cek status pembayaran: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final subtotalPesanan = OrderSession.subtotal;
    final subtotalPengerjaan = OrderSession.subtotalPengerjaan;
    final total = OrderSession.totalPembayaran;
    final isOffline = OrderSession.paymentMethod == 'offline';

    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      drawer: const SidebarWidget(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
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
                        const Center(
                          child: Text(
                            'Menunggu Pembayaran',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildBarisInfo(
                          'Subtotal pesanan',
                          formatRupiah(subtotalPesanan),
                        ),
                        const SizedBox(height: 6),
                        _buildBarisInfo(
                          'Subtotal pengerjaan',
                          formatRupiah(subtotalPengerjaan),
                        ),
                        const SizedBox(height: 10),
                        Divider(color: Colors.grey.shade300, height: 1),
                        const SizedBox(height: 10),
                        _buildBarisInfo(
                          'Total Pembayaran',
                          formatRupiah(total),
                          bold: true,
                        ),
                        if (isOffline) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Pembayaran dilakukan langsung di kasir bengkel',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isProsesBayar ? null : mulaiBayar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                              disabledBackgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: isProsesBayar
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Bayar',
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

  Widget _buildBarisInfo(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: bold ? Colors.black87 : Colors.black54,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
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
}
