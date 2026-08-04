import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mobile_kelompok/models/pesanan_model.dart';
import 'package:mobile_kelompok/services/pesanan_services.dart';
import 'package:mobile_kelompok/ui/detail_pesanan_screen.dart';
import 'package:mobile_kelompok/ui/sidebar/sidebar.dart';

class PesananScreen extends StatefulWidget {
  const PesananScreen({super.key});

  @override
  State<PesananScreen> createState() => _PesananScreenState();
}

class _PesananScreenState extends State<PesananScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController tableScrollController = ScrollController();

  List<Pesanan> pesanan = [];
  List<Pesanan> filtered = [];

  bool loading = true;

  static const Color kBlue = Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    tableScrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
    });

    pesanan = await PesananService.getPesanan();

    filtered = pesanan;

    setState(() {
      loading = false;
    });
  }

  void search(String value) {
    setState(() {
      filtered = pesanan.where((e) {
        return e.idPesanan.toString().toLowerCase().contains(
              value.toLowerCase(),
            ) ||
            e.email.toLowerCase().contains(value.toLowerCase());
      }).toList();
    });
  }

  String rupiah(int angka) {
    return NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp ",
      decimalDigits: 0,
    ).format(angka);
  }

  String tanggal(String tgl) {
    try {
      return DateFormat("dd MMMM yyyy", "id_ID").format(DateTime.parse(tgl));
    } catch (e) {
      return tgl;
    }
  }

  Widget statusPembayaran(String status) {
    Color warna = Colors.orange;
    String text = "Pending";

    if (status == "dibayar") {
      warna = Colors.green;
      text = "Dibayar";
    }

    return Text(
      text,
      style: TextStyle(color: warna, fontWeight: FontWeight.bold, fontSize: 12),
    );
  }

  Widget statusPengerjaan(String status) {
    Color warna = Colors.red;
    String text = "Belum Dikerjakan";

    if (status == "sedang_dikerjakan") {
      warna = Colors.orange;
      text = "Sedang Dikerjakan";
    }

    if (status == "selesai") {
      warna = Colors.green;
      text = "Selesai";
    }

    return Text(
      text,
      style: TextStyle(color: warna, fontWeight: FontWeight.bold, fontSize: 12),
    );
  }

  Widget headerCell(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: Colors.white,
      ),
    );
  }

  DataRow buildRow(Pesanan item, int index) {
    return DataRow(
      color: MaterialStateProperty.all(Colors.white),
      cells: [
        DataCell(Text(item.idPesanan.toString())),
        DataCell(Text(item.email.isEmpty ? "-" : item.email)),
        DataCell(Text(tanggal(item.tanggalReservasi))),
        DataCell(Text(tanggal(item.tanggalEstimasi))),
        DataCell(Text(item.metodePembayaran.toUpperCase())),
        DataCell(Text(rupiah(item.totalPesanan))),
        DataCell(statusPembayaran(item.statusPembayaran)),
        DataCell(statusPengerjaan(item.statusPengerjaan)),
        DataCell(
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DetailPesananScreen(idPesanan: item.idPesanan),
                ),
              );
            },
            child: const Text("Detail", style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget buildTable(BoxConstraints constraints) {
    return Scrollbar(
      controller: tableScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      interactive: true,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          controller: tableScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 14),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(kBlue),
                dataRowColor: MaterialStateProperty.all(Colors.white),
                columns: [
                  DataColumn(label: headerCell("No Pesanan")),
                  DataColumn(label: headerCell("Email")),
                  DataColumn(label: headerCell("Tgl Reservasi")),
                  DataColumn(label: headerCell("Tgl Estimasi")),
                  DataColumn(label: headerCell("Metode")),
                  DataColumn(label: headerCell("Total Harga")),
                  DataColumn(label: headerCell("Status Bayar")),
                  DataColumn(label: headerCell("Status Kerja")),
                  DataColumn(label: headerCell("Aksi")),
                ],
                rows: [
                  for (int i = 0; i < filtered.length; i++)
                    buildRow(filtered[i], i),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7E5EC),
      drawer: const SidebarWidget(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.black87,
                        size: 26,
                      ),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Image.asset(
                    'assets/images/logo.png',
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          const Text(
                            "Kelola Pesanan",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            bottom: 0,
                            child: Container(
                              height: 2,
                              width: 130,
                              color: kBlue,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              onChanged: search,
                              decoration: InputDecoration(
                                hintText: "Cari nomor pesanan / email",
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => search(searchController.text),
                            child: const Text("Cari"),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: Text("Tidak ada data pesanan")),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) =>
                              buildTable(constraints),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
