<?php

namespace App\Tests\Controller;

use App\Api\PhoenixApiClientInterface;
use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

final class UserControllerTest extends WebTestCase
{
    public function testUsersIndex(): void
    {
        $client = static::createClient();

        $mockApi = $this->createMock(PhoenixApiClientInterface::class);
        $mockApi->method('listUsers')->willReturn([
            'data' => [
                [
                    'id' => 1,
                    'first_name' => 'Anna',
                    'last_name' => 'Nowak',
                    'gender' => 'female',
                    'birthdate' => '1995-05-05',
                ],
            ],
        ]);

        static::getContainer()->set(PhoenixApiClientInterface::class, $mockApi);

        $client->request('GET', '/users');

        $this->assertResponseIsSuccessful();
        $this->assertSelectorTextContains('table', 'Anna');
        $this->assertSelectorTextContains('table', 'Nowak');
    }

    public function testApiFailureIsHandledGracefully(): void
    {
        $client = static::createClient();

        $mockApi = $this->createMock(PhoenixApiClientInterface::class);
        $mockApi->method('listUsers')
            ->willThrowException(new \RuntimeException('API down'));

        static::getContainer()->set(PhoenixApiClientInterface::class, $mockApi);

        $client->request('GET', '/users');

        $this->assertResponseIsSuccessful();
        $this->assertSelectorExists('.flash-error');
    }

    public function testUsersIndexPassesFilterToApiClient(): void
    {
        $client = static::createClient();

        $mockApi = $this->createMock(PhoenixApiClientInterface::class);

        $mockApi
            ->expects($this->once())
            ->method('listUsers')
            ->with($this->callback(function (array $query): bool {
                return ($query['first_name'] ?? null) === 'Anna';
            }))
            ->willReturn([
                'data' => [
                    [
                        'id' => 1,
                        'first_name' => 'Anna',
                        'last_name' => 'Nowak',
                        'gender' => 'female',
                        'birthdate' => '1995-05-05',
                    ],
                ],
            ]);

        static::getContainer()->set(PhoenixApiClientInterface::class, $mockApi);

        $client->request('GET', '/users?first_name=Anna');

        $this->assertResponseIsSuccessful();
    }

}
