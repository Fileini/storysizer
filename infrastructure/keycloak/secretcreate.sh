kubectl create secret generic keycloak-creds \
  --from-literal=user='' \
  --from-literal=password='' \
  -n auth