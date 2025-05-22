FROM alpine:3.19

# 1. Instalar pacotes essenciais
RUN apk update && \
    apk add --no-cache \
      mariadb mariadb-client \
      nginx \
      php82-fpm php82-mysqli php82-session \ 
      syslog-ng syslog-ng-json libstdc++ \
      supervisor bash \
    && rm -rf /var/cache/apk/*

# 2. Configurar diretórios e permissões
RUN mkdir -p /var/lib/mysql /var/log/mysql /var/log/nginx /var/www/html && \
    chown -R mysql:mysql /var/lib/mysql /var/log/mysql && \
    chown -R nginx:nginx /var/log/nginx /var/www/html

RUN sed -i 's/^#log(log_file);/log(log_file);/' /etc/syslog-ng/syslog-ng.conf && \
    sed -i 's/^[[:space:]]*system();/#&/' /etc/syslog-ng/syslog-ng.conf && \
    mkdir -p /etc/syslog-ng/conf.d && \
    mv /usr/lib/syslog-ng/libcloud_auth.so /usr/lib/syslog-ng/libcloud_auth.so.disabled

# 3. Remover configurações default do nginx.
RUN rm /usr/share/nginx/http-default_server.conf && \
    mv /etc/nginx/http.d/default.conf /etc/nginx/http.d/default.conf.old

# 4. Copiar arquivos de configuração e scripts
COPY supervisord.conf  /etc/supervisord.conf
COPY entrypoint.sh      /usr/local/bin/entrypoint
COPY init.sh      /usr/local/bin/init
COPY cgnat_logger.sql /tmp/
COPY cgnatlogger.conf /etc/nginx/http.d/default.conf

#COPY /etc/syslog-ng/conf.d/mikrotik.conf /etc/syslog-ng/conf.d/99-mikrotik.conf

COPY www/ /var/www/html/
COPY configure-syslog-ng.sh /usr/local/bin/configure-syslog-ng.sh

RUN chmod +x /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/init
RUN chmod +x /usr/local/bin/configure-syslog-ng.sh

RUN sed -i 's/^memory_limit *= *128M/memory_limit = 6G/' /etc/php82/php.ini

# 5. Expor portas e definir volumes
EXPOSE 80 514 514/udp
VOLUME ["/var/lib/mysql", "/var/log/mikrotik"]

# 6. Definir ponto de entrada
ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]