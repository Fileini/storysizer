pipeline {
    agent any
    tools {
            maven 'Maven'
        }
    environment {
        // Tag dell'immagine su DockerHub
        DOCKER_IMAGE = "fileini/graphql-gateway:latest"
        // ID delle credenziali configurate in Jenkins per DockerHub
        DOCKERHUB_CREDENTIALS = "dockerhub-credentials"
    }

    stages {
        stage('Checkout') {
            steps {
                // Clona il repository fileini/storysizer (assicurati di impostare il branch corretto se necessario)
                git url: 'https://github.com/fileini/storysizer.git', branch: 'master'
            }
        }
        stage('Build con Maven') {
            steps {
                // Entra nella cartella del microservizio e compila il progetto saltando i test
                dir('graphql-gateway') {
                    sh 'mvn clean package -DskipTests -B -T 1C'
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                // Costruisci l'immagine Docker utilizzando il Dockerfile presente nella root di graphql-gateway
                dir('graphql-gateway') {
                    sh "docker build -t ${DOCKER_IMAGE} ."
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                // Accedi a DockerHub e push l'immagine
                script {
                    docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS) {
                        sh "docker push ${DOCKER_IMAGE}"
                    }
                }
            }
        }
    }
}
