#!/bin/bash

if [ $(id -u) -ne 0 ]
then 
  echo "Please run with sudo or as root"
  exit 1
fi

# Install the Influxdb repo
dnf install -y http://mirror.linuxtrainingacademy.com/grafana/influxdb-1.8.2.x86_64.rpm
# dnf install https://dl.inuxdata.com/inuxdb/releases/inuxdb-1.8.2.x86_64.rpm


systemctl start influxdb
systemctl enable influxdb

# Install the Telegraf repo
dnf install -y http://mirror.linuxtrainingacademy.com/grafana/telegraf-1.15.3-1.x86_64.rpm
# dnf install https://dl.inuxdata.com/telegraf/releases/telegraf-1.15.3-1.x86_64.rpm

# Using sed to uncomment the following lines

config_file="/etc/telegraf/telegraf.conf"
# sed -i 's/^\# [[inputs.conntrack]]/[[inputs.conntrack]]/'

sed -i '/^# \[\[inputs\.\(conntrack\|internal\|interrupts\|linux_sysctl_fs\|net\|netstat\|nstat\)\]\]/s/^# //' $config_file

# for section in conntrack internal interrupts linux_sysctl_fs net netstat nstat; do
#   sed -i "s/^# \[\[inputs\.$section\]\]/\[\[inputs\.$section\]\]/" $config_file
# done

# [[inputs.conntrack]]
# [[inputs.internal]]
# [[inputs.interrupts]]
# [[inputs.linux_sysctl_fs]]
# [[inputs.net]]
# [[inputs.netstat]]
# [[inputs.nstat]]

systemctl start telegraf
systemctl enable telegraf

# # To test configuration:
# influx
# show databases    # Telegraf should be here, if not check the service
# use telegraf
# show measurements
# select * from swap where time > now() - 1m
# exit

# Install Grafana
dnf install -y http://mirror.linuxtrainingacademy.com/grafana/grafana-7.2.0-1.x86_64.rpm
# dnf install -y https://dl.grafana.com/oss/release/grafana-7.2.0-1.x86_64.rpm

# Well need to log in with admin: admin and use the web interface
# http://10.23.45.40:3000/
