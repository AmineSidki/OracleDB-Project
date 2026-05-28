FROM container-registry.oracle.com/database/express:21.3.0-xe

ENV ORACLE_PWD=oracle123
ENV ORACLE_CHARACTERSET=AL32UTF8

COPY init/ /container-entrypoint-initdb.d/
RUN sed -i 's/\r//' /container-entrypoint-initdb.d/*.sh && \
    chmod +x /container-entrypoint-initdb.d/*.sh

EXPOSE 1521 5500
