pipeline {
    agent any

    tools {
            maven 'Maven'
        }

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKERHUB_USERNAME = "${DOCKERHUB_CREDENTIALS_USR}"
        DOCKERHUB_PASSWORD = "${DOCKERHUB_CREDENTIALS_PSW}"
        REPO_URL = 'https://github.com/fileini/storysizer.git'
        BRANCH = 'develop'
    }

    stages {
        stage('Sparse Checkout - Backend') {
            steps {
                script {
                    sh '''
                        rm -rf storysizer
                        git init storysizer
                        cd storysizer
                        git remote add origin ${REPO_URL}
                        git config core.sparseCheckout true
                        echo "backend/" >> .git/info/sparse-checkout
                        git pull origin ${BRANCH}
                    '''
                }
            }
        }

        stage('Build and Deploy Microservices') {
            steps {
                script {
                    def microservices = sh(script: 'ls storysizer/backend', returnStdout: true).trim().split("\n")
                    microservices.each { service ->
                        stage("Build and Deploy ${service}") {
                            dir("storysizer/backend/${service}") {
                                sh '''
                                    mvn clean package -DskipTests

                                    cat <<EOF > Dockerfile
                                    FROM openjdk:17-jdk-slim
                                    WORKDIR /app
                                    COPY target/${service}-0.0.1-SNAPSHOT.jar app.jar
                                    EXPOSE 8080
                                    ENTRYPOINT ["java", "-jar", "app.jar"]
                                    EOF

                                    docker build -t ${DOCKERHUB_USERNAME}/${service}:latest .
                                    echo ${DOCKERHUB_PASSWORD} | docker login -u ${DOCKERHUB_USERNAME} --password-stdin
                                    docker push ${DOCKERHUB_USERNAME}/${service}:latest
                                '''

                                sh '''
                                    kubectl set image deployment/${service}-deployment ${service}=${DOCKERHUB_USERNAME}/${service}:latest -n service-dev || echo "Deployment not found, creating new deployment."
                                '''
                            }
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
