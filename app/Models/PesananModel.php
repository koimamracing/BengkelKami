<?php
 
namespace App\Models;
 
use CodeIgniter\Model;
 
class PesananModel extends Model
{
    protected $table            = 'pesanan';
    protected $primaryKey       = 'id_pesanan';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $allowedFields    = [
        'tanggal_reservasi',
        'tanggal_estimasi',
        'metode_pembayaran',
        'subtotal_barang',
        'subtotal_pengerjaan',
        'total_pesanan',
        'status_pembayaran',
        'status_pengerjaan',
        'id_pemesan',
        'midtrans_order_id',
    ];
 
    protected $useTimestamps = false;
}