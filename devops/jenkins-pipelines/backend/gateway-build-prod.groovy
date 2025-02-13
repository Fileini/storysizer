pipeline {
    agent {
        kubernetes {
            defaultContainer 'kubectl'
            yaml """
apiVersion: v1
kind: Pod
metadata:
  name: jenkins-agent
spec:
  serviceAccountName: jenkins
  containers:
    - name: kubectl
      image: lachlanevenson/k8s-kubectl:latest
      command: ['sleep']
      args: ['infinity']
      tty: true
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent
    - name: docker
      image: docker:20.10.16
      command: ['cat']
      tty: true
      volumeMounts:
        - name: docker-socket
          mountPath: /var/run/docker.sock
        - name: workspace-volume
          mountPath: /home/jenkins/agent
    - name: openjdk
      image: openjdk:17
      command: ['cat']
      tty: true
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent
    - name: maven
      image: maven:3.9.9-eclipse-temurin-17
      command: ['cat']
      tty: true
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent
  restartPolicy: Never
  volumes:
    - name: docker-socket
      hostPath:
        path: /var/run/docker.sock
    - name: workspace-volume
      emptyDir: {}
"""
        }
    }
    environment {
        DOCKER_IMAGE = "fileini/graphql-gateway:latest"
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'develop', url: 'https://github.com/fileini/storysizer.git'
            }
        }
        stage('Prepare Truststore') {
            steps {
                container('kubectl') {
                    sh '''
                      set -ex
                      echo "Verifico la versione di kubectl:"
                      kubectl version --short
                      echo "Recupero il secret wildcard-public-cluster-tls dal namespace frontend-prod:"
                      kubectl get secret wildcard-public-cluster-tls -n frontend-prod
                      echo "Recupero il certificato dal secret..."
                      kubectl get secret wildcard-public-cluster-tls -n frontend-prod -o jsonpath="{.data.ca\\.crt}" | base64 -d > public.crt
                      echo "Contenuto del certificato (public.crt):"
                      cat public.crt
                    '''
                }
                container('openjdk') {
                    sh '''
                      set -ex
                      echo "DEBUG: Verifica la presenza di keytool:"
                      command -v keytool || echo "keytool non trovato"
                      keytool -help > /dev/null || echo "keytool non funziona"
                      echo "Creazione del truststore..."
                      keytool -importcert -alias keycloak-ca -file public.crt -keystore truststore.jks -storepass changeit -noprompt
                      echo "Verifica del truststore:"
                      keytool -list -keystore truststore.jks -storepass changeit
                      echo "Spostamento del truststore nella directory di build..."
                      mv truststore.jks graphql-gateway/
                    '''
                }
            }
        }
        stage('Build Maven Project') {
            steps {
                container('maven') {
                    dir('graphql-gateway') {
                        sh 'mvn clean package -DskipTests -B -T 1C'
                    }
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                container('docker') {
                    dir('graphql-gateway') {
                        sh "docker build -t ${DOCKER_IMAGE} ."
                    }
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                container('docker') {
                    withDockerRegistry([credentialsId: 'dockerhub-credentials', url: '']) {
                        sh "docker push ${DOCKER_IMAGE}"
                    }
                }
            }
        }
    }
    post {
        always {
            script {
                // Proviamo a rendere scrivibili i file, se possibile, prima di pulire il workspace.
                try {
                    container('maven') {
                        sh 'chmod -R u+w . || true'
                    }
                } catch (e) {
                    echo "Impossibile modificare i permessi: ${e}"
                }
                // Proviamo ad eseguire deleteDir() e, in caso di errore, lo catturiamo per evitare che la pipeline fallisca.
                try {
                    deleteDir()
                } catch (e) {
                    echo "Cleanup non riuscito: ${e}"
                }
            }
        }
    }
}
