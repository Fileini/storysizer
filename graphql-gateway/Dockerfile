FROM openjdk:17-jdk-slim

WORKDIR /app

# Copia il truststore nella directory di lavoro
COPY truststore.jks /app/truststore.jks

# Copia il jar dell'applicazione
COPY target/graphql-gateway-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 9090

# Imposta l'ENTRYPOINT con le proprietà per il truststore
ENTRYPOINT ["java", "-Djavax.net.ssl.trustStore=/app/truststore.jks", "-Djavax.net.ssl.trustStorePassword=changeit", "-jar", "app.jar"]
