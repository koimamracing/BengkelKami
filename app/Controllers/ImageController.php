<?php
namespace App\Controllers;

class ImageController extends BaseController
{
    public function barang($filename)
    {
        $path = WRITEPATH . 'uploads/imgbarang/' . $filename;

        if (!is_file($path)) {
            return $this->response->setStatusCode(404);
        }

        return $this->response
            ->setHeader('Access-Control-Allow-Origin', '*')
            ->setContentType(mime_content_type($path))
            ->setBody(file_get_contents($path));
    }
}