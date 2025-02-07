fra@fraserver:~/storysizer/infrastructure/Kubernetes/database$ kubectl apply -f microservices-postgres.yaml -n frontend-dev



kubectl exec -it -n frontend-dev $(kubectl get pod -n frontend-dev -l app=postgres -o jsonpath="{.items[0].metadata.name}") -- psql -U admin -d postgres


