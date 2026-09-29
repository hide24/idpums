FROM rockylinux/rockylinux:9

ARG HOST_NAME

RUN yum -y update \
    && yum -y install httpd mod_ssl mod_ldap \
    && yum -y clean all

COPY httpd-foreground /usr/local/bin/
COPY conf/httpd.conf /etc/httpd/conf.d/
COPY conf/ssl.conf /etc/httpd/conf.d/
RUN sed -i -e "s/__host_name__/$HOST_NAME/" /etc/httpd/conf.d/httpd.conf

RUN chmod +x /usr/local/bin/httpd-foreground

EXPOSE 80 443

CMD ["httpd-foreground"]

