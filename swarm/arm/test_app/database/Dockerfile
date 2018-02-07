FROM postgres

ENV POSTGRES_DB cluster_test_app

COPY schema.sql /docker-entrypoint-initdb.d/
