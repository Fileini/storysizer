pipeline {
    agent {
        kubernetes {
            // Configura il pod template con un container "docker" che ha il client Docker installato
            label 'docker-agent'
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: docker-agent
spec:
  containers:
  - name: docker
    image: docker:20.10.16
    command:
      - cat
    tty: true
    volumeMounts:
      - name: docker-socket
        mountPath: /var/run/docker.sock
  volumes:
    - name: docker-socket
      hostPath:
        path: /var/run/docker.sock
"""
        }
    }
    tools {
        maven 'Maven'
    }
    environment {
        DOCKER_IMAGE = "fileini/graphql-gateway:latest"
    }
    stages {
        stage('Checkout') {
            steps {
                // Esegue il checkout della branch "develop" dal repository
                git branch: 'develop', url: 'https://github.com/fileini/storysizer.git'
            }
        }
        stage('Build Maven Project') {
            steps {
                // Compila il progetto Maven (saltando i test, se desiderato)
                dir('graphql-gateway') {
                    sh 'mvn clean package -Dmaven.test.skip=true'
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                // Utilizza il container "docker" per eseguire i comandi Docker
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
                    // Effettua il push dell'immagine su Docker Hub utilizzando le credenziali configurate in Jenkins
                    withDockerRegistry([credentialsId: 'dockerhub-credentials', url: '']) {
                        sh "docker push ${DOCKER_IMAGE}"
                    }
                }
            }
        }
    }
    post {
        always {
            deleteDir()
        }
    }
}
