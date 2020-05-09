#! /usr/bin/env sh
set -ev

ELK_HOST=$1
ELK_USERNAME=$2
ELK_PASSWORD=$3
APP_NAME=$4
ENV_NAME=$5

# construct dir with all of the files we need to run for PROD
sed -i -E "s/REPLACE_ME_WITH_APP_NAME/${APP_NAME}/g" filebeat.config
sed -i -E "s/REPLACE_ME_WITH_ENV_NAME/${ENV_NAME}/g" filebeat.config
sed -i -E "s/REPLACE_ME_WITH_HOST/${ELK_HOST}/g" filebeat.config
sed -i -E "s/REPLACE_ME_WITH_USERNAME/${ELK_USERNAME}/g" filebeat.config
sed -i -E "s/REPLACE_ME_WITH_PASSWORD/${ELK_PASSWORD}/g" filebeat.config

sed -i -E "s/REPLACE_ME_WITH_APP_NAME/${APP_NAME}/g" metricbeat.config
sed -i -E "s/REPLACE_ME_WITH_ENV_NAME/${ENV_NAME}/g" metricbeat.config
sed -i -E "s/REPLACE_ME_WITH_HOST/${ELK_HOST}/g" metricbeat.config
sed -i -E "s/REPLACE_ME_WITH_USERNAME/${ELK_USERNAME}/g" metricbeat.config
sed -i -E "s/REPLACE_ME_WITH_PASSWORD/${ELK_PASSWORD}/g" metricbeat.config

sed -i -E "s/REPLACE_ME_WITH_APP_NAME/${APP_NAME}/g" auditbeat.config
sed -i -E "s/REPLACE_ME_WITH_ENV_NAME/${ENV_NAME}/g" auditbeat.config
sed -i -E "s/REPLACE_ME_WITH_HOST/${ELK_HOST}/g" auditbeat.config
sed -i -E "s/REPLACE_ME_WITH_USERNAME/${ELK_USERNAME}/g" auditbeat.config
sed -i -E "s/REPLACE_ME_WITH_PASSWORD/${ELK_PASSWORD}/g" auditbeat.config