<?php

namespace App\Controller;

use App\Api\PhoenixApiClientInterface;
use App\Api\PhoenixApiClient;
use App\Form\UserFilterType;
use App\Form\UserType;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/users')]
final class UserController extends AbstractController
{
    #[Route('', name: 'users_index', methods: ['GET'])]
    public function index(Request $req, PhoenixApiClientInterface $api): Response
    {
        $filterForm = $this->createForm(UserFilterType::class, null, [
            'method' => 'GET',
            'csrf_protection' => false,
        ]);
        $filterForm->handleRequest($req);

        $query = $req->query->all();

        try {
            $data = $api->listUsers($query);
            $users = $data['data'] ?? [];
        } catch (\Throwable $e) {
            // API is down / invalid JSON / network error, etc.
            $users = [];
            $this->addFlash('error', 'Backend API is temporarily unavailable. Please try again in a moment.');
            // optional: login
            // $this->logger->error('Phoenix API failed', ['exception' => $e]);
        }

        return $this->render('users/index.html.twig', [
            'filterForm' => $filterForm,
            'users' => $users,
        ]);
    }


    #[Route('/new', name: 'users_new', methods: ['GET','POST'])]
    public function new(Request $req, PhoenixApiClientInterface $api): Response
    {
        $form = $this->createForm(UserType::class);
        $form->handleRequest($req);

        if ($form->isSubmitted() && $form->isValid()) {
            $payload = $form->getData();
            $payload['birthdate'] = $payload['birthdate']->format('Y-m-d');

            $res = $api->createUser($payload);

            if (!empty($res['errors'])) {
                $this->addFlash('error', 'Błąd walidacji po stronie API.');
            } else {
                $this->addFlash('success', 'Utworzono użytkownika.');
                return $this->redirectToRoute('users_index');
            }
        }

        return $this->render('users/form.html.twig', [
            'form' => $form,
            'mode' => 'new',
        ]);
    }

    #[Route('/{id}/edit', name: 'users_edit', methods: ['GET','POST'])]
    public function edit(int $id, Request $req, PhoenixApiClientInterface $api): Response
    {
        $user = $api->getUser($id)['data'] ?? null;
        if (!$user) {
            throw $this->createNotFoundException();
        }

        $form = $this->createForm(UserType::class, [
            'first_name' => $user['first_name'] ?? '',
            'last_name' => $user['last_name'] ?? '',
            'gender' => $user['gender'] ?? 'male',
            'birthdate' => new \DateTimeImmutable($user['birthdate']),
        ]);
        $form->handleRequest($req);

        if ($form->isSubmitted() && $form->isValid()) {
            $payload = $form->getData();
            $payload['birthdate'] = $payload['birthdate']->format('Y-m-d');

            $res = $api->updateUser($id, $payload);

            if (!empty($res['errors'])) {
                $this->addFlash('error', 'Błąd walidacji po stronie API.');
            } else {
                $this->addFlash('success', 'Zapisano zmiany.');
                return $this->redirectToRoute('users_index');
            }
        }

        return $this->render('users/form.html.twig', [
            'form' => $form,
            'mode' => 'edit',
            'id' => $id,
        ]);
    }

    #[Route('/{id}/delete', name: 'users_delete', methods: ['POST'])]
    public function delete(int $id, Request $req, PhoenixApiClientInterface $api): Response
    {
        if (!$this->isCsrfTokenValid('del_'.$id, $req->request->get('_token'))) {
            $this->addFlash('error', 'CSRF invalid.');
            return $this->redirectToRoute('users_index');
        }

        $api->deleteUser($id);
        $this->addFlash('success', 'Usunięto użytkownika.');

        return $this->redirectToRoute('users_index');
    }
}
