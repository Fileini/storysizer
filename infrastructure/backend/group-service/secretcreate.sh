#!/bin/bash
# Crea il secret groups-db-secret nel namespace service-prod.
# Esegui PRIMA di applicare il manifest e il Job di inizializzazione DB.
#
# Sostituisci i valori tra <...> con quelli reali.

kubectl create secret generic groups-db-secret \
  -n service-prod \
  --from-literal=POSTGRES_DB=groupsdb \
  --from-literal=POSTGRES_USER=groupsuser \
  --from-literal=POSTGRES_PASSWORD='<password>' \
  --from-literal=RESEND_API_KEY='<resend-api-key>' \
  --from-literal=RESEND_FROM_EMAIL='StorySizer <noreply@storysizer.org>' \
  --from-literal=APP_BASE_URL='https://app.storysizer.org'
