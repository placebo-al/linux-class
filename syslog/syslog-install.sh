#!/bin/bash

ELASTIC_SEARCH="/etc/elasticsearch/elasticsearch.yml"

if [ $(id -u) -ne 0 ]
then 
	echo "Please run with sudo or as root"
	exit 1
fi

sudo dnf install -y http://mirror.linuxtrainingacademy.com/elasticsearch/elasticsearch-7.9.2-x86_64.rpm
# back up here: https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.9.2-x86_64.rpm

echo "cluster.name: syslog" >> $ELASTIC_SEARCH
echo "node.name: syslog" >> $ELASTIC_SEARCH

systemctl start elasticsearch && systemctl enable elasticsearch

# To test
curl http://localhost:9200

dnf install -y java-1.8.0-openjdk

sudo dnf install -y http://mirror.linuxtrainingacademy.com/logstash/logstash-7.9.2.rpm
# back up here: https://artifacts.elastic.co/downloads/logstash/logstash-7.9.2.rpm


cat <<EOL > /etc/logstash/conf.d/syslog.conf
input {
	syslog {
		type => syslog
		port => 5141
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

systemctl start logstash && systemctl enable logstash

# Confirm it has started by: cat /var/log/logstash/logstash-plain.log

echo "*.* @10.23.45.50:5141" /etc/ryslog.d/logstash.conf

systemctl restart rsyslog

# Install Kibana
sudo dnf install -y http://mirror.linuxtrainingacademy.com/kibana/kibana-7.9.2-x86_64.rpm
# back up is: https://artifacts.elastic.co/downloads/kibana/kibana-7.9.2-x86_64.rpm

echo 'server.host: "10.23.45.50"'

systemctl start kibana && systemctl enable kibana

# Open page http://10.23.45.50:5601

# Read notes to gather more information about progressing forward
