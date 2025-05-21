#!/bin/bash
set -e

# 1) Se não houver variável, sai sem mexer
if [ -z "$MIKROTIK_IPS" ]; then
  echo "[syslog-ng] MIKROTIK_IPS não definido, usando configuração estática"
  exit 0
fi

# 2) Monta o filtro com OR entre cada IP
#    Ex.: MIKROTIK_IPS="192.168.1.1,10.0.0.5"
IFS=',' read -r -a IPS <<< "$MIKROTIK_IPS"

# Cabeçalho do arquivo
conf="/etc/syslog-ng/conf.d/mikrotik.conf"
cat > "$conf" <<EOF

source s_net {
    udp(ip(0.0.0.0) port(514));
};

# Filtro gerado dinamicamente para MikroTik
filter f_mikrotik {
EOF

first=true
for ip in "${IPS[@]}"; do
  if [ "$first" = true ]; then
    echo "    host(\"$ip\")"   >> "$conf"
    first=false
  else
    echo "    or host(\"$ip\")" >> "$conf"
  fi
done

cat >> "$conf" <<'EOF'
};

destination df_mikrotik {
    file(
        "/var/log/mikrotik/${HOST}.${YEAR}.${MONTH}.${DAY}.${HOUR}.log"
        template-escape(no)
        create-dirs(yes)
        perm(0644)
        dir_perm(0755)
    );
};

log {
    source(s_net);
    filter(f_mikrotik);
    destination(df_mikrotik);
};
EOF

echo "[syslog-ng] Filtro gerado em $conf"

# 3) Testa sintaxe e recarrega o syslog-ng
syslog-ng --syntax-only
if [ $? -ne 0 ]; then
  echo "[syslog-ng] Erro na sintaxe, abortando reload" >&2
  exit 1
fi

# local padrão do PID no Alpine
pidfile="/run/syslog-ng.pid"
if [ -f "$pidfile" ]; then
  kill -HUP "$(cat $pidfile)"
  echo "[syslog-ng] Reload enviado ao master process"
else
  echo "[syslog-ng] PID file $pidfile não encontrado, iniciando syslog-ng"
  syslog-ng
fi
