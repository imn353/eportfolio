FROM jupyter/pyspark-notebook:spark-3.3.0

USER root

# Install Python dependencies
RUN pip install --no-cache-dir psycopg2-binary requests urllib3

# Download PostgreSQL JDBC driver so Spark can write to PostgreSQL
RUN wget -q -O /usr/local/spark/jars/postgresql-42.6.0.jar \
    https://jdbc.postgresql.org/download/postgresql-42.6.0.jar

USER ${NB_UID}
