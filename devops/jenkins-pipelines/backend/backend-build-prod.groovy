pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  securityContext:
    fsGroup: 0
  containers:
  - name: builder
    image: maven:3.8.5-openjdk-17
    command:
    - cat
    tty: true
    securityContext:
      runAsUser: 1000
      runAsGroup: 1000
    volumeMounts:
    - name: workspace-volume
      mountPath: /home/jenkins/agent
  - name: docker
    image: docker:20.10.7
    command:
    - cat
    tty: true
    securityContext:
      runAsUser: 0
      privileged: true
    volumeMounts:
    - name: docker-socket
      mountPath: /var/run/docker.sock
    - name: workspace-volume
      mountPath: /home/jenkins/agent
  volumes:
  - name: docker-socket
    hostPath:
      path: /var/run/docker.sock
  - name: workspace-volume
    emptyDir: {}
'''
        }
    }

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
                container('builder') {
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

        stage('Build Microservices') {
            steps {
                container('builder') {
                    script {
                        def microservices = sh(script: 'ls -1 storysizer/backend | grep -v "^$" | grep -v "@tmp"', returnStdout: true).trim().split("\n")
                        microservices.each { service ->
                            if (service?.trim()) {
                                stage("Build ${service}") {
                                    dir("storysizer/backend/${service}") {
                                        sh """
                                        mvn clean package -DskipTests -B -T 1C

                                        if [ ! -f target/${service}-0.0.1-SNAPSHOT.jar ]; then
                                            echo "Error: JAR file not found for ${service}" >&2
                                            exit 1
                                        fi

                                        cat <<EOF > Dockerfile
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY target/${service}-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8080
ENTRYPOINT [\"java\", \"-jar\", \"app.jar\"]
EOF

                                        if [ ! -f Dockerfile ]; then
                                            echo "Error: Dockerfile not created for ${service}" >&2
                                            exit 1
                                        fi
                                        """
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                container('docker') {
                    script {
                        def microservices = sh(script: 'ls -1 storysizer/backend | grep -v "^$" | grep -v "@tmp"', returnStdout: true).trim().split("\n")
                        microservices.each { service ->
                            if (service?.trim()) {
                                stage("Docker Build ${service}") {
                                    dir("storysizer/backend/${service}") {
                                        sh """
                                            if [ ! -f Dockerfile ]; then
                                                echo "Error: Dockerfile not found for ${service}" >&2
                                                exit 1
                                            fi

                                            docker build -t ${DOCKERHUB_USERNAME}/${service.replaceAll('@.*', '')}:latest .
                                        """
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Deploy Microservices') {
            steps {
                container('docker') {
                    script {
                        def microservices = sh(script: 'ls -1 storysizer/backend | grep -v "^$" | grep -v "@tmp"', returnStdout: true).trim().split("\n")
                        microservices.each { service ->
                            if (service?.trim()) {
                                stage("Deploy ${service}") {
                                    sh """
                                        echo ${DOCKERHUB_PASSWORD} | docker login -u ${DOCKERHUB_USERNAME} --password-stdin
                                        docker push ${DOCKERHUB_USERNAME}/${service.replaceAll('@.*', '')}:latest
                                    """
                                }
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
