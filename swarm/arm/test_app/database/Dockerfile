FROM postgres

ENV POSTGRES_DB cluster_test

COPY schema.sql /docker-entrypoint-initdb.d/
