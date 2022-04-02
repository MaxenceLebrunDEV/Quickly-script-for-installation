#!/bin/bash

if [ "$(whoami)" != 'root' ]; then
	echo "Veuiller exécuter ce programme  en tant qu'utilisateur du groupe sudo."
	exit 1;
fi

domain=$1
rootPath=$2
sitesEnable='/etc/nginx/sites-enabled/'
sitesAvailable='/etc/nginx/sites-available/'
serverRoot='/srv/'
domainRegex="^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$"

while [ "$domain" = "" ]
do
	echo "S'il vous plaît indiquer le nom de domaine:"
	read domain
done

until [[ $domain =~ $domainRegex ]]
do
	echo "Entrer un nom de domaine valide s'il vous plaît:"
	read domain
done

if [ -e $sitesAvailable$domain ]; then
	echo "Ce domaine existe déjà.\ Essayant en un autre"
	exit;
fi


if [ "$rootPath" = "" ]; then
	rootPath=$serverRoot$domain
fi

if ! [ -d $rootPath ]; then
	mkdir $rootPath
	chmod 777 $rootPath
	if ! echo "Hello, world!" > $rootPath/index.php
	then
		echo "ERREUR:  $rootPath/index.php. Les permissions sont insuffisantes."
		exit;
	else
		echo "Contenu ajouté : $rootPath/index.php"
	fi
fi

if ! [ -d $sitesEnable ]; then
	mkdir $sitesEnable
	chmod 777 $sitesEnable
fi

if ! [ -d $sitesAvailable ]; then
	mkdir $sitesAvailable
	chmod 777 $sitesAvailable
fi

configName=$domain

if ! echo "server {
	listen 80;
	root $rootPath;
	index  samplepage.html index.php index.html index.htm;
	server_name $domain;
	location = /favicon.ico { log_not_found off; access_log off; }
	location = /robots.txt { log_not_found off; access_log off; }
	location ~* \.(jpg|jpeg|gif|css|png|js|ico|xml)$ {
		access_log off;
		log_not_found off;
	}
 location ~ \.php$ {
                include snippets/fastcgi-php.conf;

                # With php-fpm (or other unix sockets):
                fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        }
        
	location ~ /\.ht {
		deny all;
	}
	client_max_body_size 0;
}" > $sitesAvailable$configName
then
	echo "Le fichier $configName ne peut pas être modifié dût au manque de permissions !"
	exit;
else
	echo "Nouveau VHOST à été créer!!"
fi

if ! echo "127.0.0.1	$domain" >> /etc/hosts
then
	echo "ERREUR: Je ne peut pas modifier /etc/hosts"
	exit;
else
	echo "CHOST ajouté au dossier /etc/hosts"
fi

ln -s $sitesAvailable$configName $sitesEnable$configName

service nginx restart

cd $rootPath

wget https://raw.githubusercontent.com/MaxenceLebrunDEV/Quickly-script-for-installation/main/assets/samplepage.html;



echo "Félicitations ! \nVous avez un nouveau vhost \nPour se connecter à celui-ci faite: http://$domain \n Son répertoire est $rootPath"
exit;
