#!/bin/bash
set -e

echo "[init_db] Aguardando MariaDB..."
sleep 10

DB_NAME=${DB_NAME:-cgnat_logger}
DB_USER=${DB_USER:-cgnat_user}
DB_PASS=${DB_PASS:-cgn4t_l0gg3r!}
FLAG_FILE=/var/lib/mysql/.db_cgnat

if [ ! -f "$FLAG_FILE" ]; then
    echo "[init_db] Criando base, usuário e importando schema..."

    # 1) Cria DB e usuário com um here-doc limpo
    mysql -u root <<EOSQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOSQL

    # 2) Importa schema já com o usuário criado
    mysql -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" < /tmp/cgnat_logger.sql

    touch "$FLAG_FILE"
    echo "[init_db] Schema inicializado com sucesso."
else
    echo "[init_db] Schema já inicializado, pulando..."
fi
