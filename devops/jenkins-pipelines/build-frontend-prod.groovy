pipeline {
    agent none

    stages {

        /* ========== CHECKOUT ========== */
        stage('Checkout Flutter Web') {
            agent {
                kubernetes {
                    defaultContainer 'flutter'
                    yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
    - name: flutter
      image: ghcr.io/cirruslabs/flutter:3.27.1
      command: ['cat']
      tty: true
"""
                }
            }
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: 'develop']],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [
                        [$class: 'SparseCheckoutPaths',
                         sparseCheckoutPaths: [[path: 'frontend/storysizer/**']]]
                    ],
                    userRemoteConfigs: [[url: 'https://github.com/Fileini/storysizer.git']]
                ])
                stash name: 'flutter-code', includes: 'frontend/storysizer/**'
            }
        }

        /* ========== BUILD FLUTTER ========== */
        stage('Build Flutter Web') {
            agent {
                kubernetes {
                    defaultContainer 'flutter'
                    yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
    - name: flutter
      image: ghcr.io/cirruslabs/flutter:3.27.1
      command: ['cat']
      tty: true
"""
                }
            }
            steps {
                unstash 'flutter-code'

                container('flutter') {
                    sh '''
                      cd frontend/storysizer
                      flutter pub get
                      flutter build web --release
                    '''
                }
                stash name: 'flutter-build', includes: 'frontend/storysizer/build/web/**'
            }
        }

        /* ========== DOCKER BUILD & PUSH ========== */
        stage('Build & Push Docker Image') {
            agent {
                kubernetes {
                    defaultContainer 'docker'
                    yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
    - name: docker
      image: docker:24.0-dind
      securityContext:
        privileged: true
      tty: true
"""
                }
            }
            environment {
                DOCKER_REGISTRY_URL = 'docker.io'
                DOCKER_IMAGE_NAME   = 'fileini/storysizer-web'
                DOCKER_IMAGE_TAG    = 'latest'
            }
            steps {
                unstash 'flutter-build'

                container('docker') {
                    script {
                        sh '''
                          mkdir -p docker-context
                          cp -r frontend/storysizer/build/web docker-context/
                          
                          cat <<EOF > docker-context/Dockerfile
FROM nginx:alpine
COPY web /usr/share/nginx/html
EXPOSE 80
EOF
                        '''

                        withCredentials([
                            usernamePassword(
                                credentialsId: 'dockerhub-credentials',
                                usernameVariable: 'DOCKERHUB_USERNAME',
                                passwordVariable: 'DOCKERHUB_PASSWORD'
                            )
                        ]) {
                            sh '''
                              echo $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG
                              echo $DOCKERHUB_PASSWORD | docker login -u $DOCKERHUB_USERNAME --password-stdin $DOCKER_REGISTRY_URL
                              cd docker-context
                              docker build -t $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG .
                              docker push $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG
                            '''
                        }
                    }
                }
            }
        }
    }
}
