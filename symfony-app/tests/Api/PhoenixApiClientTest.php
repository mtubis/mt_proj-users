<?php

namespace App\Tests\Api;

use App\Api\PhoenixApiClientInterface;
use App\Api\PhoenixApiClient;
use PHPUnit\Framework\TestCase;
use Symfony\Component\HttpClient\MockHttpClient;
use Symfony\Component\HttpClient\Response\MockResponse;

final class PhoenixApiClientTest extends TestCase
{
    public function testListUsers(): void
    {
        $mockResponse = new MockResponse(json_encode([
            'data' => [
                [
                    'id' => 1,
                    'first_name' => 'Jan',
                    'last_name' => 'Kowalski',
                    'gender' => 'male',
                    'birthdate' => '1990-01-01',
                ]
            ]
        ]));

        $http = new MockHttpClient($mockResponse);
        $client = new PhoenixApiClient($http, 'http://phoenix/api');

        $result = $client->listUsers();

        $this->assertCount(1, $result['data']);
        $this->assertSame('Jan', $result['data'][0]['first_name']);
    }
}
