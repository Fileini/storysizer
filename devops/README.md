# DevOps

Pipeline CI/CD e ambienti di sviluppo per StorySizer.

## Struttura

```
devops/
├── jenkins-pipelines/
│   ├── backend/
│   │   ├── backend-build-prod.groovy    # Build story-service + estimation-service
│   │   ├── backend-deploy-prod.groovy   # Deploy backend (rollout restart)
│   │   └── gateway-build-prod.groovy    # Build graphql-gateway
│   └── frontend/
│       ├── build-frontend-prod.groovy   # Build Flutter Web + push Docker
│       └── deploy-frontend-prod.groovy  # Deploy frontend (rollout restart)
└── remote-frontend-dev-environment/
    ├── Dockerfile                        # Immagine ambiente dev Flutter remoto
    └── README.md
```

## Pipeline Jenkins

Le pipeline sono scritte in Groovy (Jenkinsfile-style) e devono essere configurate manualmente nei job Jenkins (non usano Jenkinsfile da SCM automaticamente).

### Backend Build (`backend-build-prod.groovy`)
- Fa sparse checkout del repo (solo `backend/`)
- Compila entrambi i microservizi con Maven
- Builda le immagini Docker con `eclipse-temurin:17-jre-jammy` come base
- Push su Docker Hub (`fileini/storysizer-story-service:latest`, `fileini/storysizer-estimation-service:latest`)

### Backend Deploy (`backend-deploy-prod.groovy`)
- Fa `kubectl rollout restart` di story-service ed estimation-service nel namespace `service-prod`

### Gateway Build (`gateway-build-prod.groovy`)
- Checkout del repo (solo `graphql-gateway/`)
- Recupera il certificato TLS da un Secret Kubernetes e crea un truststore JKS
- Compila con Maven
- Builda l'immagine Docker
- Push su Docker Hub (`fileini/graphql-gateway:latest`)

### Frontend Build (`build-frontend-prod.groovy`)
- Sparse checkout (solo `frontend/storysizer/`)
- Build Flutter Web con `ghcr.io/cirruslabs/flutter:3.27.1`
- Builda immagine Docker Nginx con l'output
- Push su Docker Hub (`fileini/storysizer-web:latest`)

### Frontend Deploy (`deploy-frontend-prod.groovy`)
- Fa `kubectl rollout restart` di storysizer-web nel namespace `frontend-prod`

## Credenziali Jenkins richieste

| ID | Tipo | Usato da |
|----|------|---------|
| `dockerhub-credentials` | Username/Password | Tutte le pipeline di build |

## Flusso completo per rilascio backend

1. Push modifiche su `develop`
2. Avviare `backend-build-prod` in Jenkins
3. Quando la build è verde, avviare `backend-deploy-prod`
4. Verificare: `kubectl rollout status deployment/story-service -n service-prod`

## Flusso completo per rilascio gateway

1. Push modifiche su `develop`
2. Avviare `gateway-build-prod` in Jenkins
3. `kubectl rollout restart deployment/gateway-service -n service-prod`

## Note Importanti

- Le immagini base Docker usano `eclipse-temurin:17-jre-jammy` (non `openjdk:17-jdk-slim` che è deprecata)
- Il gateway richiede un truststore JKS per validare i certificati TLS di Keycloak
- Tutti gli endpoint `/actuator/health/**` devono essere liberi da autenticazione per le probe Kubernetes
