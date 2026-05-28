FROM container-registry.oracle.com/database/express:21.3.0-xe

ENV ORACLE_PWD=oracle123
ENV ORACLE_CHARACTERSET=AL32UTF8
ENV APP_USER=site1
ENV APP_USER_PASSWORD=site1123

COPY init/ /container-entrypoint-initdb.d/

EXPOSE 1521 5500
