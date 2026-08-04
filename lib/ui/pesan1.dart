import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_kelompok/config/api_config.dart';
import 'package:mobile_kelompok/ui/sidebar/sidebar.dart';
import 'package:mobile_kelompok/ui/tanggal_screen.dart';
import 'package:mobile_kelompok/services/order_session.dart';

class Pesan1Screen extends StatefulWidget {
  final String fromMenu;

  const Pesan1Screen({super.key, required this.fromMenu});

  @override
  State<Pesan1Screen> createState() => _Pesan1ScreenState();
}

class _Pesan1ScreenState extends State<Pesan1Screen> {
  List<dynamic> listBarang = [];
  bool isLoading = true;
  final Map<int, bool> checkedItems = {};
  String? selectedMenu;
  Map<String, String> currentDropdownMap = {};

  @override
  void initState() {
    super.initState();
    setupDropdownItems();
    fetchBarangAwal();
  }

  void setupDropdownItems() {
    currentDropdownMap = {'--- Semua Kategori ---': ''};

    if (widget.fromMenu == 'Ganti Sparepart') {
      currentDropdownMap.addAll({
        'Headlight': 'headlight',
        'Backlight': 'backlight',
        'Kaca Depan': 'kaca_depan',
        'Kaca Samping': 'kaca_samping',
        'Kaca Belakang': 'kaca_belakang',
        'Spion': 'spion',
        'Wiper': 'wiper',
        'Kaca Film': 'kaca_film',
      });
    } else if (widget.fromMenu == 'Cat dan Oli') {
      currentDropdownMap.addAll({'Warna Cat': 'warna_cat', 'Oli': 'oli'});
    } else {
      currentDropdownMap.addAll({
        'Servis Ringan': 'Servis Ringan',
        'Servis Besar': 'Servis Besar',
        'Ganti Oli': 'Ganti Oli',
      });
    }

    selectedMenu = '';
  }

  Future<void> fetchBarangAwal() async {
    setState(() {
      isLoading = true;
    });
    try {
      final urlTarget = Uri.parse(
        '${ApiConfig.barangUrl}?menu=${widget.fromMenu}',
      );
      final response = await http.get(urlTarget);
      if (response.statusCode == 200) {
        processResponse(response.body);
      }
    } catch (e) {
      handleFetchError(e);
    }
  }

  Future<void> fetchBarangByKategori(String? dbValue) async {
    if (dbValue == null || dbValue.isEmpty) {
      await fetchBarangAwal();
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final urlTarget = Uri.parse('${ApiConfig.barangUrl}?kategori=$dbValue');
      final response = await http.get(urlTarget);
      if (response.statusCode == 200) {
        processResponse(response.body);
      }
    } catch (e) {
      handleFetchError(e);
    }
  }

  void processResponse(String responseBody) {
    final data = json.decode(responseBody);
    setState(() {
      listBarang = data is List ? data : (data['data'] ?? []);
      isLoading = false;

      checkedItems.clear();
      for (int i = 0; i < listBarang.length; i++) {
        final id = int.tryParse(listBarang[i]['id'].toString()) ?? i;
        checkedItems[id] = false;
      }
    });
  }

  void handleFetchError(Object e) {
    setState(() {
      isLoading = false;
    });
    debugPrint("Error fetch data: $e");
  }

  int hitungTotal() {
    int total = 0;
    for (int i = 0; i < listBarang.length; i++) {
      final item = listBarang[i];
      final id = int.tryParse(item['id'].toString()) ?? i;
      if (checkedItems[id] == true) {
        final harga =
            int.tryParse(item['harga'].toString()) ??
            int.tryParse(item['harga_barang'].toString()) ??
            0;
        total += harga;
      }
    }
    return total;
  }

  String formatRupiah(int angka) {
    return "Rp ${angka.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  void buatPesanan() {
    final itemsTerpilih = <Map<String, dynamic>>[];

    for (int i = 0; i < listBarang.length; i++) {
      final item = listBarang[i];
      final id = int.tryParse(item['id'].toString()) ?? i;
      if (checkedItems[id] == true) {
        itemsTerpilih.add(Map<String, dynamic>.from(item));
      }
    }

    if (itemsTerpilih.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 barang terlebih dahulu')),
      );
      return;
    }

    OrderSession.selectedItems = itemsTerpilih;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TanggalScreen()),
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
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(
                            Icons.menu,
                            color: Colors.black87,
                            size: 28,
                          ),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
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
                          Container(
                            height: 1,
                            color: Colors.grey.shade300,
                            width: 60,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox.shrink(),
                ],
              ),
            ),
            Container(
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
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedMenu,
                    isExpanded: true,
                    alignment: Alignment.center,
                    items: currentDropdownMap.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.value,
                        child: Center(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedMenu = newValue;
                      });
                      fetchBarangByKategori(newValue);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : listBarang.isEmpty
                  ? const Center(child: Text("Tidak ada data barang"))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: listBarang.length,
                      itemBuilder: (context, index) {
                        final item = listBarang[index];
                        final id = int.tryParse(item['id'].toString()) ?? index;
                        final namaBarang =
                            item['nama_barang'] ??
                            item['nama'] ??
                            'Nama Barang';
                        final hargaBarang =
                            int.tryParse(item['harga'].toString()) ??
                            int.tryParse(item['harga_barang'].toString()) ??
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
                              Checkbox(
                                value: checkedItems[id] ?? false,
                                activeColor: const Color(0xFF1E88E5),
                                onChanged: (bool? value) {
                                  setState(() {
                                    checkedItems[id] = value ?? false;
                                  });
                                },
                              ),
                              const SizedBox(width: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 100,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD9D9D9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  child: Image.network(
                                    "${ApiConfig.baseUrl}/imgbarang/${item["gambar"]}",
                                    width: 100,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: SizedBox(
                                  height: 80,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                      },
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
              'Total Harga: ${formatRupiah(hitungTotal())}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: hitungTotal() == 0 ? null : buatPesanan,
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
}
