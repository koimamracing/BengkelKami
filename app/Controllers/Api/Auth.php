<?php

namespace App\Controllers\Api;

use App\Controllers\BaseController;
use App\Models\UserModel;

class Auth extends BaseController
{
    public function login()
    {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token, Authorization');
        header('Access-Control-Allow-Methods: POST, OPTIONS');

        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            exit(0);
        }

        $email = $this->request->getPost('email');
        $password = $this->request->getPost('password');

        $model = new UserModel();
        $user = $model->where('email', $email)->first();

        if (!$user) {
            return $this->response->setJSON([
                'status' => false, 
                'message' => 'Email tidak ditemukan'
            ]);
        }

        if ($user['email_verified_at'] === null) {
            return $this->response->setJSON([
                'status' => false, 
                'message' => 'Email Anda belum diverifikasi. Silakan cek Gmail Anda.'
            ]);
        }

        if ($user['password'] != $password) {
            return $this->response->setJSON([
                'status' => false, 
                'message' => 'Password salah'
            ]);
        }

        return $this->response->setJSON([
            'status' => true,
            'message' => 'Login berhasil',
            'data' => [
            'id'       => $user['id'],
            'email'    => $user['email'],
            'role'     => $user['role'] ?? 'client'
        ]
        ]);
    }

    public function register()
    {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token, Authorization');
        header('Access-Control-Allow-Methods: POST, OPTIONS');

        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            exit(0);
        }

        $email = $this->request->getPost('email');
        $password = $this->request->getPost('password');

        $model = new UserModel();
        $cek = $model->where('email', $email)->first();

        if ($cek) {
            return $this->response->setJSON([
                'status' => false, 
                'message' => 'Email sudah digunakan'
            ]);
        }

        $token = base64_encode($email);

        $model->save([
            'email' => $email,
            'password' => $password,
            'role'     => 'client',
            'email_verified_at' => null
        ]);

        $emailService = \Config\Services::email();
        $emailService->setTo($email);
        $emailService->setSubject('Verifikasi Akun - Bengkel Kita');
        
        $verificationLink = "http://localhost:8080/api/auth/verify?token=" . $token;

        $message = "
            <h3>Halo! Selamat Datang di Bengkel Kita</h3>
            <p>Terima kasih telah mendaftar. Selesaikan pendaftaran Anda dengan mengklik tombol di bawah ini:</p>
            <p><a href='{$verificationLink}' style='background:#2196F3; color:white; padding:10px 20px; text-decoration:none; border-radius:5px;'>Verifikasi Akun Saya</a></p>
            <br>
            <p>Atau buka link berikut di browser Anda:</p>
            <p>{$verificationLink}</p>
        ";
        $emailService->setMessage($message);

        if ($emailService->send()) {
            return $this->response->setJSON([
                'status' => true,
                'message' => 'Registrasi berhasil. Silakan cek Gmail Anda untuk memverifikasi akun!'
            ]);
        } else {
            $debugger = $emailService->printDebugger(['headers', 'subject', 'body']);
            
            return $this->response->setJSON([
                'status' => false,
                'message' => 'Gagal mengirimkan email verifikasi.',
                'error_debug' => strip_tags($debugger)
            ]);
        }
    }

   public function verify()
    {
        $token = $this->request->getGet('token');
        if (!$token) {
            echo "<div style='text-align:center; margin-top:50px; font-family:sans-serif; color:#d32f2f;'><h3>Token tidak valid.</h3></div>";
            exit;
        }

        $email = base64_decode($token);
        $model = new UserModel();
        $user = $model->where('email', $email)->first();
        $htmlHead = "
        <!DOCTYPE html>
        <html lang='id'>
        <head>
            <meta charset='UTF-8'>
            <meta name='viewport' content='width=device-width, initial-scale=1.0'>
            <title>Verifikasi Akun</title>
            <link href='https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap' rel='stylesheet'>
            <style>
                * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Roboto', sans-serif; }
                body { background-color: #E0E0E0; display: flex; flex-direction: column; min-height: 100vh; }
                .app-header { width: 100%; background-color: #FFFFFF; padding: 20px 25px; display: flex; justify-content: flex-start; }
                .app-header img { height: 40px; object-fit: contain; }
                .main-container { flex: 1; display: flex; justify-content: center; align-items: center; padding: 25px; }
                .success-card { width: 100%; max-width: 450px; background-color: #FFFFFF; border-radius: 40px; padding: 40px 30px; box-shadow: 0 4px 10px rgba(0, 0, 0, 0.05); display: flex; flex-direction: column; align-items: center; text-align: center; }
                .icon-circle { width: 80px; height: 80px; background-color: #2196F3; border-radius: 50%; display: flex; justify-content: center; align-items: center; margin-bottom: 30px; }
                .icon-circle.info { background-color: #FF9800; } /* Untuk status sudah aktif */
                .icon-circle svg { width: 50px; height: 50px; fill: #FFFFFF; }
                .title { font-size: 14px; font-weight: 700; color: #000000; margin-bottom: 10px; }
                .subtitle { font-size: 12px; color: #212121; margin-bottom: 15px; }
                .description { font-size: 12px; color: #757575; line-height: 1.4; margin-bottom: 35px; }
                .btn-redirect { background: none; border: none; color: #2196F3; font-size: 13px; font-weight: 500; text-decoration: none; cursor: pointer; padding: 8px 16px; transition: opacity 0.2s; }
                .btn-redirect:hover { opacity: 0.8; }
            </style>
        </head>
        <body>
            <div class='app-header'>
                <img src='" . base_url('assets/images/logo.png') . "' alt='Logo App' onerror=\"this.style.display='none';\">
            </div>
            <div class='main-container'>
                <div class='success-card'>
        ";

        $htmlFoot = "
                </div>
            </div>
        </body>
        </html>
        ";

        if ($user) {
            if ($user['email_verified_at'] !== null) {
                echo $htmlHead . "
                    <div class='icon-circle info'>
                        <svg viewBox='0 0 24 24'>
                            <path d='M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z'/>
                        </svg>
                    </div>
                    <div class='title'>Akun Sudah Aktif!</div>
                    <div class='subtitle'>Terima kasih!</div>
                    <div class='description'>
                        Akun Anda sudah diverifikasi sebelumnya.<br>Silakan kembali dan login di aplikasi mobile.
                    </div>
                " . $htmlFoot;
                exit;
            }

            $dataUpdate = [
                'email_verified_at' => date('Y-m-d H:i:s')
            ];

            if ($model->update($user['id'], $dataUpdate)) {
                echo $htmlHead . "
                    <div class='icon-circle'>
                        <svg viewBox='0 0 24 24'>
                            <path d='M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z'/>
                        </svg>
                    </div>
                    <div class='title'>Verifikasi Berhasil!</div>
                    <div class='subtitle'>Akun Anda telah aktif.</div>
                    <div class='description'>
                        Registrasi akun Anda berhasil.<br>Nikmati berbagai fitur dan kemudahan yang kami sediakan.
                    </div>
                " . $htmlFoot;
            } else {
                echo "<div style='text-align:center; margin-top:50px; font-family:sans-serif;'>Gagal memperbarui status verifikasi.</div>";
            }
            
        } else {
            echo "<div style='text-align:center; margin-top:50px; font-family:sans-serif;'>User tidak ditemukan atau link kadaluwarsa.</div>";
        }
    }
    public function checkStatus()
    {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token, Authorization');
        header('Access-Control-Allow-Methods: GET, OPTIONS');

        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            exit(0);
        }
        
        $email = $this->request->getGet('email');
        $model = new UserModel();
        $user = $model->where('email', $email)->first();

        if ($user && $user['email_verified_at'] !== null) {
            return $this->response->setJSON(['verified' => true]);
        }
        return $this->response->setJSON(['verified' => false]);
    }

    public function resetPassword()
    {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token, Authorization');
        header('Access-Control-Allow-Methods: POST, OPTIONS');

        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            exit(0);
        }

        $email = $this->request->getPost('email');
        $newPassword = $this->request->getPost('password');

        if (empty($email) || empty($newPassword)) {
            return $this->response->setJSON([
                'status' => false, 
                'message' => 'Email dan password baru wajib diisi.'
            ]);
        }

        $model = new UserModel();
        $user = $model->where('email', $email)->first();

        if (!$user) {
            return $this->response->setJSON([
                'status' => false, 
                'message' => 'User tidak ditemukan.'
            ]);
        }

        $dataUpdate = [
            'password' => $newPassword
        ];

        if ($model->update($user['id'], $dataUpdate)) {
            return $this->response->setJSON([
                'status' => true,
                'message' => 'Password berhasil diubah.'
            ]);
        } else {
            return $this->response->setJSON([
                'status' => false,
                'message' => 'Gagal mengubah password. Silakan coba lagi.'
            ]);
        }
    }

    public function forgotPassword()
    {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token, Authorization');
        header('Access-Control-Allow-Methods: POST, OPTIONS');

        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            exit(0);
        }

        $email = $this->request->getPost('email');

        if (empty($email)) {
            return $this->response->setJSON([
                'status' => false, 
                'message' => 'Email wajib diisi.'
            ]);
        }

        $model = new UserModel();
        $user = $model->where('email', $email)->first();

        if (!$user) {
            return $this->response->setJSON([
                'status' => false, 
                'message' => 'Email tidak terdaftar di sistem kami.'
            ]);
        }

        $token = base64_encode($email);

        $emailService = \Config\Services::email();
        $emailService->setTo($email);
        $emailService->setSubject('Reset Password - Bengkel Kita');
        
        $resetLink = "http://localhost:5555/#/reset-password?token=" . $token;

        $message = "
            <h3>Permintaan Reset Password</h3>
            <p>Kami menerima permintaan untuk mereset password akun Anda di Bengkel Kita.</p>
            <p>Jika ini memang Anda, silakan klik tombol di bawah ini untuk membuat password baru:</p>
            <p><br></p>
            <p><a href='{$resetLink}' style='background:#2196F3; color:white; padding:10px 20px; text-decoration:none; border-radius:5px;'>Reset Password Saya</a></p>
            <p><br></p>
            <p>Atau copy-paste link berikut ke browser Anda:</p>
            <p>{$resetLink}</p>
            <br>
            <p>Jika Anda merasa tidak meminta reset password, abaikan saja email ini.</p>
        ";
        
        $emailService->setMessage($message);

        if ($emailService->send()) {
            return $this->response->setJSON([
                'status' => true,
                'message' => 'Link untuk reset password telah berhasil dikirim ke email Anda.'
            ]);
        } else {
            $debugger = $emailService->printDebugger(['headers', 'subject', 'body']);
            return $this->response->setJSON([
                'status' => false,
                'message' => 'Gagal mengirimkan email reset password.',
                'error_debug' => strip_tags($debugger)
            ]);
        }
    }
}