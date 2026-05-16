# StorySizer

StorySizer è una web app per la gestione e stima delle storie utente (story pointing). Gli utenti si autenticano tramite Keycloak, interagiscono con un GraphQL gateway che orchestra due microservizi backend, e visualizzano il tutto tramite un frontend Flutter Web.

## Stack Tecnologico

| Layer | Tecnologia |
|-------|-----------|
| Frontend | Flutter Web → Nginx alpine |
| API Gateway | Spring Boot 3.4 + GraphQL + OAuth2/JWT |
| Backend | Spring Boot 3.4, Java 17 (story-service, estimation-service, group-service) |
| Database | PostgreSQL 15 |
| Auth | Keycloak 26.3 (Bitnami Helm) |
| Cluster | k3s single-node bare metal (`fraserver`) |
| Ingress | Traefik v3 (due istanze: admin + public) |
| LB | MetalLB (pool 192.168.1.6–192.168.1.50) |
| Tunnel | Cloudflare Tunnel (cloudflared) |
| CI/CD | Jenkins su Kubernetes |

## Struttura del Repository

```
/
├── frontend/storysizer/     # App Flutter Web
├── backend/
│   ├── story-service/       # Microservizio gestione storie (Spring Boot)
│   ├── estimation-service/  # Microservizio stime (Spring Boot)
│   └── group-service/       # Microservizio gruppi + stime collaborative + inviti email
├── graphql-gateway/         # API Gateway GraphQL (Spring Boot)
├── infrastructure/          # Manifesti Kubernetes e Helm values
├── devops/                  # Pipeline Jenkins e ambienti di sviluppo
├── docs/                    # Diagrammi infrastruttura
├── design/                  # Asset di design (Figma export)
└── hardware/                # Documentazione server fisico e rete
```

## URL Produzione

| Servizio | URL |
|---------|-----|
| App frontend | https://app.storysizer.org |
| GraphQL API | https://api.storysizer.org/graphql |
| Keycloak | https://auth.storysizer.org |
| Jenkins (LAN) | http://jenkins.storysizer.local |

## Flusso del Traffico

```
Internet → Cloudflare → cloudflared (tunnel) → Traefik Public → Services
LAN      → Traefik Admin (192.168.1.30)      → Services interni
```

## Sviluppo Locale

### Backend (Spring Boot)
```bash
cd backend/story-service
./mvnw spring-boot:run
```

### Frontend (Flutter)
```bash
cd frontend/storysizer
flutter run -d chrome
```

### Gateway
```bash
cd graphql-gateway
./mvnw spring-boot:run
```

## Diagrammi

La cartella [docs/infrastructure-diagram/](docs/infrastructure-diagram/) contiene i diagrammi dell'infrastruttura:

| File | Contenuto |
|------|-----------|
| [storysizer-infrastructure-complete.drawio](docs/infrastructure-diagram/storysizer-infrastructure-complete.drawio) | Diagramma completo (draw.io) — cluster, rete, servizi, tunnel |
| [storysizerinfrastructure.drawio](docs/infrastructure-diagram/storysizerinfrastructure.drawio) | Versione precedente del diagramma |
| [storysizerinfrastructure.drawio.svg](docs/infrastructure-diagram/storysizerinfrastructure.drawio.svg) | Export SVG — visualizzabile direttamente nel browser |

Per aprire i file `.drawio`: [draw.io](https://app.diagrams.net/) (File → Open from → Device).

## Deploy Produzione

Il deploy avviene tramite pipeline Jenkins (vedi [devops/README.md](devops/README.md)):

1. Push su branch `develop`
2. Avviare manualmente il job Jenkins corrispondente
3. La pipeline compila, builda l'immagine Docker, fa push su Docker Hub
4. Fare `kubectl rollout restart` o usare il deploy pipeline

Per l'infrastruttura Kubernetes vedi [infrastructure/README.md](infrastructure/README.md).