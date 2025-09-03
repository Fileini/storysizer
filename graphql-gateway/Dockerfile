FROM eclipse-temurin:17-jre-jammy

WORKDIR /app



# Copia il jar dell'applicazione
COPY target/graphql-gateway-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 9090

# Imposta l'ENTRYPOINT con le proprietà per il truststore
ENTRYPOINT ["java","-jar","/app/app.jar"]
