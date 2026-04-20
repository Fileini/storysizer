# Database

PostgreSQL condiviso tra i microservizi `story-service` ed `estimation-service`.

## Configurazione

- **Namespace**: `database`
- **Immagine**: `postgres:15`
- **Host interno**: `postgres.database.svc.cluster.local:5432`
- **Utente**: `admin`
- **priorityClassName**: `infrastructure-critical`

## File

- `microservices-postgres.yaml` — Deployment + Service + PVC

## Oggetti Kubernetes

| Risorsa | Nome | Note |
|---------|------|------|
| Deployment | `postgres` | 1 replica |
| Service | `postgres` | ClusterIP, porta 5432 |
| PVC | `postgres-pvc` | Persistenza dati |

## Probes

```yaml
startupProbe:   pg_isready -U admin  (attende max 5 min al boot)
readinessProbe: pg_isready -U admin  (ogni 10s)
livenessProbe:  pg_isready -U admin  (ogni 30s)
```

## Apply

```bash
kubectl apply -f database/microservices-postgres.yaml -n database
```

## Accesso diretto al database (debug)

```bash
kubectl exec -it -n database \
  $(kubectl get pod -n database -l app=postgres -o jsonpath="{.items[0].metadata.name}") \
  -- psql -U admin -d postgres
```

## Note

- Questo PostgreSQL è distinto da quello interno di Keycloak (che vive nel namespace `auth`).
- I microservizi usano l'init container `wait-for-postgres` che aspetta `postgres.database:5432` prima di avviarsi.
- Il PVC usa il StorageClass di default di k3s (local-path provisioner).

