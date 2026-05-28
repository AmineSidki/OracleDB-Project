FROM container-registry.oracle.com/database/express:21.3.0-xe

ENV ORACLE_PWD=oracle123
ENV ORACLE_CHARACTERSET=AL32UTF8
ENV APP_USER=eshop
ENV APP_USER_PASSWORD=eshop123

COPY init/ /opt/oracle/scripts/setup/

EXPOSE 1521 5500
