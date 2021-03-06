#! /usr/bin/env sh
set -ev

service filebeat stop
service metricbeat stop
service auditbeat stop

beat[0]="filebeat"
beat[1]="metricbeat"
beat[2]="auditbeat"

for i in "${!beat[@]}";
do
    rm -rf /etc/systemd/system/${beat[$i]}.service.d/override.conf
    rm -rf /etc/${beat[$i]}/envvars

    mkdir -p /etc/${beat[$i]}
    cat /opt/elasticbeanstalk/deployment/env.list >> /etc/${beat[$i]e}/envvars
    mkdir -p /etc/systemd/system/${beat[$i]}.service.d
    touch /etc/systemd/system/${beat[$i]}.service.d/override.conf
    echo "[Service]" >> /etc/systemd/system/${beat[$i]}.service.d/override.conf
    echo "EnvironmentFile=/etc/${beat[$i]}/envvars" >> /etc/systemd/system/${beat[$i]}.service.d/override.conf
    systemctl daemon-reload
done

service filebeat start
service metricbeat start
service auditbeat start
service nginx restart