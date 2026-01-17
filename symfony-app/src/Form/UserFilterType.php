<?php

namespace App\Form;

use Symfony\Component\Form\AbstractType;
use Symfony\Component\Form\Extension\Core\Type\ChoiceType;
use Symfony\Component\Form\Extension\Core\Type\DateType;
use Symfony\Component\Form\Extension\Core\Type\TextType;
use Symfony\Component\Form\FormBuilderInterface;
use Symfony\Component\OptionsResolver\OptionsResolver;

final class UserFilterType extends AbstractType
{
    public function buildForm(FormBuilderInterface $b, array $options): void
    {
        $b
            ->add('first_name', TextType::class, ['required' => false])
            ->add('last_name', TextType::class, ['required' => false])
            ->add('gender', ChoiceType::class, [
                'required' => false,
                'choices' => [
                    '' => '',
                    'male' => 'male',
                    'female' => 'female',
                ],
            ])
            ->add('birthdate_from', DateType::class, [
                'required' => false,
                'widget' => 'single_text',
            ])
            ->add('birthdate_to', DateType::class, [
                'required' => false,
                'widget' => 'single_text',
            ]);
    }

    public function getBlockPrefix(): string
    {
        return '';
    }

    public function configureOptions(OptionsResolver $resolver): void
    {
        $resolver->setDefaults([
            'method' => 'GET',
            'csrf_protection' => false,
        ]);
    }
}
