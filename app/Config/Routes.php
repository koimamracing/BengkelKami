<?php

use CodeIgniter\Router\RouteCollection;

/** @var RouteCollection $routes */

$routes->get('imgbarang/(:segment)', 'ImageController::barang/$1');
$routes->group('api/auth', ['namespace' => 'App\Controllers\Api'], function($routes) {
    $routes->get('verify', 'Auth::verify');
    $routes->post('login', 'Auth::login');
    $routes->post('register', 'Auth::register');
    $routes->get('checkStatus', 'Auth::checkStatus');
    $routes->post('forgotPassword', 'Auth::forgotPassword');
    $routes->post('resetPassword', 'Auth::resetPassword');

    $routes->options('login', function() { return response()->setStatusCode(200); });
    $routes->options('register', function() { return response()->setStatusCode(200); });
    $routes->options('checkStatus', function() { return response()->setStatusCode(200); });
    $routes->options('forgotPassword', function() { return response()->setStatusCode(200); });
    $routes->options('resetPassword', function() { return response()->setStatusCode(200); });
}); 

$routes->options('api/barang', function() {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token, Authorization');
    header('Access-Control-Allow-Methods: GET, OPTIONS');
    exit(0);
});
$routes->get('api/barang', '\App\Controllers\Api\Barang::index');
$routes->options('api/pesanan', function() {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token, Authorization');
    header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
    exit(0);
});
$routes->options('api/pesanan/(:num)', function() {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token, Authorization');
    header('Access-Control-Allow-Methods: GET, OPTIONS');
    exit(0);
});

$routes->get('api/pesanan', '\App\Controllers\Api\Pesanan::index');
$routes->post('api/pesanan', '\App\Controllers\Api\Pesanan::store');
$routes->get('api/pesanan/(:num)', '\App\Controllers\Api\Pesanan::show/$1');
$routes->options('api/midtrans/charge', function() {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token, Authorization');
    header('Access-Control-Allow-Methods: POST, OPTIONS');
    exit(0);
});
$routes->post('api/midtrans/charge', '\App\Controllers\Api\Midtrans::charge');

$routes->options('api/midtrans/status/(:segment)', function() {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token, Authorization');
    header('Access-Control-Allow-Methods: GET, OPTIONS');
    exit(0);
});
$routes->get('api/midtrans/status/(:segment)', '\App\Controllers\Api\Midtrans::status/$1');
$routes->get('api/midtrans/qr-image/(:segment)', '\App\Controllers\Api\Midtrans::qrImage/$1');
$routes->get('api/pesanan/email','Api\Pesanan::email');