#!/bin/bash
# apply-in-order.sh - Apply StorySizer infrastructure in correct startup order
#
# Usage: ./apply-in-order.sh [--dry-run] [--skip-helm]
#
# This script ensures components start in the correct order after a full
# cluster restart or disaster recovery. For normal operations, Kubernetes
# handles ordering via init containers and readiness probes.

set -e

DRY_RUN=""
SKIP_HELM=""
KUBECTL="kubectl"
HELM="helm"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN="--dry-run=client"
      echo "DRY RUN MODE - no changes will be applied"
      shift
      ;;
    --skip-helm)
      SKIP_HELM="true"
      echo "Skipping Helm upgrades"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--dry-run] [--skip-helm]"
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="${SCRIPT_DIR}"

echo "============================================"
echo "StorySizer Infrastructure - Ordered Apply"
echo "============================================"
echo ""

wait_for_pods() {
  local namespace=$1
  local label=$2
  local timeout=${3:-300}
  
  echo "  Waiting for pods with label '$label' in namespace '$namespace'..."
  if [[ -z "$DRY_RUN" ]]; then
    $KUBECTL wait --for=condition=ready pod -l "$label" -n "$namespace" --timeout="${timeout}s" 2>/dev/null || true
  fi
}

wait_for_deployment() {
  local namespace=$1
  local deployment=$2
  local timeout=${3:-300}
  
  echo "  Waiting for deployment '$deployment' in namespace '$namespace'..."
  if [[ -z "$DRY_RUN" ]]; then
    $KUBECTL rollout status deployment/"$deployment" -n "$namespace" --timeout="${timeout}s" 2>/dev/null || true
  fi
}

wait_for_statefulset() {
  local namespace=$1
  local statefulset=$2
  local timeout=${3:-300}
  
  echo "  Waiting for statefulset '$statefulset' in namespace '$namespace'..."
  if [[ -z "$DRY_RUN" ]]; then
    $KUBECTL rollout status statefulset/"$statefulset" -n "$namespace" --timeout="${timeout}s" 2>/dev/null || true
  fi
}

# ============================================
# Phase 0: PriorityClasses (must be first)
# ============================================
echo "Phase 0: Applying PriorityClasses..."
$KUBECTL apply $DRY_RUN -f "$INFRA_DIR/priority-classes.yaml"
echo ""

# ============================================
# Phase 1: MetalLB (networking foundation)
# ============================================
echo "Phase 1: MetalLB (Load Balancer)..."
if [[ -z "$SKIP_HELM" ]]; then
  echo "  Upgrading MetalLB Helm release..."
  if [[ -z "$DRY_RUN" ]]; then
    $HELM upgrade --install metallb metallb/metallb \
      -n metallb-system --create-namespace \
      -f "$INFRA_DIR/metallb/helm-values.yaml" \
      --wait --timeout 5m
  fi
fi
$KUBECTL apply $DRY_RUN -f "$INFRA_DIR/metallb/metallb-config.yaml"
wait_for_pods "metallb-system" "app.kubernetes.io/name=metallb" 120
echo ""

# ============================================
# Phase 2: Traefik Ingress Controllers
# ============================================
echo "Phase 2: Traefik Ingress Controllers..."
if [[ -z "$SKIP_HELM" ]]; then
  echo "  Upgrading Traefik Admin..."
  if [[ -z "$DRY_RUN" ]]; then
    $HELM upgrade --install traefik-admin traefik/traefik \
      -n ingress --create-namespace \
      -f "$INFRA_DIR/treaefik/admin-ingress-controller/helm-values.yaml" \
      --wait --timeout 3m
  fi
  
  echo "  Upgrading Traefik Public..."
  if [[ -z "$DRY_RUN" ]]; then
    $HELM upgrade --install traefik-public traefik/traefik \
      -n ingress \
      -f "$INFRA_DIR/treaefik/public-ingress-controller/helm-values.yaml" \
      --wait --timeout 3m
  fi
fi
wait_for_pods "ingress" "app=traefik-admin" 120
wait_for_pods "ingress" "app=traefik-public" 120
echo ""

# ============================================
# Phase 3: cert-manager (TLS certificates)
# ============================================
echo "Phase 3: cert-manager..."
$KUBECTL apply $DRY_RUN -f "$INFRA_DIR/certmanager/"
# cert-manager is usually already installed via Helm, just apply issuers
echo ""

# ============================================
# Phase 4: Wait-scripts ConfigMap (needed by init containers)
# ============================================
echo "Phase 4: Wait-scripts ConfigMap..."
# Deploy to all namespaces that need it
for ns in database service-prod cloudflared; do
  echo "  Deploying wait-scripts to namespace: $ns"
  if [[ -z "$DRY_RUN" ]]; then
    $KUBECTL apply -f "$INFRA_DIR/common/wait-scripts-configmap.yaml" -n "$ns" 2>/dev/null || \
    $KUBECTL create namespace "$ns" --dry-run=client -o yaml | $KUBECTL apply -f - && \
    $KUBECTL apply -f "$INFRA_DIR/common/wait-scripts-configmap.yaml" -n "$ns"
  fi
done
echo ""

# ============================================
# Phase 5: PostgreSQL (microservices database)
# ============================================
echo "Phase 5: PostgreSQL (microservices database)..."
$KUBECTL apply $DRY_RUN -f "$INFRA_DIR/database/microservices-postgres.yaml" -n database
wait_for_deployment "database" "postgres" 180
echo ""

# ============================================
# Phase 6: Keycloak (authentication)
# ============================================
echo "Phase 6: Keycloak..."
if [[ -z "$SKIP_HELM" ]]; then
  echo "  Upgrading Keycloak Helm release..."
  if [[ -z "$DRY_RUN" ]]; then
    $HELM upgrade --install keycloak oci://registry-1.docker.io/bitnamicharts/keycloak \
      -n auth --create-namespace \
      -f "$INFRA_DIR/keycloak/bitnami/bitnami-helm-values.yaml" \
      --wait --timeout 10m
  fi
fi
wait_for_statefulset "auth" "keycloak" 300
echo ""

# ============================================
# Phase 7: Jenkins (CI/CD - can start in parallel with services)
# ============================================
echo "Phase 7: Jenkins..."
if [[ -z "$SKIP_HELM" ]]; then
  echo "  Upgrading Jenkins Helm release..."
  if [[ -z "$DRY_RUN" ]]; then
    $HELM upgrade --install jenkins jenkins/jenkins \
      -n jenkins --create-namespace \
      -f "$INFRA_DIR/jenkins/helm-values.yaml" \
      --wait --timeout 10m
  fi
fi
$KUBECTL apply $DRY_RUN -f "$INFRA_DIR/jenkins/ingress-jenkins.yaml"
$KUBECTL apply $DRY_RUN -f "$INFRA_DIR/jenkins/rbac/"
# Don't wait - Jenkins can take a while and is not blocking
echo ""

# ============================================
# Phase 8: Backend Services (story, estimation)
# ============================================
echo "Phase 8: Backend Services..."
$KUBECTL apply $DRY_RUN -f "$INFRA_DIR/backend/story-service/prod-story-service-manifest.yaml"
$KUBECTL apply $DRY_RUN -f "$INFRA_DIR/backend/estimation-service/prod-estimation-service-manifest.yaml"
# Init containers will wait for PostgreSQL
wait_for_deployment "service-prod" "story-service" 300
wait_for_deployment "service-prod" "estimation-service" 300
echo ""

# ============================================
# Phase 9: GraphQL Gateway (needs Keycloak)
# ============================================
echo "Phase 9: GraphQL Gateway..."
$KUBECTL apply $DRY_RUN -f "$INFRA_DIR/backend/graphql-gateway/prod-graphql-gateway-manifest.yaml"
# Init container will wait for Keycloak OIDC
wait_for_deployment "service-prod" "gateway-service" 300
echo ""

# ============================================
# Phase 10: Cloudflared (tunnel to external)
# ============================================
echo "Phase 10: Cloudflared..."
$KUBECTL apply $DRY_RUN -f "$INFRA_DIR/cloudflare/"
# Init container will wait for Traefik public
wait_for_deployment "cloudflared" "cloudflared" 180
echo ""

# ============================================
# Phase 11: Frontend
# ============================================
echo "Phase 11: Frontend..."
$KUBECTL apply $DRY_RUN -f "$INFRA_DIR/frontend/prod-frontend-manifest.yaml"
wait_for_deployment "frontend-prod" "storysizer-web" 120
echo ""

# ============================================
# Summary
# ============================================
echo "============================================"
echo "Deployment Complete!"
echo "============================================"
echo ""
echo "Check status with:"
echo "  kubectl get pods -A | grep -E 'metallb|traefik|keycloak|postgres|jenkins|gateway|story|estimation|frontend|cloudflare'"
echo ""
echo "If any pods are stuck in Init state, check init container logs:"
echo "  kubectl logs <pod-name> -c wait-for-postgres -n <namespace>"
echo "  kubectl logs <pod-name> -c wait-for-keycloak -n <namespace>"
echo ""
