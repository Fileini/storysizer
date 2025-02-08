kubectl patch service traefik-admin -n ingress -p '{"spec":{"loadBalancerIP":"192.168.1.30"}}'

kubectl patch svc traefik-admin -n ingress -p '{
  "spec": {
    "ports": [
      {
        "name": "traefik",
        "port": 8080,
        "targetPort": 8080,
        "protocol": "TCP"
      }
    ]
  }
}'


kubectl annotate ingressclass traefik-admin ingressclass.kubernetes.io/is-default-class-

kubectl patch deployment traefik-admin -n ingress -p '{"spec": {"template": {"metadata": {"labels": {"app": "traefik-admin"}}}}}'

kubectl rollout restart deployment traefik-admin -n ingress