#pour pull la version 20.04 de ubuntu
FROM ubuntu:20.04

#evite les questions pendant l'instalation des packages
ARG DEBIAN_FRONTEND=noninteractive

#fait une mise a jour de ubuntu
RUN apt update

#instale les packages de  nginx, php et supervisor, une fois terminé, supprime le cache et tous les packages pour reduire la taille de l'image personalisé
RUN apt install -y nginx php-fpm supervisor && \
    rm -rf /var/lib/apt/lists/* && \
    apt clean

#definie les variables d'environnement. c'est à dire une variable qui enregistre un chemin d'acces à un certain fichier par exemple. 
ENV nginx_vhost /etc/nginx/sites-available/default
ENV php_conf /etc/php/7.4/fpm/php.ini
ENV nginx_conf /etc/nginx/nginx.conf
ENV supervisor_conf /etc/supervisor/supervisord.conf

#COPY = copie des fichiers ou repertoire depuis le systeme fichier de l'hote vers le systeme de fichiers du conteneur.
# copie mon fichier "default" que j'ai reconfigureé et remplace le fichier "default" dans ma variable nginx_vhost(de mon image). 
COPY default ${nginx_vhost}

#remplace cgi.fix_pathinfo=1 par 0. s'il  est défini à 1 dans le fichier de configuration php.ini, cela signifie que PHP tentera de corriger automatiquement les informations de chemin si elles sont absentes dans une requête. On le met donc à 0 pour que php ne recherche pas de chemin par lui meme. evite des erreurs.
# ${php_conf} = lance la variable php_conf, donc parcourera le repertoire annoncé dans ma variable ENV jusqu'à atteindre "php.ini": on active PHP-FPM sur la configuration de virtualhost nginx
RUN sed -i -e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' ${php_conf} && \
    echo "\ndaemon off;" >> ${nginx_conf}

#applique la config supervisord.conf à mon image. Donc cela copiera le fichier supervisord.conf (que j'ai reconfiguré) puis remplacera le fichier "supervisord.conf" dans ma variable d'environement de mon image personnalisé 
COPY supervisord.conf ${supervisor_conf}

#creer un nouveau repertoire (dans le conteneur) pour le fichier sock PHP-FPM,
# modifie la propriété du repertoire racine WEB /var/www/html et du repertoire PHP-FPM /run/php en l'utilisateur par défaut www-data.
RUN mkdir -p /run/php && \
    chown -R www-data:www-data /var/www/html && \
    chown -R www-data:www-data /run/php


#definie les volumes de l'image, on lui attribue ici 5 partitions.
# chaque volume servira à stocker des données persistantes. on pourra personnalisé la configuration du serveur nginx depuis l'hote.
# sites-enabled = stocker des configurations de sites activés pour Nginx / certs = stocker et modifiers les certificats SSL/TLS
#log/nginx = stock des logs??  / var/www/html = stock le contenu web du serveur Nginx (fichier html, images etc)
VOLUME ["/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx", "/var/www/html"]

#Copie mon fichier "start.sh"(hote) vers la racine du system de fichier du conteneur.(docker)
COPY start.sh /start.sh

#permet de lancer, "sh" est un script shell. start sh est un script de demarage que j'ai configuré.
CMD ["./start.sh"]

#On expose les ports. c'est à dire que le conteneur ecoutera les ports 80 et 443
EXPOSE 80 443
 

