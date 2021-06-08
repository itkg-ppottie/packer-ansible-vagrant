FROM nginx
COPY nginx.conf /etc/nginx/nginx.conf
COPY .htpasswd /usr/share/nginx/html/.htpasswd

RUN chmod o+r  /usr/share/nginx/html/.htpasswd
