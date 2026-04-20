# Keycloak

Keycloak è il provider di autenticazione e autorizzazione per StorySizer.

## Configurazione

- **Namespace**: `auth`
- **Helm chart**: `bitnami/keycloak` v25.2.0 — release `keycloak` (revision 18)
- **Versione app**: Keycloak 26.3.3
- **URL**: https://auth.storysizer.org
- **Realm**: `storysizer`
- **priorityClassName**: `infrastructure-critical`

## Database

Keycloak usa il suo PostgreSQL interno (gestito dal chart Bitnami), separato dal PostgreSQL dei microservizi.

## File

| File | Scopo |
|------|-------|
| `bitnami/bitnami-helm-values.yaml` | Helm values per installazione/upgrade |
| `keycloak-ingress.yaml` | Ingress per esporre Keycloak via Traefik Admin |
| `secretcreate.sh` | Script per creare il Secret con le credenziali admin |
| `old-codecentric/` | Vecchia installazione (ora deprecata, non usare) |

## Secret

Le credenziali admin sono in un Secret Kubernetes nel namespace `auth`.
Per crearlo/aggiornarlo:

```bash
kubectl create secret generic keycloak-creds \
  --from-literal=user='<admin-user>' \
  --from-literal=password='<admin-password>' \
  -n auth
```

## Upgrade

```bash
helm upgrade keycloak bitnami/keycloak -n auth --version 25.2.0 --reuse-values \
  --set priorityClassName=infrastructure-critical
```

## Dipendenze

- Richiede che il suo PostgreSQL interno sia pronto (gestito automaticamente dal chart)
- Il `gateway-service` aspetta Keycloak via init container (controlla `/realms/storysizer/.well-known/openid-configuration`)

## Note

- `production: true` — abilita HTTPS-only e header sicuri
- `proxy: edge` — Keycloak si fida degli header X-Forwarded-For da Traefik
- Il certificato TLS è gestito da cert-manager tramite Cloudflare DNS challenge
