# MetalLB

MetalLB fornisce IP di tipo LoadBalancer nel cluster k3s bare metal (che non ha un cloud provider).

## Configurazione

- **Namespace**: `metallb-system`
- **Helm chart**: `metallb/metallb` v0.14.9
- **Helm release**: `metallb` (revision 2)
- **Modalità**: Layer 2 (ARP)

## IP Pool

Pool definito nei CRD di MetalLB (applicato separatamente):

```
192.168.1.6 – 192.168.1.50
```

IP attualmente assegnati:
| IP | Servizio |
|----|---------|
| 192.168.1.30 | Traefik Admin (LoadBalancer) |

## File

- `helm-values.yaml` — Helm values usati per l'installazione/upgrade

## Upgrade

```bash
helm upgrade metallb metallb/metallb -n metallb-system --version 0.14.9 --reuse-values \
  --set controller.priorityClassName=system-cluster-critical \
  --set speaker.priorityClassName=system-cluster-critical
```

## Note

- Il **controller** gestisce l'assegnazione degli IP.
- Lo **speaker** annuncia gli IP via ARP sulla LAN (richiede privilegi `NET_ADMIN`, `NET_RAW`).
- `priorityClassName: system-cluster-critical` — deve avviarsi prima di tutto.
