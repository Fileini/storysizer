# Backend — Manifesti Kubernetes

Manifesti di deploy per i tre componenti backend in produzione.

## Struttura

```
backend/
├── story-service/
│   └── prod-story-service-manifest.yaml
├── estimation-service/
│   └── prod-estimation-service-manifest.yaml
└── graphql-gateway/
    └── prod-graphql-gateway-manifest.yaml
```

## story-service

- **Namespace**: `service-prod`
- **Immagine**: `fileini/storysizer-story-service:latest`
- **Porta**: 8080
- **Database**: PostgreSQL su `postgres.database.svc.cluster.local:5432`
- **Init container**: `wait-for-postgres` — aspetta che PostgreSQL sia pronto
- **Probes**: `/actuator/health/readiness` su porta 8080

## estimation-service

- **Namespace**: `service-prod`
- **Immagine**: `fileini/storysizer-estimation-service:latest`
- **Porta**: 8080
- **Database**: stesso PostgreSQL di story-service
- **Init container**: `wait-for-postgres`
- **Probes**: `/actuator/health/readiness` su porta 8080

## graphql-gateway

- **Namespace**: `service-prod`
- **Immagine**: `fileini/graphql-gateway:latest`
- **Porta**: 9090
- **Auth**: OAuth2/JWT via Keycloak (`auth.storysizer.org`, realm `storysizer`)
- **Init container**: `wait-for-keycloak` — aspetta l'OIDC endpoint di Keycloak
- **Probes**: `/actuator/health/readiness` su porta 9090
- **Ingress**: `api.storysizer.org` via Traefik Public

## Attenzione — Spring Security e Probes

Il gateway usa Spring Security con OAuth2. Gli endpoint `/actuator/health/**` devono essere esplicitamente esclusi dall'autenticazione in `SecurityConfig.java`, altrimenti le probe Kubernetes ricevono HTTP 401 e il pod non diventa mai Ready.

## Apply

```bash
# Tutti e tre insieme
kubectl apply -f backend/story-service/prod-story-service-manifest.yaml
kubectl apply -f backend/estimation-service/prod-estimation-service-manifest.yaml
kubectl apply -f backend/graphql-gateway/prod-graphql-gateway-manifest.yaml

# Rollout restart dopo nuova build Docker
kubectl rollout restart deployment/story-service deployment/estimation-service deployment/gateway-service -n service-prod
```

## ConfigMap wait-scripts

Gli init container usano script da un ConfigMap che deve essere presente nel namespace:

```bash
kubectl apply -f common/wait-scripts-configmap.yaml -n service-prod
```
