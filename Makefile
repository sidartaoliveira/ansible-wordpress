SHELL := /bin/bash


install:
	ansible-playbook provisioning.yml
	lxc exec wordpress -- apt install -y python
	ansible-playbook configure.yml --vault-password-file ./.vault_pass.txt

expose:
	$(eval ipaddr := $(shell lxc info wordpress | awk '/eth0:\s+inet\s+/{print $$3}'))
	$(eval public-ipaddr := $(shell curl --silent ifconfig.me))
	sudo iptables -t nat -A PREROUTING -i ens3 -p TCP -d ${public-ipaddr}/32 --dport 80 -j DNAT --to-destination ${ipaddr}:80

clean:
	for ln in $$( sudo iptables -t nat --line-numbers -L | grep ^[0-9] | awk '/DNAT/{print $$1}' | tac ); do sudo iptables -t nat -D PREROUTING $${ln} ; done
	lxc delete wordpress --force
