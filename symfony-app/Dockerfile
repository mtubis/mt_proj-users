FROM php:8.4-cli

WORKDIR /app

RUN apt-get update \
  && apt-get install -y git unzip libicu-dev \
  && docker-php-ext-install intl \
  && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY . .
RUN composer install --no-interaction

EXPOSE 8000
CMD ["php", "-S", "0.0.0.0:8000", "-t", "public"]
