<?php

namespace App\Models;

use App\Entities\Post;
use CodeIgniter\Model;

class PostModel extends Model
{
    protected $table = 'posts';
    protected $returnType = Post::class;

    protected $allowedFields = [
        'title',
        'slug',
        'content',
        'status'
    ];

    protected $validationRules = [
            'id' => 'permit_empty|is_natural_no_zero',
        'title' => 'required|alpha_numeric_space|min_length[3]|max_length[255]|is_unique[posts.title,id,{id}]',
        'content' => 'required',
        'status' => 'required'
    ];
}