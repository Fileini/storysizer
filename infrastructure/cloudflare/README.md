# Cloudflare Tunnel (cloudflared)

Cloudflare Tunnel espone l'applicazione su Internet senza aprire porte nel router/firewall.

## Come funziona

```
Utente Internet
  → Cloudflare CDN/proxy
  → Cloudflare Tunnel (connessione uscente dal cluster)
  → cloudflared (pod nel cluster)
  → Traefik Public (traefik-public.ingress.svc.cluster.local:443)
  → Applicazione
```

Il cluster stabilisce una connessione **uscente** verso Cloudflare — nessuna porta deve essere aperta in ingresso.

## Configurazione

- **Namespace**: `cloudflared`
- **Immagine**: `cloudflare/cloudflared:latest`
- **priorityClassName**: `application-standard`
- **Init container**: `wait-for-tcp` — aspetta che `traefik-public.ingress:443` sia raggiungibile
- **Probes**: `GET /ready` su porta 2000

## File

| File | Scopo |
|------|-------|
| `cloudflared-deploy.yaml` | Deployment + ServiceAccount + ConfigMap con tunnel config |
| `cloudflared-config.yaml` | Configurazione del tunnel (hostname routing) |

## Secret

Il tunnel richiede un Secret con il token di autenticazione Cloudflare:

```bash
# Il token viene generato nella dashboard Cloudflare (Zero Trust → Tunnels)
kubectl create secret generic cloudflare-tunnel-token \
  --from-literal=token='<tunnel-token>' \
  -n cloudflared
```

## Apply

```bash
kubectl apply -f cloudflare/cloudflared-deploy.yaml
```

## Note

- Se cloudflared si avvia prima che Traefik Public sia pronto, l'init container lo blocca finché il servizio non è disponibile.
- La configurazione del routing (quale hostname va a quale service) è in `cloudflared-config.yaml`.
- Il traffico HTTPS viene terminato da Traefik con i certificati cert-manager.
