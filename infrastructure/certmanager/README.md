# cert-manager

cert-manager gestisce automaticamente i certificati TLS tramite Let's Encrypt con DNS challenge su Cloudflare.

## Configurazione

- **Namespace**: `cert-manager`
- **Helm chart**: `jetstack/cert-manager` v1.12.0
- **Challenge type**: DNS-01 via Cloudflare API

## File

| File | Scopo |
|------|-------|
| `cloudflare-clusterissuer.yaml` | ClusterIssuer per Let's Encrypt produzione via Cloudflare |
| `selfsigned-clusterissuer.yaml` | ClusterIssuer self-signed (per uso interno/test) |
| `cert-admin-ingress-self-signed.yaml` | Certificato self-signed per ingress admin (LAN) |
| `cert-public-ingress-self-signed.yaml` | Certificato per ingress public |

## Come funziona

1. cert-manager riceve una richiesta di certificato (tramite annotazioni Ingress o oggetti `Certificate`)
2. Crea un record DNS TXT su Cloudflare tramite API per verificare il dominio
3. Let's Encrypt valida il challenge e rilascia il certificato
4. Il certificato viene salvato in un Secret Kubernetes e rinnovato automaticamente

## Secret Cloudflare API

Per il DNS challenge è necessario il token API Cloudflare:

```bash
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token='<token>' \
  -n cert-manager
```

## Nota

Il traffico pubblico usa certificati Let's Encrypt (trusted dai browser). Il traffico LAN admin usa certificati self-signed (accettare l'eccezione nel browser o installare la CA).
