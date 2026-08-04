class OrderSession {
  static DateTime? selectedDate;
  static String? paymentMethod;
  static List<Map<String, dynamic>> selectedItems = [];
  static int estimasiHariPengerjaan = 5;

  static int subtotalPengerjaan = 50000;
  static int? idPesanan;
  static String? midtransOrderId;

  static int _ambilHarga(Map<String, dynamic> item) {
    return int.tryParse(item['harga']?.toString() ?? '') ??
        int.tryParse(item['harga_barang']?.toString() ?? '') ??
        0;
  }

  static int get subtotal =>
      selectedItems.fold(0, (sum, item) => sum + _ambilHarga(item));

  static int get totalPembayaran => subtotal + subtotalPengerjaan;

  static DateTime? get estimasiSelesai => selectedDate == null
      ? null
      : selectedDate!.add(Duration(days: estimasiHariPengerjaan));

  static void reset() {
    selectedDate = null;
    paymentMethod = null;
    selectedItems = [];
    idPesanan = null;
    midtransOrderId = null;
  }

  static bool get isComplete =>
      selectedDate != null && paymentMethod != null && selectedItems.isNotEmpty;
}
