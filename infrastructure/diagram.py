from diagrams import Diagram, Cluster, Edge
from diagrams.k8s.compute import Pod, Deployment, StatefulSet
from diagrams.k8s.network import Ingress, Service
from diagrams.k8s.storage import PVC
from diagrams.k8s.compute import Pod as ConfigMap
from diagrams.onprem.database import PostgreSQL
from diagrams.onprem.client import User
from diagrams.onprem.network import Internet
from diagrams.generic.network import Router
from diagrams.custom import Custom

with Diagram("Web Self-Hosted Infrastructure", show=False):
    internet = Internet("Internet")
    developer = User("Developer")
    
    with Cluster("K3s Cluster - Master Node"):
        
        with Cluster("Namespace: metallb"):
            metallb = Custom("MetalLB", "./metallb_logo.png")

        with Cluster("Namespace: ingress"):
            traefik_public = Service("Traefik-Public\n192.168.1.31")
            traefik_admin = Service("Traefik-Admin\n192.168.1.30")

            dashboard_public = Ingress("Traefik Public Dashboard")
            dashboard_admin = Ingress("Traefik Admin Dashboard")

            traefik_public >> dashboard_public
            traefik_admin >> dashboard_admin

        with Cluster("Namespace: auth"):
            keycloak = StatefulSet("Keycloak")
            keycloak_db = StatefulSet("Keycloak-Postgres")
            keycloak_pvc = PVC("Keycloak DB PVC")

            svc_keycloak = Service("Keycloak Service\nClusterIP")
            svc_keycloak_headless = Service("Keycloak Headless\nClusterIP")
            svc_keycloak_postgresql = Service("Keycloak-PostgreSQL\nClusterIP")

            ingress_admin = Ingress("keycloak.admin.cluster.local.com")
            ingress_public = Ingress("keycloak.public.cluster.local.com")

            keycloak >> svc_keycloak >> ingress_admin
            keycloak >> ingress_public
            keycloak_db >> keycloak_pvc

        with Cluster("Namespace: frontend-dev"):
            flutter_devenv = Deployment("Flutter-DevEnv")
            pod_flutter = Pod("Pod Flutter-DevEnv")
            svc_flutter = Service("Flutter Service\n192.168.1.36:22")

            storysizer_web = Deployment("StorySizer-Web")
            pod_storysizer = Pod("Pod StorySizer-Web")
            svc_storysizer = Service("StorySizer Service\nClusterIP: HTTPS")
            ingress_storysizer = Ingress("storysizer.admin.cluster.local.com")

            flutter_devenv >> pod_flutter >> svc_flutter
            storysizer_web >> pod_storysizer >> svc_storysizer >> ingress_storysizer

        with Cluster("Namespace: service-dev"):
            microservice_story = Deployment("Microservice Story")
            pod_story = Pod("Pod Story")
            config_story = ConfigMap("ConfigMap Story")
            ingress_story = Ingress("api.cluster.local/story")

            microservice_estimation = Deployment("Microservice Estimation")
            pod_estimation = Pod("Pod Estimation")
            config_estimation = ConfigMap("ConfigMap Estimation")
            ingress_estimation = Ingress("api.public.cluster.local/estimation")

            postgres_storysizer = PostgreSQL("Postgres StorySizer")
            pvc_postgres = PVC("StorySizer DB PVC")

            microservice_story >> config_story >> ingress_story
            microservice_estimation >> config_estimation >> ingress_estimation
            microservice_story >> postgres_storysizer
            microservice_estimation >> postgres_storysizer
            postgres_storysizer >> pvc_postgres

        with Cluster("Namespace: jenkins"):
            jenkins = Deployment("Jenkins")
            pod_jenkins = Pod("Pod Jenkins")
            svc_jenkins = Service("Jenkins Service\nClusterIP: HTTPS")
            ingress_jenkins = Ingress("jenkins.cluster.local")

            jenkins >> pod_jenkins >> svc_jenkins >> ingress_jenkins

    developer >> Edge(label="SSH 192.168.1.36") >> svc_flutter
    developer >> Edge(label="HTTPS") >> ingress_storysizer
    developer >> Edge(label="API Requests") >> ingress_estimation
    developer >> Edge(label="API Requests") >> ingress_story
    internet >> traefik_public
    internet >> traefik_admin
