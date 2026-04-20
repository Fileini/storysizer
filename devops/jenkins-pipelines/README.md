# Jenkins Pipelines

Pipeline Groovy per la build e il deploy di tutti i componenti StorySizer.

> **Nota**: Le pipeline sono copiate manualmente nella configurazione dei job Jenkins (sezione "Pipeline script"). Non usano Jenkinsfile da SCM.

## Struttura

```
jenkins-pipelines/
├── backend/
│   ├── backend-build-prod.groovy    # Build story-service + estimation-service
│   ├── backend-deploy-prod.groovy   # Deploy backend (rollout restart)
│   └── gateway-build-prod.groovy    # Build graphql-gateway
└── frontend/
    ├── build-frontend-prod.groovy   # Build Flutter Web + push Docker
    └── deploy-frontend-prod.groovy  # Deploy frontend (rollout restart)
```

---

## backend-build-prod.groovy

**Scopo**: Compila e pubblica le immagini Docker di `story-service` ed `estimation-service`.

**Agent pod**:
- `maven:3.8.5-openjdk-17` — build Maven
- `docker:20.10.7` — build/push immagine Docker (monta `/var/run/docker.sock`)

**Stage**:
1. **Sparse Checkout** — clona solo `backend/` dal branch `develop`
2. **Build Microservices** — per ogni servizio in `backend/`:
   - `mvn clean package -DskipTests -B -T 1C`
   - Genera un Dockerfile inline (`FROM eclipse-temurin:17-jre-jammy`)
   - Build + push immagine `fileini/<service-name>:latest`

**Immagini prodotte**:
- `fileini/storysizer-story-service:latest`
- `fileini/storysizer-estimation-service:latest`

**Credenziali richieste**: `dockerhub-credentials`

---

## backend-deploy-prod.groovy

**Scopo**: Aggiorna i pod backend in produzione dopo una nuova build.

**Agent pod**: `lachlanevenson/k8s-kubectl:latest` con `serviceAccountName: jenkins`

**Stage**:
1. **Clean old deploy** — esegue:
   ```bash
   kubectl rollout restart deployment story-service -n service-prod
   kubectl rollout restart deployment estimation-service -n service-prod
   ```

**Nota**: Il nome dello stage è "Clean old deploy" per motivi storici, ma in realtà fa un rolling restart — non cancella nulla.

---

## gateway-build-prod.groovy

**Scopo**: Compila e pubblica l'immagine Docker del `graphql-gateway`.

**Agent pod** (multi-container):
- `lachlanevenson/k8s-kubectl:latest` — recupera il certificato TLS da Kubernetes
- `eclipse-temurin:17-jdk-jammy` — crea il truststore JKS con `keytool`
- `maven:3.9.9-eclipse-temurin-17` — build Maven
- `docker:20.10.16` — build/push immagine Docker

**Stage**:
1. **Checkout** — clone completo del repo (`develop`)
2. **Prepare Truststore**:
   - Legge il Secret `wildcard-public-cluster-tls` dal namespace `frontend-prod`
   - Estrae `ca.crt` e lo importa in un truststore JKS (`truststore.jks`, password `changeit`)
   - Copia `truststore.jks` nella directory `graphql-gateway/`
3. **Build Maven** — `mvn clean package -DskipTests` in `graphql-gateway/`
4. **Build Docker Image** — usa il Dockerfile del progetto
5. **Push Docker Image** — push di `fileini/graphql-gateway:latest`

**Post**: tenta `chmod -R u+w .` + `deleteDir()` per pulizia workspace (errori ignorati).

**Immagine prodotta**: `fileini/graphql-gateway:latest`

**Credenziali richieste**: `dockerhub-credentials`

**Perché il truststore?** Il gateway usa OAuth2 Resource Server e valida i JWT contro il JWKS endpoint di Keycloak (`auth.storysizer.org`). Poiché Keycloak usa un certificato TLS da Let's Encrypt / self-signed, il truststore JKS è necessario perché la JVM si fidi di quel certificato.

---

## build-frontend-prod.groovy

**Scopo**: Compila Flutter Web e pubblica l'immagine Docker del frontend.

**Agent pod** (agent separati per stage):
- `ghcr.io/cirruslabs/flutter:3.27.1` — checkout e build Flutter
- `docker:24.0-dind` (Docker-in-Docker, privileged) — build/push immagine

**Stage**:
1. **Checkout Flutter Web** — sparse checkout di `frontend/storysizer/**` da `develop`, poi `stash`
2. **Build Flutter Web**:
   - `flutter pub get`
   - `flutter build web --release`
   - stash dell'output in `frontend/storysizer/build/web/`
3. **Build & Push Docker Image**:
   - `unstash` del build
   - Crea contesto Docker con l'output web
   - Build immagine con Nginx
   - Push di `fileini/storysizer-web:latest`

**Immagine prodotta**: `fileini/storysizer-web:latest`

**Credenziali richieste**: `dockerhub-credentials`

---

## deploy-frontend-prod.groovy

**Scopo**: Aggiorna il pod frontend in produzione dopo una nuova build.

**Agent pod**: `lachlanevenson/k8s-kubectl:latest` con `serviceAccountName: jenkins`

**Stage**:
1. **Clean old deploy** — esegue:
   ```bash
   kubectl rollout restart deployment storysizer-web -n frontend-prod
   ```

---

## Flusso di rilascio

### Backend completo

```
backend-build-prod  →  backend-deploy-prod
```

### Gateway

```
gateway-build-prod  →  kubectl rollout restart deployment/gateway-service -n service-prod
```
(Il deploy del gateway non ha una pipeline separata — si fa manualmente o si aggiunge un job.)

### Frontend

```
build-frontend-prod  →  deploy-frontend-prod
```

## Configurazione Jenkins

Per usare una pipeline:
1. **New Item** → Pipeline
2. Incollare il contenuto del file `.groovy` nella sezione **Pipeline script**
3. Aggiungere le credenziali: **Manage Jenkins → Credentials** → `dockerhub-credentials` (Username with password)
