import 'package:flutter/material.dart';
import 'package:mobile_kelompok/ui/sidebar/sidebar.dart';
import 'package:mobile_kelompok/services/order_session.dart';
import 'package:mobile_kelompok/ui/tanggal_screen.dart';
import 'package:mobile_kelompok/ui/pembayaran_screen.dart';

class FinalOrderScreen extends StatelessWidget {
  const FinalOrderScreen({super.key});

  String formatRupiah(int angka) {
    return "Rp ${angka.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  String formatTanggal(DateTime? tanggal) {
    if (tanggal == null) return '-';
    final dd = tanggal.day.toString().padLeft(2, '0');
    final mm = tanggal.month.toString().padLeft(2, '0');
    final yyyy = tanggal.year.toString();
    return '$dd-$mm-$yyyy';
  }

  String labelMetodePembayaran(String? metode) {
    switch (metode) {
      case 'online':
        return 'Pembayaran online';
      case 'offline':
        return 'Pembayaran offline';
      default:
        return 'Belum dipilih';
    }
  }

  void buatPesanan(BuildContext context) {
    debugPrint('Items   : ${OrderSession.selectedItems}');
    debugPrint('Tanggal : ${OrderSession.selectedDate}');
    debugPrint('Metode  : ${OrderSession.paymentMethod}');
    debugPrint('Total   : ${OrderSession.totalPembayaran}');
  }

  @override
  Widget build(BuildContext context) {
    final items = OrderSession.selectedItems;
    final subtotal = OrderSession.subtotal;
    final total = OrderSession.totalPembayaran;

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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 15, 24, 15),
                children: [
                  ...items.map((item) => _buildItemCard(item)),

                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Belum ada barang dipilih',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 4),

                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCardHeader(
                          context,
                          title: 'Metode Pembayaran',
                          actionLabel: 'Lihat Semua',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PembayaranScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 18,
                              color: Color(0xFF1E88E5),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              labelMetodePembayaran(OrderSession.paymentMethod),
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCardHeader(
                          context,
                          title: 'Tanggal',
                          actionLabel: 'Pilih Tanggal',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TanggalScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildBarisInfo(
                          'Tanggal reservasi',
                          formatTanggal(OrderSession.selectedDate),
                        ),
                        const SizedBox(height: 4),
                        _buildBarisInfo(
                          'Estimasi selesai pengerjaan',
                          formatTanggal(OrderSession.estimasiSelesai),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rincian Pembayaran',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildBarisInfo(
                          'Subtotal pesanan',
                          formatRupiah(subtotal),
                        ),
                        const SizedBox(height: 8),
                        Divider(color: Colors.grey.shade300, height: 1),
                        const SizedBox(height: 8),
                        _buildBarisInfo(
                          'Total Pembayaran',
                          formatRupiah(total),
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Harga: ${formatRupiah(total)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: items.isEmpty ? null : () => buatPesanan(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Buat pesanan',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final namaBarang = item['nama_barang'] ?? item['nama'] ?? 'Nama Barang';
    final hargaBarang =
        int.tryParse(item['harga']?.toString() ?? '') ??
        int.tryParse(item['harga_barang']?.toString() ?? '') ??
        0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_box, color: Color(0xFF1E88E5), size: 20),
          const SizedBox(width: 10),
          Container(
            width: 100,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: SizedBox(
              height: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    namaBarang,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      formatRupiah(hargaBarang),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildCardHeader(
    BuildContext context, {
    required String title,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        InkWell(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF1E88E5),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: Color(0xFF1E88E5),
              ),
            ],
          ),
        ),
      ],
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
