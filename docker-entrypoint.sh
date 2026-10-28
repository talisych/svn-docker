#!/bin/sh
set -e

# Avoid 'httpd (pid N) already running' after the container is restarted
rm -f /run/apache2/httpd.pid

exec "$@"
