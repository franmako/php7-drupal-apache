FROM php:7.3-apache

# install the PHP extensions we need
RUN set -ex; \
	\
	if command -v a2enmod; then \
		a2enmod rewrite; \
	fi; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
	    libzip-dev \
		libjpeg-dev \
		libpng-dev \
		libpq-dev \
	; \
	\
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install -j "$(nproc)" \
		gd \
		opcache \
		pdo_mysql \
		pdo_pgsql \
		zip \
	; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
COPY drupal-recommended.ini /usr/local/etc/php/conf.d/

#Copy composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

#Copy apache vhost
COPY vhost.conf /etc/apache2/sites-available/

# Copy drush launcher phar
# see https://github.com/drush-ops/drush-launcher
ADD https://github.com/drush-ops/drush-launcher/releases/download/0.6.0/drush.phar drush.phar

# Make drush launcher executable
# Enable apache vhos
# Set permissions for site folder
RUN	chmod +x drush.phar \
	&& mv drush.phar /usr/local/bin/drush
	&& ln -s /etc/apache2/sites-available/vhost.conf /etc/apache2/sites-enabled/vhost.conf 
	&& chown -R www-data:www-data /var/www/html/ 

WORKDIR /var/www/html