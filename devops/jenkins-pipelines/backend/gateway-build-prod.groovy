pipeline {
    agent any
    tools {
        maven 'Maven'
    }
    environment {
        // Assicurati di aver configurato in Jenkins le credenziali Docker con questo ID
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        // Specifica qui il nome dell’immagine Docker; nel nostro caso fileini/graphql-gateway
        DOCKER_IMAGE = "fileini/graphql-gateway:latest"
    }

    stages {
        stage('Checkout') {
            steps {
                // Esegue il checkout della branch develop della repo fileini/storysizer
                git branch: 'develop', url: 'https://github.com/fileini/storysizer.git'
            }
        }
        stage('Build Maven Project') {
            steps {
                // Usa la cartella corretta dove è presente il pom.xml
                dir('graphql-gateway') {
                    sh 'mvn clean package -DskipTests -B -T 1C'
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                // Costruisce l’immagine Docker usando il Dockerfile presente nella cartella graphql-gateway
                dir('graphql-gateway') {
                    sh "docker build -t ${DOCKER_IMAGE} ."
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                // Esegue il push dell’immagine su Docker Hub utilizzando le credenziali configurate
                withDockerRegistry([credentialsId: "${DOCKERHUB_CREDENTIALS}", url: '']) {
                    sh "docker push ${DOCKER_IMAGE}"
                }
            }
        }
    }

    post {
        always {
            // Pulisce la workspace usando deleteDir() se cleanWs() non è disponibile
            deleteDir()
        }
    }
}
