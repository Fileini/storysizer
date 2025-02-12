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
                            kubectl rollout restart deployment storysizer-web -n frontend-prod
                        '''
                    }
                }
            }
        }

     
    }
}
