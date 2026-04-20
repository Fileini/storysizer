# Jenkins

Jenkins CI/CD per la build e il deploy dei componenti StorySizer.

## Configurazione

- **Namespace**: `jenkins`
- **Helm chart**: `jenkins/jenkins` v5.8.10 — release `jenkins` (revision 18)
- **Versione app**: Jenkins 2.492.1
- **URL (LAN)**: http://jenkins.storysizer.local
- **priorityClassName**: `application-standard`

## File

- `helm-values.yaml` — Helm values correnti (estratti con `helm get values`)

## Plugin installati

I plugin principali configurati nei values:
- `workflow-aggregator`, `pipeline-model-definition` — Pipeline
- `git`, `git-client` — Integrazione Git
- `kubernetes` — Agent su Kubernetes
- `docker-workflow`, `docker-commons` — Build Docker
- `credentials`, `credentials-binding` — Gestione credenziali

## Credenziali necessarie

| ID credenziale | Tipo | Usato da |
|---------------|------|---------|
| `dockerhub-credentials` | Username/Password | Tutte le pipeline (push immagini) |

## Upgrade

```bash
helm upgrade jenkins jenkins/jenkins -n jenkins --version 5.8.10 --reuse-values \
  --set controller.priorityClassName=application-standard
```

## RBAC

Jenkins usa un ServiceAccount con permessi per gestire pod nel cluster (per gli agent Kubernetes).
I file RBAC sono in `rbac/`.

## Note

- Gli agent Jenkins girano come pod temporanei nel cluster, usano il socket Docker dell'host per le build.
- Le pipeline sono definite in `devops/jenkins-pipelines/` e devono essere **copiate manualmente** nella configurazione dei job Jenkins (non usano Jenkinsfile da SCM automaticamente).
