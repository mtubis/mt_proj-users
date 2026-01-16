<?php

namespace App\Api;

use Symfony\Contracts\HttpClient\HttpClientInterface;

final class PhoenixApiClient implements PhoenixApiClientInterface
{
    public function __construct(
        private HttpClientInterface $http,
        private string $baseUrl,
    ) {}

    public function listUsers(array $query = []): array
    {
        return $this->http->request('GET', $this->baseUrl.'/users', [
            'query' => array_filter($query, fn($v) => $v !== null && $v !== ''),
        ])->toArray(false);
    }

    public function getUser(int $id): array
    {
        return $this->http->request('GET', $this->baseUrl.'/users/'.$id)->toArray(false);
    }

    public function createUser(array $payload): array
    {
        return $this->http->request('POST', $this->baseUrl.'/users', [
            'json' => $payload,
        ])->toArray(false);
    }

    public function updateUser(int $id, array $payload): array
    {
        return $this->http->request('PUT', $this->baseUrl.'/users/'.$id, [
            'json' => $payload,
        ])->toArray(false);
    }

    public function deleteUser(int $id): int
    {
        return $this->http->request('DELETE', $this->baseUrl.'/users/'.$id)->getStatusCode();
    }
}
