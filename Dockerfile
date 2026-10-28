# Alpine Linux running Apache in the foreground, with tini as PID 1
FROM alpine:3.24

	# Install Apache2 and other stuff needed to access svn via WebDav
	# Install svn
	# Installing utilities for SVNADMIN frontend
	# Create required folders
	# Create the authentication file for http access
RUN apk add --no-cache tini &&\
	apk add --no-cache apache2 apache2-ctl apache2-utils apache2-webdav mod_dav_svn &&\
	apk add --no-cache subversion &&\
	apk add --no-cache php84 php84-apache2 php84-session php84-ldap php84-xml &&\
	sed -i -e 's#^ErrorLog .*#ErrorLog /dev/stderr#' -e 's#^\(\s*CustomLog\) logs/access.log combined#\1 /dev/stdout combined env=!svn_dav#' /etc/apache2/httpd.conf &&\
	sed -i 's/^expose_php = On/expose_php = Off/' /etc/php84/php.ini &&\
	mkdir -p /run/apache2/ &&\
	mkdir /home/svn/ &&\
	mkdir /etc/subversion &&\
	touch /etc/subversion/passwd

COPY iF.SVNAdmin /opt/svnadmin

RUN ln -s /opt/svnadmin /var/www/localhost/htdocs/svnadmin &&\
	chown -R apache:apache /opt/svnadmin/data

# Add SVNAuth file
COPY subversion-access-control /etc/subversion/subversion-access-control
RUN chown -R apache:apache /etc/subversion /home/svn

# Add WebDav and SVNADMIN configuration
COPY dav_svn.conf /etc/apache2/conf.d/dav_svn.conf
COPY svnadmin.conf /etc/apache2/conf.d/svnadmin.conf

# Set HOME in non /root folder
ENV HOME=/home

# Expose ports for http access
EXPOSE 80 443

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# SIGWINCH makes Apache stop gracefully, letting in-flight commits finish
STOPSIGNAL SIGWINCH

ENTRYPOINT ["/sbin/tini", "--", "docker-entrypoint.sh"]
CMD ["httpd", "-DFOREGROUND"]
