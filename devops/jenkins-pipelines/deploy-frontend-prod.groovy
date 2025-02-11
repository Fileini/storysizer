pipeline {
    agent none
    stages {
        /* ========== CLEAN OLD DEPLOY ========== */
        stage('Clean old deploy') {
            agent {
                kubernetes {
                    defaultContainer 'kubectl'
                    yaml """
apiVersion: v1
kind: Pod
metadata:
  name: kubectl-pod
spec:
  serviceAccountName: jenkins
  containers:
    - name: kubectl
      image: lachlanevenson/k8s-kubectl:latest
      command: ['sleep']
      args: ['infinity']
      tty: true
  restartPolicy: Never
"""
                }
            }
            steps {
                container('kubectl') {
                    script {
                        sh '''
                            kubectl delete deployment storysizer-web -n frontend-prod --ignore-not-found=true
                            kubectl delete service storysizer-web -n frontend-prod --ignore-not-found=true
                        '''
                    }
                }
            }
        }

        /* ========== DEPLOY TO KUBERNETES ========== */
        stage('Deploy to Kubernetes') {
            agent {
                kubernetes {
                    defaultContainer 'kubectl'
                    yaml """
apiVersion: v1
kind: Pod
metadata:
  name: kubectl-pod-deploy
spec:
  serviceAccountName: jenkins
  containers:
    - name: kubectl
      image: lachlanevenson/k8s-kubectl:latest
      command: ['sleep']
      args: ['infinity']
      tty: true
  restartPolicy: Never
"""
                }
            }
            steps {
                container('kubectl') {
                    script {
                        sh '''
cat <<EOF > deploy-storysizer.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: storysizer-web
  namespace: frontend-prod
spec:
  replicas: 1
  selector:
    matchLabels:
      app: storysizer-web
  template:
    metadata:
      labels:
        app: storysizer-web
    spec:
      containers:
      - name: storysizer-web
        image: fileini/storysizer-web:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: storysizer-web
  namespace: frontend-prod
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: http
  selector:
    app: storysizer-web
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: storysizer-web-ingress
  namespace: frontend-prod
spec:
  ingressClassName: traefik-public
  rules:
  - host: storysizer.public.cluster.local.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: storysizer-web
            port:
              number: 80
  tls:
  - hosts:
    - storysizer.public.cluster.local.com
    secretName: wildcard-public-cluster-tls
EOF

kubectl apply -f deploy-storysizer.yaml
                        '''
                    }
                }
            }
        }
    }
}
