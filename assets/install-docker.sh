#!/bin/bash

# Install Docker on Ubuntu Trusty and later

set -e

function err_exit()
{
	echo "$1 Stop." >&2;
	exit 1;
}

[[ -f /etc/lsb-release ]] || err_exit "Cannot install Docker because /etc/lsb-release was not found.";
DISTRIB_CODENAME=$(grep DISTRIB_CODENAME /etc/lsb-release  | cut -d'=' -f2);

# Check that it's OK to install linux-image-extra-virtual and bail if not.
KERN_GENERIC_INSTALLED=$(apt-cache policy linux-image-generic | grep Installed: | awk '{print $2}');
KERN_VIRTUAL_INSTALLED=$(apt-cache policy linux-image-virtual | grep Installed: | awk '{print $2}');
KERN_VIRTUAL_EXTRA_INSTALLED=$(apt-cache policy linux-image-extra-virtual | grep Installed: | awk '{print $2}');
KERN_VIRTUAL_EXTRA_CANDIDATE=$(apt-cache policy linux-image-extra-virtual | grep Candidate: | awk '{print $2}');
if [[ $KERN_VIRTUAL_EXTRA_INSTALLED = "(none)" ]]
then
	if [[ $KERN_GENERIC_INSTALLED != "(none)" ]]
	then
		KERN_INSTALLED=$KERN_GENERIC_INSTALLED
	elif [[ $KERN_VIRTUAL_INSTALLED != "(none)" ]]
	then
		KERN_INSTALLED=$KERN_VIRTUAL_INSTALLED
	else
		err_exit "Cannot determine whether it is safe to install linux-image-extra-virtual."
	fi
	if [[ $KERN_VIRTUAL_EXTRA_CANDIDATE != $KERN_INSTALLED ]]
	then
		echo >&2 "Installing linux-image-extra-virtual would install a different version of your kernel."
		echo >&2 "Consider upgrading your kernel."
		err_exit "Cannot install linux-image-extra-virtual."
	fi
fi

case $DISTRIB_CODENAME in
	wily|xenial)
		sudo mkdir /etc/systemd/system/docker.service.d \
			&& sudo mv /tmp/custom-exec-start.conf /etc/systemd/system/docker.service.d \
			&& sudo chown root:root /etc/systemd/system/docker.service.d/custom-exec-start.conf \
			&& sudo chmod 0644 /etc/systemd/system/docker.service.d/custom-exec-start.conf;
		;;
	trusty)
		sudo mv /tmp/docker /etc/default/ \
			&& sudo chown root:root /etc/default/docker \
			&& sudo chmod 0644 /etc/default/docker;
		;;
	precise)
		err_exit "Installing to Ubuntu Precise Pangolin is not possible with this script."
		;;
	*)
		echo "Installing to an Ubuntu release other than Trusty, Wily or Xenial is unsupported, but may work."
		sudo mkdir /etc/systemd/system/docker.service.d \
			&& sudo mv /tmp/custom-exec-start.conf /etc/systemd/system/docker.service.d \
			&& sudo chown root:root /etc/systemd/system/docker.service.d/custom-exec-start.conf \
			&& sudo chmod 0644 /etc/systemd/system/docker.service.d/custom-exec-start.conf;
		;;
esac

sudo apt-get install apt-transport-https ca-certificates \
	&& sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D \
	&& echo "deb https://apt.dockerproject.org/repo ubuntu-${DISTRIB_CODENAME} main" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null \
	&& sudo apt-get update \
	&& sudo apt-get purge lxc-docker \
	&& sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
		install -y linux-image-extra-$(uname -r) linux-image-extra-virtual docker-engine;

if [[ $DISTRIB_CODENAME != "trusty" ]]
then
	sudo systemctl enable docker;
fi
