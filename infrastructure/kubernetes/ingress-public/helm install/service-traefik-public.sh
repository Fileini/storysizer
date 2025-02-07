kubectl patch service traefik-public -n ingress -p '{"spec":{"loadBalancerIP":"192.168.1.31"}}'

kubectl patch deployment traefik-public -n ingress -p '{"spec": {"template": {"metadata": {"labels": {"app": "traefik-public"}}}}}'

kubectl rollout restart deployment traefik-public -n ingress
