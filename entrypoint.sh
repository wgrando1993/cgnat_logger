#!/bin/bash
set -e

# Garantir diretório de socket
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

# Inicializar MariaDB se necessário
if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "Inicializando banco de dados MariaDB..."
  mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

/usr/local/bin/configure-syslog-ng.sh || echo "⚠️  Erro ao configurar syslog-ng (ignorado)"

# Iniciar supervisord (via CMD)
exec "$@"