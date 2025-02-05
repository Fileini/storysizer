from diagrams import Diagram, Cluster
from diagrams.k8s.compute import Deployment, StatefulSet, Pod
from diagrams.k8s.network import Ingress, Service
from diagrams.k8s.storage import PVC
from diagrams.k8s.podconfig import ConfigMap, Secret
from diagrams.onprem.client import Users

with Diagram("Kubernetes Infrastructure", show=True, filename="k8s_infra_diagram", direction="LR"):
    # Nodo che rappresenta il Developer (accesso diretto a Flutter DevEnv)
    developer = Users("Developer")
    # Nodo per gli utenti esterni (es. utenti finali)
    external_users = Users("External Users")

    with Cluster("Kubernetes Cluster"):
        # Ingress Controller (Namespace: kube-system)
        with Cluster("Namespace: kube-system"):
            ingress_controller = Ingress("Traefik Ingress\nIP: 192.168.1.30")
        
        # MetalLB (Namespace: metallb-system)
        with Cluster("Namespace: metallb-system"):
            metallb_controller = Pod("MetalLB Controller")
            metallb_speaker = Pod("MetalLB Speaker")
            metallb_webhook = Service("MetalLB Webhook Service")

        # Namespace: auth - Keycloak e il suo database Postgres
        with Cluster("Namespace: auth"):
            with Cluster("Keycloak"):
                keycloak_stateful = StatefulSet("Keycloak")
                keycloak_db = StatefulSet("Keycloak Postgres")
                keycloak_db_pvc = PVC("Keycloak DB PVC")
            keycloak_service = Service("Keycloak Service\n(ClusterIP)")
            keycloak_ingress = Ingress("Keycloak Ingress\nkeycloak.cluster.local")
            keycloak_secret = Secret("Keycloak Secret")

        # Namespace: frontend-dev
        with Cluster("Namespace: frontend-dev"):
            # Flutter Development Environment esposto come LoadBalancer
            flutter_deployment = Deployment("Flutter DevEnv Deployment")
            flutter_pod = Pod("Flutter DevEnv Pod")
            flutter_lb_service = Service("Flutter DevEnv LB\nLoadBalancer\nIP: 192.168.1.36\nPort: 22")
            # Catena: Service (LoadBalancer) -> Pod -> Deployment
            flutter_lb_service >> flutter_pod >> flutter_deployment

            # Storysizer-web: applicazione web con Service ClusterIP e Ingress
            storysizer_deployment = Deployment("Storysizer-web Deployment")
            storysizer_pod = Pod("Storysizer-web Pod")
            storysizer_service = Service("Storysizer-web Service\n(ClusterIP)")
            storysizer_ingress = Ingress("Storysizer Ingress\nstorysizer.cluster.local")
            # Catena: Ingress -> Service -> Pod -> Deployment
            storysizer_ingress >> storysizer_service >> storysizer_pod >> storysizer_deployment

        # Namespace: service-dev (Microservizi Spring Boot)
        with Cluster("Namespace: service-dev"):
            # Microservizio "story"
            with Cluster("Story Service"):
                story_deployment = Deployment("Deployment: Story")
                story_pod = Pod("Pod: Story")
                story_config = ConfigMap("ConfigMap: Story")
                story_service = Service("Service: Story\n(ClusterIP)")
                story_ingress = Ingress("Ingress: api.cluster.local/story")
                # Catena: Ingress -> Service -> Pod -> Deployment
                story_ingress >> story_service >> story_pod >> story_deployment

            # Microservizio "estimation"
            with Cluster("Estimation Service"):
                estimation_deployment = Deployment("Deployment: Estimation")
                estimation_pod = Pod("Pod: Estimation")
                estimation_config = ConfigMap("ConfigMap: Estimation")
                estimation_service = Service("Service: Estimation\n(ClusterIP)")
                estimation_ingress = Ingress("Ingress: api.cluster.local/estimation")
                # Catena: Ingress -> Service -> Pod -> Deployment
                estimation_ingress >> estimation_service >> estimation_pod >> estimation_deployment

            # Database Postgres condiviso per i microservizi (story ed estimation)
            with Cluster("Shared Postgres DB"):
                shared_db = Pod("Postgres DB\n(storysizer)")
                shared_db_pvc = PVC("DB PVC")
                shared_db >> shared_db_pvc

            # I Pod dei microservizi si collegano al DB (per la persistenza)
            story_pod >> shared_db
            estimation_pod >> shared_db

            # I Pod dei microservizi si collegano al Keycloak Service per l'autenticazione
            story_pod >> keycloak_service
            estimation_pod >> keycloak_service

        # Namespace: jenkins
        with Cluster("Namespace: jenkins"):
            jenkins_deployment = Deployment("Jenkins Deployment")
            jenkins_pod = Pod("Jenkins Pod")
            jenkins_service = Service("Jenkins Service\n(ClusterIP)")
            jenkins_ingress = Ingress("Jenkins Ingress\njenkins.cluster.local")
            # Catena: Ingress -> Service -> Pod -> Deployment
            jenkins_ingress >> jenkins_service >> jenkins_pod >> jenkins_deployment

    # Collegamenti globali dal Ingress Controller alle varie Ingress
    ingress_controller >> keycloak_ingress
    ingress_controller >> storysizer_ingress
    ingress_controller >> story_ingress  # per Story Service
    ingress_controller >> estimation_ingress  # per Estimation Service
    ingress_controller >> jenkins_ingress

    # Il Developer si collega direttamente al servizio LoadBalancer di Flutter DevEnv
    developer >> flutter_lb_service

    # Gli utenti esterni si collegano al Traefik Ingress Controller
    external_users >> ingress_controller

