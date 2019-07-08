FROM nginx:alpine
COPY src /usr/share/nginx/html
COPY conf.d /etc/nginx/conf.d
