# Traefik (Ingress Controller)

Sono presenti **due istanze** di Traefik con ruoli distinti.

## Traefik Admin

- **Namespace**: `ingress`
- **Helm chart**: `traefik/traefik` v34.3.0 — release `traefik-admin` (revision 4)
- **Tipo**: DaemonSet + LoadBalancer
- **IP**: `192.168.1.30` (assegnato da MetalLB)
- **IngressClass**: `traefik-admin` (default)
- **Scopo**: Traffico interno LAN — Jenkins, Keycloak admin, dashboard

```
LAN → 192.168.1.30 → Traefik Admin → Services interni
```

### Helm values: `admin-ingress-controller/helm-values.yaml`

## Traefik Public

- **Namespace**: `ingress`
- **Helm chart**: `traefik/traefik` v37.1.0 — release `traefik-public` (revision 4)
- **Tipo**: DaemonSet + ClusterIP
- **IngressClass**: `traefik-public`
- **Scopo**: Traffico Internet — raggiunto da cloudflared (Cloudflare Tunnel)

```
Internet → Cloudflare → cloudflared → traefik-public.ingress:443 → App
```

### Helm values: `public-ingress-controller/helm-values.yaml`

## Upgrade

```bash
# Admin
helm upgrade traefik-admin traefik/traefik -n ingress --version 34.3.0 --reuse-values \
  --set priorityClassName=system-cluster-critical

# Public
helm upgrade traefik-public traefik/traefik -n ingress --version 37.1.0 --reuse-values \
  --set priorityClassName=system-cluster-critical
```

## Note

- Entrambe le istanze hanno `priorityClassName: system-cluster-critical` — devono avviarsi subito dopo MetalLB.
- Il traffico pubblico passa **sempre** da Cloudflare Tunnel, non direttamente.
- L'API dashboard è abilitata (`--api=true`, `--api.insecure=true`) ma accessibile solo internamente.
