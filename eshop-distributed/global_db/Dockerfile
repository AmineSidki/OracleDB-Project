FROM container-registry.oracle.com/database/express:21.3.0-xe

ENV ORACLE_PWD=oracle123
ENV ORACLE_CHARACTERSET=AL32UTF8

COPY init/ /tmp/init-src/
RUN sed -i 's/\r//' /tmp/init-src/*.sh && \
    chmod +x /tmp/init-src/*.sh && \
    cp /tmp/init-src/*.sh /container-entrypoint-initdb.d/

EXPOSE 1521 5500
