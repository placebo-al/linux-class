#!/bin/bash

# Variables

ELASTIC_SEARCH="/etc/elasticsearch/elasticsearch.yml"
SYSLOG_CONFIG="/etc/logstash/conf.d/syslog.conf"
KIBANA_CONFIG="/etc/kibana/kibana.yml"
SYSLOG_CONFIG="/etc/logstash/conf.d/syslog.conf"
LOGSTASH_RSYSLOG_CONF="/etc/rsyslog.d/logstash.conf"
SYSLOG_HOST="10.23.45.50"
SYSLOG_PORT="5141"


if [ $(id -u) -ne 0 ]
then 
	echo "Please run with sudo or as root"
	exit 1
fi

# Install Elasticsearch
sudo dnf install -y http://mirror.linuxtrainingacademy.com/elasticsearch/elasticsearch-7.9.2-x86_64.rpm
# back up here: https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.9.2-x86_64.rpm

# Configure Elasticsearch
echo "cluster.name: syslog" >> $ELASTIC_SEARCH
echo "node.name: syslog" >> $ELASTIC_SEARCH

# Enable and start Elasticsearch
systemctl start elasticsearch && systemctl enable elasticsearch

# Test Elasticsearch
curl -s http://localhost:9200 || { echo "Elasticsearch failed to start"; exit 1; }

# Install Java runtime
dnf install -y java-1.8.0-openjdk

# Install Logstash
sudo dnf install -y http://mirror.linuxtrainingacademy.com/logstash/logstash-7.9.2.rpm
# back up here: https://artifacts.elastic.co/downloads/logstash/logstash-7.9.2.rpm

# Configure Logstash
cat <<EOL > "$SYSLOG_CONFIG"
input {
    syslog {
        type => syslog
        port => $SYSLOG_PORT
    }
}
filter {
    if [type] == "syslog" {
        grok {
            match => { "message" => "Accepted %{WORD:auth_method} for %{USER:username} from %{IP:src_ip} port %{INT:src_port} ssh2" }
            add_tag => "ssh_successful_login"
        }
        grok {
            match => { "message" => "Failed %{WORD:auth_method} for %{USER:username} from %{IP:src_ip} port %{INT:src_port} ssh2" }
            add_tag => "ssh_failed_login"
        }
        grok {
            match => { "message" => "Invalid user %{USER:username} from %{IP:src_ip}" }
            add_tag => "ssh_failed_login"
        }
    }
    geoip {
        source => "src_ip"
    }
}
output {
    elasticsearch { }
}
EOL

# Enable and start Logstash
systemctl start logstash && systemctl enable logstash

# Confirm it has started by: cat /var/log/logstash/logstash-plain.log

# Configure Rsyslog
echo "*.* @$SYSLOG_HOST:$SYSLOG_PORT" > "$LOGSTASH_RSYSLOG_CONF"
systemctl restart rsyslog

# Install Kibana
sudo dnf install -y http://mirror.linuxtrainingacademy.com/kibana/kibana-7.9.2-x86_64.rpm
# back up is: https://artifacts.elastic.co/downloads/kibana/kibana-7.9.2-x86_64.rpm

# Configure Kibana
echo "server.host: \"$SYSLOG_HOST\"" >> "$KIBANA_CONFIG"

# Enable and start Kibana
systemctl start kibana && systemctl enable kibana

echo "Setup complete. Access Kibana at http://$SYSLOG_HOST:5601"

# Read notes to gather more information about progressing forward
