# Set nginx base image
FROM digitalcountry/nginx-php

# File Author / Maintainer
MAINTAINER ANO "Digital Country"

RUN set -ex \
  && apk update \
  && apk --no-cache add php7-mysqli php7-pdo_mysql php7-simplexml php7-intl php7-fileinfo

#RUN docker-php-ext-install mysqli pdo pdo_mysql

ADD etc/php-fpm/www.conf /etc/php7/php-fpm.d/www.conf
ADD etc/php-fpm/php.ini /etc/php7/php.ini
ADD etc/nginx/default.conf /etc/nginx/conf.d/default.conf
ADD etc/nginx/fastcgi.conf /etc/nginx/fastcgi.conf

