# Remote Flutter Dev Environment

Ambiente di sviluppo Flutter remoto che gira come pod nel cluster Kubernetes. Permette al developer di lavorare da qualsiasi macchina connettendosi via SSH.

## Come funziona

```
Developer (VS Code / IDE) ──SSH──► pod nel cluster (flutter installato)
                                        │
                                        └─► codice su volume montato
```

Il pod espone la porta SSH 22 via un Service di tipo LoadBalancer, così il developer si collega direttamente all'ambiente con Flutter, Git, e tutto il necessario già installato.

## Immagine Docker

Basata su `debian:bullseye-slim` con:
- OpenSSH server
- Git
- Flutter SDK (da installare al primo avvio o in un'immagine derivata)
- curl, unzip e dipendenze Flutter

**Utente di default**: `dev` / `dev` (cambiare in produzione)

## Build immagine

```bash
docker build -t fileini/flutter-devenv:latest .
docker push fileini/flutter-devenv:latest
```

## Deploy nel cluster

Il manifesto di deploy è in `infrastructure/` (namespace `frontend-dev`). Il Service espone la porta 22 via MetalLB.

## Connessione

```bash
ssh dev@<IP-assegnato-da-MetalLB> -p 22
```

Per VS Code Remote SSH, aggiungere in `~/.ssh/config`:
```
Host flutter-dev
  HostName <IP-assegnato>
  User dev
  Port 22
```

## Note

- Questo ambiente è pensato per sviluppo/test, non per produzione.
- Il namespace `frontend-dev` può contenere anche una versione di sviluppo del frontend.
- La password SSH deve essere impostata tramite variabile di build o sostituita con chiave pubblica.
