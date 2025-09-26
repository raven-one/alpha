FROM php:8.2-fpm-alpine
RUN apk add --no-cache nginx supervisor curl bash ca-certificates && docker-php-ext-install pdo pdo_mysql && mkdir -p /run/nginx
WORKDIR /var/www/html
COPY src/ /var/www/html/
COPY nginx/default.conf /etc/nginx/http.d/default.conf
COPY supervisord.conf /etc/supervisord.conf
RUN echo 'clear_env = no' > /usr/local/etc/php-fpm.d/zz-php-fpm.conf
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://127.0.0.1/health.php || exit 1
CMD ["/usr/bin/supervisord","-c","/etc/supervisord.conf"]
