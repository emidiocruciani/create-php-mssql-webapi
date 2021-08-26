FROM php:8.0.9-apache-buster AS bare
RUN apt-get update && apt-get install -y \
        gnupg2 \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update && ACCEPT_EULA=Y apt-get install -y \
        msodbcsql17 \
        # g++ \
        # gcc \
        # unixodbc \
        unixodbc-dev \
    && docker-php-ext-configure pdo_odbc --with-pdo-odbc=unixODBC,/usr \
    && docker-php-ext-install pdo_odbc

FROM bare as shared
COPY /docker/config/php $PHP_INI_DIR
COPY /docker/config/apache /etc/apache2
RUN a2enmod rewrite
WORKDIR /usr/share/www

FROM shared as develop
COPY /docker/config/php/php.ini-development $PHP_INI_DIR/php.ini

FROM shared AS publish
COPY /docker/config/php/php.ini-production $PHP_INI_DIR/php.ini
COPY / /usr/share/www
RUN rm $PHP_INI_DIR/php.ini-development \
    && rm $PHP_INI_DIR/php.ini-production \
    && rm -rf /usr/share/www/docker \
    && rm -rf $PHP_INI_DIR/original \
    && rm -rf /etc/apache2/original