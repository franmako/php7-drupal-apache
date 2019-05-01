FROM php:7.3-apache

# install the PHP extensions we need
RUN apt-get update && apt-get install -y --no-install-recommends \
	libjpeg-dev \
	libpng-dev \
	libpq-dev \
	libzip-dev \
	git \
	unzip \
	wget \
	mysql-client \
	vim \
	&& rm -rf /var/lib/apt/lists/*

#Install required php extension
# see https://www.drupal.org/docs/8/system-requirements/php-requirements
RUN docker-php-ext-install \
	opcache \
	pdo_mysql \
	zip \
	gd

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
COPY drupal-recommended.ini /usr/local/etc/php/conf.d/

# Install drush launcher
# see https://github.com/drush-ops/drush-launcher
RUN wget -O drush.phar https://github.com/drush-ops/drush-launcher/releases/download/0.6.0/drush.phar \
	&& chmod +x drush.phar \
	&& mv drush.phar /usr/local/bin/drush

#Install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

#Copy apache vhost
COPY vhost.conf /etc/apache2/sites-available/
RUN ln -s /etc/apache2/sites-available/vhost.conf /etc/apache2/sites-enabled/vhost.conf

RUN chown -R www-data:www-data /var/www/html/ 

WORKDIR /var/www/html