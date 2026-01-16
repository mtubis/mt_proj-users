<?php

namespace App\Api;

interface PhoenixApiClientInterface
{
    public function listUsers(array $query = []): array;
    public function getUser(int $id): array;
    public function createUser(array $payload): array;
    public function updateUser(int $id, array $payload): array;
    public function deleteUser(int $id): int;
}
