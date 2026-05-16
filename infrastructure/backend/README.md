# Backend — Manifesti Kubernetes

Manifesti di deploy per i componenti backend in produzione.

## Struttura

```
backend/
├── story-service/
│   └── prod-story-service-manifest.yaml
├── estimation-service/
│   └── prod-estimation-service-manifest.yaml
├── graphql-gateway/
│   └── prod-graphql-gateway-manifest.yaml
└── group-service/
    ├── prod-group-service-manifest.yaml
    ├── create-group-db-job.yaml        # Job idempotente per creare DB e utente
    └── secretcreate.sh                 # Script per creare groups-db-secret
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

## group-service

- **Namespace**: `service-prod`
- **Immagine**: `fileini/group-service:latest`
- **Porta**: 8080
- **Database**: PostgreSQL dedicato (`groupsdb`) — credenziali in `groups-db-secret`
- **Init container**: `wait-for-postgres`
- **Probes**: `/actuator/health/readiness` su porta 8080
- **Accesso**: solo interno al cluster (`ClusterIP`), nessuna rotta Traefik pubblica
- **Secret**: `groups-db-secret` — contiene le credenziali DB + Resend API key + APP_BASE_URL

### Prima installazione di group-service

```bash
# 1. Copia microservices-postgres-secret nel namespace service-prod
#    (il Job ne ha bisogno ma il secret si trova nel namespace 'database')
kubectl get secret microservices-postgres-secret -n database -o json \
  | jq 'del(.metadata.resourceVersion,.metadata.uid,.metadata.creationTimestamp,.metadata.annotations) | .metadata.namespace="service-prod"' \
  | kubectl apply -f -

# 2. Crea il secret con le credenziali del nuovo DB (compilare i valori reali)
bash backend/group-service/secretcreate.sh

# 3. Crea DB e utente PostgreSQL
kubectl apply -f backend/group-service/create-group-db-job.yaml

# 4. Deploy del servizio
kubectl apply -f backend/group-service/prod-group-service-manifest.yaml
```

Vedi [backend/group-service/README.md](../../backend/group-service/README.md) per la documentazione del servizio, incluso il flusso di invito email.

## Attenzione — Spring Security e Probes

Il gateway usa Spring Security con OAuth2. Gli endpoint `/actuator/health/**` devono essere esplicitamente esclusi dall'autenticazione in `SecurityConfig.java`, altrimenti le probe Kubernetes ricevono HTTP 401 e il pod non diventa mai Ready.

## Apply

```bash
# Tutti i servizi
kubectl apply -f backend/story-service/prod-story-service-manifest.yaml
kubectl apply -f backend/estimation-service/prod-estimation-service-manifest.yaml
kubectl apply -f backend/graphql-gateway/prod-graphql-gateway-manifest.yaml
kubectl apply -f backend/group-service/prod-group-service-manifest.yaml

# Rollout restart dopo nuova build Docker
kubectl rollout restart deployment/story-service deployment/estimation-service deployment/gateway-service deployment/group-service -n service-prod
```

## ConfigMap wait-scripts

Gli init container usano script da un ConfigMap che deve essere presente nel namespace:

```bash
kubectl apply -f common/wait-scripts-configmap.yaml -n service-prod
```
