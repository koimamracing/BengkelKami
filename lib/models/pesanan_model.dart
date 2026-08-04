class Pesanan {
  final int idPesanan;
  final String email;
  final String tanggalReservasi;
  final String tanggalEstimasi;
  final String metodePembayaran;
  final int totalPesanan;
  final String statusPembayaran;
  final String statusPengerjaan;

  Pesanan({
    required this.idPesanan,
    required this.email,
    required this.tanggalReservasi,
    required this.tanggalEstimasi,
    required this.metodePembayaran,
    required this.totalPesanan,
    required this.statusPembayaran,
    required this.statusPengerjaan,
  });

  factory Pesanan.fromJson(Map<String, dynamic> json) {
    return Pesanan(
      idPesanan: int.parse(json["id_pesanan"].toString()),
      email: json["email"] ?? "",
      tanggalReservasi: json["tanggal_reservasi"] ?? "",
      tanggalEstimasi: json["tanggal_estimasi"] ?? "",
      metodePembayaran: json["metode_pembayaran"] ?? "",
      totalPesanan: int.parse(json["total_pesanan"].toString()),
      statusPembayaran: json["status_pembayaran"] ?? "",
      statusPengerjaan: json["status_pengerjaan"] ?? "",
    );
  }
}
