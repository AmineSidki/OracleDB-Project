FROM container-registry.oracle.com/database/express:21.3.0-xe

ENV ORACLE_PWD=oracle123
ENV ORACLE_CHARACTERSET=AL32UTF8

COPY init/ /container-entrypoint-initdb.d/
RUN find /container-entrypoint-initdb.d/ -name "*.sql" -delete

EXPOSE 1521 5500
