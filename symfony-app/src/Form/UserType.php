<?php

namespace App\Form;

use Symfony\Component\Form\AbstractType;
use Symfony\Component\Form\Extension\Core\Type\ChoiceType;
use Symfony\Component\Form\Extension\Core\Type\DateType;
use Symfony\Component\Form\Extension\Core\Type\TextType;
use Symfony\Component\Form\FormBuilderInterface;

final class UserType extends AbstractType
{
    public function buildForm(FormBuilderInterface $b, array $options): void
    {
        $b
            ->add('first_name', TextType::class)
            ->add('last_name', TextType::class)
            ->add('gender', ChoiceType::class, [
                'choices' => [
                    'male' => 'male',
                    'female' => 'female',
                ],
            ])
            ->add('birthdate', DateType::class, [
                'widget' => 'single_text',
            ]);
    }
}
