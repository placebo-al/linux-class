#!/bin/bash

config_file="/etc/telegraf/telegraf.conf"
# influxdb_install="https://dl.inuxdata.com/inuxdb/releases/inuxdb-1.8.2.x86_64.rpm"
influxdb_install="http://mirror.linuxtrainingacademy.com/grafana/influxdb-1.8.2.x86_64.rpm"
#telegraf_install="https://dl.inuxdata.com/telegraf/releases/telegraf-1.15.3-1.x86_64.rpm"
telegraf_install=http://mirror.linuxtrainingacademy.com/grafana/telegraf-1.15.3-1.x86_64.rpm
grafana_install="https://dl.grafana.com/oss/release/grafana-7.2.0-1.x86_64.rpm"


if [ $(id -u) -ne 0 ]
then 
  echo "Please run with sudo or as root"
  exit 1
fi

# Install and start the Influxdb installation
dnf install -y $influxdb_install
systemctl start influxdb && systemctl enable influxdb

# Install the Telegraf repo
dnf install -y $telegraf_install

# Use sed to change the config file
sed -i '/^# \[\[inputs\.\(conntrack\|internal\|interrupts\|linux_sysctl_fs\|net\|netstat\|nstat\)\]\]/s/^# //' $config_file

# Start the telegraf service
systemctl start telegraf && systemctl enable telegraf

# # To test the telegraf configuration:
# influx
# show databases    # Telegraf should be here, if not check the service
# use telegraf
# show measurements
# select * from swap where time > now() - 1m
# exit

# Install Grafana
dnf install -y $grafana_install

# Start the grafana service
systemctl start grafana-server && systemctl enable grafana-server

echo ""
echo "Need to log in with admin: admin and use the web interface to finish the installation"
echo "This will be in the notes for Project 7"
echo "http://10.23.45.40:3000/"
