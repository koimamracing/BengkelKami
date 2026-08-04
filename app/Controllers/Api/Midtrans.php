<?php

namespace App\Controllers\Api;

use App\Controllers\BaseController;
use App\Models\PesananModel;

class Midtrans extends BaseController
{
    private string $serverKey = 'Key kalian';
    private string $baseUrl = 'url midtrans';

    private function authHeader(): string
    {
        return 'Basic ' . base64_encode($this->serverKey . ':');
    }

    private function corsHeaders(string $methods): void
    {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token, Authorization');
        header("Access-Control-Allow-Methods: {$methods}, OPTIONS");
    }

    /**
     * POST /api/midtrans/charge
     * body: { "id_pesanan": 12 }
     *
     * Bikin transaksi QRIS baru di Midtrans buat pesanan yang udah ada di DB,
     * lalu balikin URL gambar QR yang bisa langsung ditampilkan/dipakai.
     */
    public function charge()
    {
        $this->corsHeaders('POST');
        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            exit(0);
        }

        $input     = $this->request->getJSON(true);
        $idPesanan = $input['id_pesanan'] ?? null;

        if (!$idPesanan) {
            return $this->response->setJSON([
                'status'  => false,
                'message' => 'id_pesanan wajib diisi',
            ]);
        }

        $pesananModel = new PesananModel();
        $pesanan      = $pesananModel->find($idPesanan);

        if (!$pesanan) {
            return $this->response->setJSON([
                'status'  => false,
                'message' => 'Pesanan tidak ditemukan',
            ]);
        }

        $orderIdMidtrans = 'PESANAN-' . $idPesanan . '-' . time();
        $grossAmount     = (int) $pesanan['total_pesanan'];

        $payload = [
            'payment_type'         => 'qris',
            'transaction_details'  => [
                'order_id'     => $orderIdMidtrans,
                'gross_amount' => $grossAmount,
            ],
        ];

        $ch = curl_init($this->baseUrl . '/charge');
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => json_encode($payload),
            CURLOPT_HTTPHEADER     => [
                'Accept: application/json',
                'Content-Type: application/json',
                'Authorization: ' . $this->authHeader(),
            ],
        ]);
        $result   = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        $midtransResponse = json_decode($result, true);

        if ($httpCode >= 400 || !isset($midtransResponse['transaction_id'])) {
            return $this->response->setJSON([
                'status'  => false,
                'message' => $midtransResponse['status_message'] ?? 'Gagal membuat transaksi Midtrans',
                'raw'     => $midtransResponse,
            ]);
        }

        $qrUrl = null;
        foreach ($midtransResponse['actions'] ?? [] as $action) {
            if ($action['name'] === 'generate-qr-code') {
                $qrUrl = $action['url'];
                break;
            }
        }

        $pesananModel->update($idPesanan, [
            'midtrans_order_id' => $orderIdMidtrans,
            'status_pembayaran' => 'menunggu_pembayaran',
        ]);

        $host = $this->request->getServer('HTTP_HOST') ?? 'localhost:8080';
        $qrImageUrl = 'http://' . $host . '/api/midtrans/qr-image/' . $midtransResponse['transaction_id'];

        return $this->response->setJSON([
            'status'  => true,
            'message' => 'Transaksi berhasil dibuat',
            'data'    => [
                'order_id_midtrans'      => $orderIdMidtrans,
                'transaction_id'         => $midtransResponse['transaction_id'],
                'qr_image_url'           => $qrImageUrl,
                'qr_image_url_midtrans'  => $qrUrl,
                'gross_amount'           => $grossAmount,
                'simulator_url'          => 'https://simulator.sandbox.midtrans.com/qris/index?id=' . $midtransResponse['transaction_id'],
            ],
        ]);
    }

    public function qrImage($transactionId = null)
    {
        if (!$transactionId) {
            return $this->response->setStatusCode(400)->setBody('transaction_id wajib diisi');
        }

        $url = $this->baseUrl . '/qris/' . $transactionId . '/qr-code';

        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER     => [
                'Authorization: ' . $this->authHeader(),
            ],
        ]);
        $imageData = curl_exec($ch);
        $httpCode  = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError = curl_error($ch);
        curl_close($ch);

        header('Access-Control-Allow-Origin: *');

        if ($httpCode !== 200 || $imageData === false) {
            return $this->response->setStatusCode(404)->setJSON([
                'status'      => false,
                'message'     => 'Gagal ambil QR dari Midtrans',
                'url_dicoba'  => $url,
                'http_code'   => $httpCode,
                'curl_error'  => $curlError,
                'raw_body'    => $imageData !== false ? substr($imageData, 0, 500) : null,
            ]);
        }

        return $this->response
            ->setContentType('image/png')
            ->setBody($imageData);
    }

    public function status($orderIdMidtrans = null)
    {
        $this->corsHeaders('GET');

        if (!$orderIdMidtrans) {
            return $this->response->setJSON([
                'status'  => false,
                'message' => 'order_id wajib diisi',
            ]);
        }

        $ch = curl_init($this->baseUrl . '/' . $orderIdMidtrans . '/status');
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER     => [
                'Accept: application/json',
                'Authorization: ' . $this->authHeader(),
            ],
        ]);
        $result = curl_exec($ch);
        curl_close($ch);

        $midtransResponse  = json_decode($result, true);
        $transactionStatus = $midtransResponse['transaction_status'] ?? 'unknown';
        $isPaid             = in_array($transactionStatus, ['settlement', 'capture'], true);

        if ($isPaid) {
            $pesananModel = new PesananModel();
            $pesanan      = $pesananModel->where('midtrans_order_id', $orderIdMidtrans)->first();
            if ($pesanan) {
                $pesananModel->update($pesanan['id_pesanan'], [
                    'status_pembayaran' => 'dibayar',
                ]);
            }
        }

        return $this->response->setJSON([
            'status' => true,
            'data'   => [
                'transaction_status' => $transactionStatus,
                'is_paid'            => $isPaid,
            ],
        ]);
    }
}