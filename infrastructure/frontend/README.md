# Frontend — Manifesto Kubernetes

Deploy dell'applicazione Flutter Web in produzione.

## Configurazione

- **Namespace**: `frontend-prod`
- **Immagine**: `fileini/storysizer-web:latest`
- **Server**: Nginx alpine (porta 80)
- **URL**: https://app.storysizer.org
- **priorityClassName**: `application-standard`
- **Probes**: `GET /` su porta 80 (readiness + liveness)

## File

- `prod-frontend-manifest.yaml` — Deployment + Service + Ingress

## Comportamento Startup

Il frontend **non ha** init container bloccanti: se al boot il gateway non è ancora pronto, mostra temporaneamente errori, poi si recupera automaticamente quando le API tornano disponibili. Questo è intenzionale — il frontend è una SPA e gestisce gli errori lato client.

## Apply

```bash
kubectl apply -f frontend/prod-frontend-manifest.yaml
```

## Rollout restart (dopo nuova build)

```bash
kubectl rollout restart deployment/storysizer-web -n frontend-prod
kubectl rollout status deployment/storysizer-web -n frontend-prod
```

## Build

La build è gestita dalla pipeline Jenkins `build-frontend-prod`. Vedi [devops/jenkins-pipelines/](../../devops/jenkins-pipelines/).
