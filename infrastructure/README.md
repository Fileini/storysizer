# Infrastructure

Questa cartella contiene tutti i manifesti Kubernetes e i Helm values per il cluster k3s di produzione (`fraserver`).

## Struttura

```
infrastructure/
├── priority-classes.yaml          # PriorityClasses per lo scheduling
├── apply-in-order.sh              # Script disaster recovery
├── common/
│   └── wait-scripts-configmap.yaml  # Script di wait per init containers
├── metallb/                       # Helm values MetalLB
├── treaefik/                      # Helm values Traefik (admin + public)
├── certmanager/                   # Manifesti cert-manager
├── keycloak/                      # Helm values + ingress Keycloak
├── database/                      # Manifesto PostgreSQL microservizi
├── backend/                       # Manifesti story-service, estimation-service, gateway
├── frontend/                      # Manifesto frontend Flutter Web
├── cloudflare/                    # Manifesto cloudflared tunnel
└── jenkins/                       # Helm values Jenkins
```

## Cluster Overview

- **Tipo**: k3s single-node bare metal
- **Nodo**: `fraserver` (192.168.1.6)
- **Traefik Admin**: LoadBalancer su 192.168.1.30 — traffico LAN interno
- **Traefik Public**: ClusterIP — raggiunto da cloudflared per traffico Internet
- **MetalLB**: pool IP 192.168.1.6–192.168.1.50

## Namespaces

| Namespace | Contenuto |
|-----------|-----------|
| `metallb-system` | MetalLB controller + speaker |
| `ingress` | Traefik Admin + Traefik Public |
| `cert-manager` | cert-manager |
| `auth` | Keycloak + PostgreSQL interno |
| `database` | PostgreSQL condiviso per i microservizi |
| `service-prod` | story-service, estimation-service, gateway-service |
| `frontend-prod` | storysizer-web (Flutter/Nginx) |
| `cloudflared` | Cloudflare Tunnel |
| `jenkins` | Jenkins CI/CD |

---

# Startup Ordering (Bare Metal)

Dopo un reboot del nodo, i servizi devono avviarsi in ordine. Il meccanismo è:

1. **PriorityClasses** — schedulano i pod critici prima degli altri
2. **Init Containers** — i servizi attendono le dipendenze prima di avviarsi
3. **Readiness/Liveness/Startup Probes** — Kubernetes gestisce traffico e restart

## Catena di Dipendenze

```
MetalLB (system-cluster-critical)
  ↓
Traefik Admin + Public (system-cluster-critical)
  ↓
cert-manager
  ↓
PostgreSQL microservizi (infrastructure-critical)
  ↓
Keycloak (infrastructure-critical)
  ↓
Jenkins (application-standard) ──────────────────┐
story-service (attende postgres via init container) │ paralleli
estimation-service (attende postgres)              │
gateway-service (attende Keycloak OIDC)            │
  ↓                                                │
cloudflared (attende traefik-public:443)           │
  ↓                                                │
Frontend (nessuna dipendenza bloccante) ◄──────────┘
```

## PriorityClasses Definite

| Nome | Valore | Usato da |
|------|--------|---------|
| `system-cluster-critical` | 2000000000 | (built-in k8s) MetalLB, Traefik |
| `infrastructure-critical` | 1000000 | PostgreSQL, Keycloak |
| `application-standard` | 100 (default) | Tutti gli altri |

## Init Containers

| Pod | Init Container | Attende |
|-----|---------------|---------|
| story-service | `wait-for-postgres` | `postgres.database:5432` (TCP) |
| estimation-service | `wait-for-postgres` | `postgres.database:5432` (TCP) |
| gateway-service | `wait-for-keycloak` | `https://auth.storysizer.org/realms/storysizer/.well-known/openid-configuration` |
| cloudflared | `wait-for-tcp` | `traefik-public.ingress:443` (TCP) |

Gli script sono nel ConfigMap `wait-scripts` nei rispettivi namespace (database, service-prod, cloudflared).

---

# Disaster Recovery

Se è necessario riapplicare tutto da zero in ordine:

```bash
cd infrastructure/
./apply-in-order.sh              # Applica tutto in ordine
./apply-in-order.sh --dry-run    # Solo verifica, nessuna modifica
./apply-in-order.sh --skip-helm  # Salta gli upgrade Helm
```

## Comandi Utili

```bash
# Stato generale
kubectl get pods -A
kubectl get priorityclass

# Verifica che i pod abbiano la priorityClass giusta
kubectl get pod <nome> -n <ns> -o jsonpath='{.spec.priorityClassName}'

# Debug init container bloccato
kubectl logs <pod> -c wait-for-postgres -n service-prod
kubectl logs <pod> -c wait-for-keycloak -n service-prod

# Stato rollout
kubectl rollout status deployment/<nome> -n <namespace>

# Helm releases
helm list -A
```

## Helm Upgrades

Per aggiungere la priorityClass a un componente Helm senza toccare la config:

```bash
# MetalLB
helm upgrade metallb metallb/metallb -n metallb-system --version 0.14.9 --reuse-values \
  --set controller.priorityClassName=system-cluster-critical \
  --set speaker.priorityClassName=system-cluster-critical

# Traefik
helm upgrade traefik-admin traefik/traefik -n ingress --version 34.3.0 --reuse-values \
  --set priorityClassName=system-cluster-critical

# Keycloak
helm upgrade keycloak bitnami/keycloak -n auth --version 25.2.0 --reuse-values \
  --set priorityClassName=infrastructure-critical

# Jenkins
helm upgrade jenkins jenkins/jenkins -n jenkins --version 5.8.10 --reuse-values \
  --set controller.priorityClassName=application-standard
```

---

# Componenti Dettaglio

Vedi le sottocartelle per i dettagli di ogni componente:

- [metallb/](metallb/) — IP pool e Helm values MetalLB
- [treaefik/](treaefik/) — Configurazione Traefik Admin e Public
- [keycloak/](keycloak/) — Keycloak Bitnami, ingress, secret
- [database/](database/) — PostgreSQL per i microservizi
- [backend/](backend/) — Manifesti story-service, estimation-service, gateway
- [frontend/](frontend/) — Manifesto storysizer-web
- [cloudflare/](cloudflare/) — Cloudflare Tunnel
- [jenkins/](jenkins/) — Jenkins Helm values
- [certmanager/](certmanager/) — Certificati TLS
