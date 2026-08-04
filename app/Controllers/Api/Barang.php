<?php

namespace App\Controllers\Api;

use App\Controllers\BaseController;
use App\Models\BarangModel;

class Barang extends BaseController
{
    public function index()
    {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token, Authorization');
        header('Access-Control-Allow-Methods: GET, OPTIONS');

        $model = new BarangModel();
        
        $menu = $this->request->getGet('menu');
        $kategori = $this->request->getGet('kategori');

        if ($kategori && $kategori !== '') {
            $barang = $model->where('kategori', $kategori)->findAll();
        } 
        else if ($menu && $menu !== '') {
            if ($menu === 'Ganti Sparepart') {
                $kategoriSparepart = [
                    'headlight', 'backlight', 'kaca_depan', 'kaca_samping', 
                    'kaca_belakang', 'spion', 'wiper', 'kaca_film'
                ];
                $barang = $model->whereIn('kategori', $kategoriSparepart)->findAll();
            } else if ($menu === 'Cat dan Oli') {
                $kategoriCatOli = ['warna_cat', 'oli'];
                $barang = $model->whereIn('kategori', $kategoriCatOli)->findAll();
            } else {
                $barang = $model->findAll();
            }
        } 
        else {
            $barang = $model->findAll();
        }

        return $this->response->setJSON([
            'status'  => true,
            'message' => 'Berhasil mengambil data barang',
            'data'    => $barang
        ]);
    }
}