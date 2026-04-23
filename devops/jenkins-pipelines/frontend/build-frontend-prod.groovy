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
                stash name: 'flutter-build', includes: 'frontend/storysizer/build/web/**,frontend/storysizer/build/web/*'
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
                // Creazione del contesto per Docker
                sh '''
  mkdir -p docker-context
  cp -r frontend/storysizer/build/web docker-context/

  # Sanity check: flutter_service_worker.js must be present
  if [ ! -f docker-context/web/flutter_service_worker.js ]; then
    echo "ERROR: flutter_service_worker.js missing from build output"
    ls -la docker-context/web/
    exit 1
  fi

  # Creazione del file di configurazione minimal per Nginx
  cat <<'EOF' > docker-context/default.conf
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # WASM files with correct MIME type
    location ~* \.wasm$ {
        default_type application/wasm;
        try_files $uri =404;
    }

    # JS/CSS/JSON: serve file or 404 — NEVER fallback to index.html
    # Prevents nginx from serving HTML as JS (breaks service workers)
    location ~* \.(js|css|json|map|woff2?|ttf|otf|ico|png|jpg|jpeg|gif|svg|webp)$ {
        try_files $uri =404;
    }

    # Exact match for index.html
    location = /index.html {
        try_files $uri =404;
    }

    # SPA catch-all: only for navigation requests (HTML routes)
    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF
  
  # Creazione del Dockerfile che copia i file e il file di configurazione in Nginx
  cat <<'EOF' > docker-context/Dockerfile
FROM nginx:alpine
COPY web /usr/share/nginx/html
COPY default.conf /etc/nginx/conf.d/default.conf
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
