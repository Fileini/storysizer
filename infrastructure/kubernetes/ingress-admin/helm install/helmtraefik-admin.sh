helm upgrade --install traefik-admin traefik/traefik \
  --namespace ingress \
  --create-namespace \
  --set ingressClass.enabled=true \
  --set podLabels.app=traefik-admin \
  --set crds.enabled=true \
  --set ingressClass.name=traefik-admin \
  --set ingressClass.isDefaultClass=false \
  --set service.type=LoadBalancer \
  --set dashboard.enabled=true \
  --set ports.web.port=80 \
  --set ports.websecure-adm.port=443 \
  --set metrics.prometheus.enabled=true \
  --set additionalArguments[0]="--providers.kubernetescrd" \
  --set additionalArguments[1]="--api.insecure=true" \
  --set additionalArguments[2]="--api.dashboard=true" \
  --set additionalArguments[3]="--entrypoints.traefik.address=:8080" \
  --set additionalArguments[4]="--entrypoints.websecure-adm.address=:443" \
  --set providers.kubernetesIngress.ingressEndpoint.publishedService="ingress/cleatraefik-admin" \
  --set providers.kubernetesIngress.ingressClass=traefik-admin \

