# Alpine Linux with s6 service management
FROM alpine:3.24

ARG S6_OVERLAY_VERSION=v3.2.3.2

# Add s6-overlay
RUN apk add --no-cache --virtual .s6-deps curl xz &&\
	case "$(apk --print-arch)" in \
		x86_64) S6_ARCH=x86_64 ;; \
		aarch64) S6_ARCH=aarch64 ;; \
		armv7) S6_ARCH=armhf ;; \
		*) echo "Unsupported arch: $(apk --print-arch)" && exit 1 ;; \
	esac &&\
	curl -fsSL https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz | tar Jxpf - -C / &&\
	curl -fsSL https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz | tar Jxpf - -C / &&\
	apk del .s6-deps

	# Install Apache2 and other stuff needed to access svn via WebDav
	# Install svn
	# Installing utilities for SVNADMIN frontend
	# Create required folders
	# Create the authentication file for http access
RUN apk add --no-cache apache2 apache2-ctl apache2-utils apache2-webdav mod_dav_svn &&\
	apk add --no-cache subversion &&\
	apk add --no-cache php84 php84-apache2 php84-session php84-ldap php84-xml &&\
	sed -i 's/^expose_php = On/expose_php = Off/' /etc/php84/php.ini &&\
	mkdir -p /run/apache2/ &&\
	mkdir /home/svn/ &&\
	mkdir /etc/subversion &&\
	touch /etc/subversion/passwd

COPY iF.SVNAdmin /opt/svnadmin

RUN ln -s /opt/svnadmin /var/www/localhost/htdocs/svnadmin &&\
	chown -R apache:apache /opt/svnadmin/data

# Add services configurations
COPY apache/ /etc/services.d/apache/
COPY subversion/ /etc/services.d/subversion/

# Add SVNAuth file
COPY subversion-access-control /etc/subversion/subversion-access-control
RUN chown -R apache:apache /etc/subversion /home/svn

# Add WebDav and SVNADMIN configuration
COPY dav_svn.conf /etc/apache2/conf.d/dav_svn.conf
COPY svnadmin.conf /etc/apache2/conf.d/svnadmin.conf

# Set HOME in non /root folder
ENV HOME=/home

# Expose ports for http and custom protocol access
EXPOSE 80 443 3690

ENTRYPOINT ["/init"]
