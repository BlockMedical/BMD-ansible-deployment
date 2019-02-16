# Create the ES instance based on AMI, minimal is t3.medium instance type

```
ansible all -m ping && ansible-playbook -i hack setup-demo.yml && ansible-playbook -i hack setup-event-listener2.yml
```

Manually setup an extra event listener as normal user `centos` (no `root` here).
```
sudo chown -R root:root /mnt/blockmed-eth-event-listenerX
cd ~
git clone https://github.com/BlockMedical/BMD-eth-event-listener.git
cd BMD-eth-event-listener/app
sudo su - -c "chmod -R 777 /mnt/blockmed-eth-event-listenerX"
ln -s /mnt/blockmed-eth-event-listenerX/logs logs
npm install
NODE_ENV=production node event_watcher.js
```

# Install nginx if it does not exist
```
sudo yum install -y nginx
sudo service stop nginx
sudo systemctl stop nginx
sudo systemctl disable nginx
```

# Copy SSL
Assume you have your SSL in the direcotry `~/.ssh/myssl`
```
scp -r ~/.ssh/myssl eess:/tmp/
# Login to eess
sudo su - 
mkdir -p /etc/nginx/certs
cd /root/
mv /tmp/myssl .
chown -R root:root myssl
cd myssl
unzip sslforfree_wildcard.zip
mv certificate.crt private.key ca_bundle.crt /etc/nginx/certs/
chmod 600 /etc/nginx/certs/*
cd /etc/nginx/certs/
cat certificate.crt > cert_chain.crt
echo '' >> cert_chain.crt
cat ca_bundle.crt >> cert_chain.crt
```

```
service elasticsearch restart
service logstash restart
service filebeat restart
```

# Copy nginx.conf to /etc/nginx/nginx.conf

# Tweak the IP address and domain in there to your domain e.g. blockmed.ai

Kick off nginx

```
./run-nginx.sh
```
