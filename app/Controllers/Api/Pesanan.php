<?php

namespace App\Controllers\Api;

use App\Controllers\BaseController;
use App\Models\PesananModel;
use App\Models\DetailPesananModel;
use App\Models\BarangModel;

class Pesanan extends BaseController
{

    public function store()
    {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token, Authorization');
        header('Access-Control-Allow-Methods: POST, OPTIONS');

        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            exit(0);
        }

        $input = $this->request->getJSON(true);

        $idPemesan          = $input['id_pemesan'] ?? null;
        $tanggalReservasi   = $input['tanggal_reservasi'] ?? null;
        $tanggalEstimasi    = $input['tanggal_estimasi'] ?? null;
        $metodePembayaran   = $input['metode_pembayaran'] ?? null;
        $subtotalPengerjaan = (int) ($input['subtotal_pengerjaan'] ?? 0);
        $items              = $input['items'] ?? [];

        if (!$idPemesan || !$tanggalReservasi || !$tanggalEstimasi || !$metodePembayaran) {
            return $this->response->setJSON([
                'status'  => false,
                'message' => 'id_pemesan, tanggal_reservasi, tanggal_estimasi, dan metode_pembayaran wajib diisi',
            ]);
        }

        if (!in_array($metodePembayaran, ['online', 'offline'])) {
            return $this->response->setJSON([
                'status'  => false,
                'message' => 'metode_pembayaran harus online atau offline',
            ]);
        }

        if (empty($items)) {
            return $this->response->setJSON([
                'status'  => false,
                'message' => 'Minimal harus ada 1 barang yang dipesan',
            ]);
        }

        $barangModel  = new BarangModel();
        $pesananModel = new PesananModel();
        $detailModel  = new DetailPesananModel();

        $idBarangList = array_column($items, 'id_barang');
        $barangDb = $barangModel->whereIn('id_barang', $idBarangList)->findAll();

        if (count($barangDb) !== count($idBarangList)) {
            return $this->response->setJSON([
                'status'  => false,
                'message' => 'Ada id_barang yang tidak ditemukan',
            ]);
        }

        $petaHarga = [];
        foreach ($barangDb as $b) {
            $petaHarga[$b['id_barang']] = (int) $b['harga_barang'];
        }

        $subtotalBarang = 0;
        foreach ($idBarangList as $idBarang) {
            $subtotalBarang += $petaHarga[$idBarang];
        }

        $totalPesanan = $subtotalBarang + $subtotalPengerjaan;

        $db = \Config\Database::connect();
        $db->transStart();

        $idPesanan = $pesananModel->insert([
            'tanggal_reservasi'   => $tanggalReservasi,
            'tanggal_estimasi'    => $tanggalEstimasi,
            'metode_pembayaran'   => $metodePembayaran,
            'subtotal_barang'     => $subtotalBarang,
            'subtotal_pengerjaan' => $subtotalPengerjaan,
            'total_pesanan'       => $totalPesanan,
            'status_pembayaran'   => 'menunggu_pembayaran',
            'status_pengerjaan'   => 'belum_dikerjakan',
            'id_pemesan'          => $idPemesan,
        ]);

        foreach ($idBarangList as $idBarang) {
            $detailModel->insert([
                'id_pesanan'    => $idPesanan,
                'id_barang'     => $idBarang,
                'harga_pesanan' => $petaHarga[$idBarang],
            ]);
        }

        $db->transComplete();

        if ($db->transStatus() === false) {
            return $this->response->setJSON([
                'status'  => false,
                'message' => 'Gagal menyimpan pesanan, silakan coba lagi',
            ]);
        }

        return $this->response->setJSON([
            'status'  => true,
            'message' => 'Pesanan berhasil dibuat',
            'data'    => [
                'id_pesanan'          => $idPesanan,
                'subtotal_barang'     => $subtotalBarang,
                'subtotal_pengerjaan' => $subtotalPengerjaan,
                'total_pesanan'       => $totalPesanan,
            ],
        ]);
    }

    public function index()
    {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token, Authorization');
        header('Access-Control-Allow-Methods: GET, OPTIONS');

        $idPemesan = $this->request->getGet('id_pemesan');

        if (!$idPemesan) {
            return $this->response->setJSON([
                'status'  => false,
                'message' => 'id_pemesan wajib diisi',
            ]);
        }

        $pesananModel = new PesananModel();
        $pesanan = $pesananModel->where('id_pemesan', $idPemesan)->findAll();

        return $this->response->setJSON([
            'status'  => true,
            'message' => 'Berhasil mengambil data pesanan',
            'data'    => $pesanan,
        ]);
    }

    public function show($id = null)
    {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token, Authorization');
        header('Access-Control-Allow-Methods: GET, OPTIONS');

        $pesananModel = new PesananModel();
        $pesanan = $pesananModel->find($id);

        if (!$pesanan) {
            return $this->response->setJSON([
                'status'  => false,
                'message' => 'Pesanan tidak ditemukan',
            ]);
        }

        $db = \Config\Database::connect();
        $items = $db->table('detail_pesanan dp')
            ->select('dp.id_detail, dp.id_barang, dp.harga_pesanan, b.nama_barang, b.gambar, b.kategori')
            ->join('barang b', 'b.id_barang = dp.id_barang')
            ->where('dp.id_pesanan', $id)
            ->get()
            ->getResultArray();

        $pesanan['items'] = $items;

        return $this->response->setJSON([
            'status'  => true,
            'message' => 'Berhasil mengambil detail pesanan',
            'data'    => $pesanan,
        ]);
    }

    public function bayar($id = null)
    {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token, Authorization');
        header('Access-Control-Allow-Methods: POST, OPTIONS');

        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            exit(0);
        }

        $pesananModel = new PesananModel();
        $pesanan = $pesananModel->find($id);

        if (!$pesanan) {
            return $this->response->setJSON([
                'status'  => false,
                'message' => 'Pesanan tidak ditemukan',
            ]);
        }

        if ($pesanan['status_pembayaran'] === 'dibayar') {
            return $this->response->setJSON([
                'status'  => false,
                'message' => 'Pesanan ini sudah dibayar sebelumnya',
            ]);
        }

        $pesananModel->update($id, [
            'status_pembayaran' => 'dibayar',
        ]);

        return $this->response->setJSON([
            'status'  => true,
            'message' => 'Pembayaran berhasil dikonfirmasi',
            'data'    => [
                'id_pesanan'        => $id,
                'status_pembayaran' => 'dibayar',
            ],
        ]);
    }
}