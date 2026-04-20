#!/usr/bin/env bash
set -u
# niente "set -e": vogliamo continuare e riportare FAIL/OK per ogni step

KEYCLOAK_NS="${KEYCLOAK_NS:-auth}"
KEYCLOAK_REL="${KEYCLOAK_REL:-keycloak}"
APP_NS_LIST="${APP_NS_LIST:-auth database service-dev serviceprod jenkins kube-system}"

TS="$(date +%F_%H%M)"
ROOT_OUT="/root/FORMAT_TOTAL_$TS"
ARCHIVE_ZST="/root/FORMAT_TOTAL_$TS.tar.zst"
ARCHIVE_TGZ="/root/FORMAT_TOTAL_$TS.tgz"

ok(){ echo "[OK]   $*"; }
fail(){ echo "[FAIL] $*"; }
step(){ echo -e "\n==== $* ====\n"; }

run() {
  # run "descrizione" comando...
  local desc="$1"; shift
  step "$desc"
  echo "+ $*"
  if "$@"; then ok "$desc"; return 0; else fail "$desc"; return 1; fi
}

run_sudo() {
  local desc="$1"; shift
  step "$desc"
  echo "+ sudo $*"
  if sudo "$@"; then ok "$desc"; return 0; else fail "$desc"; return 1; fi
}

mkdir_root_out() {
  run_sudo "Creo struttura output in $ROOT_OUT" \
    mkdir -p "$ROOT_OUT"/{pv,ubuntu,k8s,helm,certs,repo,notes}
}

# ---------- 0) Note base ----------
notes_base() {
  run_sudo "Salvo note base: uname" bash -lc "uname -a > '$ROOT_OUT/notes/uname.txt'"
  run_sudo "Salvo note base: lsblk" bash -lc "lsblk -f > '$ROOT_OUT/notes/lsblk.txt'"
  run_sudo "Salvo note base: df -h" bash -lc "df -h > '$ROOT_OUT/notes/df-h.txt'"
  run_sudo "Salvo note base: ip a" bash -lc "ip a > '$ROOT_OUT/notes/ip-a.txt'"
  run_sudo "Salvo note base: date" bash -lc "date > '$ROOT_OUT/notes/date.txt'"
}

# ---------- 1) Programmi Ubuntu ----------
ubuntu_inventory() {
  run_sudo "Inventario pacchetti dpkg (tutti)" \
    bash -lc "dpkg-query -W -f='\\\${binary:Package}\\t\\\${Version}\\n' > '$ROOT_OUT/ubuntu/dpkg-packages.tsv'"

  run_sudo "Inventario pacchetti APT manuali" \
    bash -lc "apt-mark showmanual > '$ROOT_OUT/ubuntu/apt-manual.txt'"

  if command -v snap >/dev/null 2>&1; then
    run_sudo "Inventario SNAP" bash -lc "snap list > '$ROOT_OUT/ubuntu/snap-list.txt'"
  else
    step "Inventario SNAP"
    echo "snap non presente"
    ok "Inventario SNAP (skipped)"
  fi

  if command -v flatpak >/dev/null 2>&1; then
    run_sudo "Inventario Flatpak" bash -lc "flatpak list > '$ROOT_OUT/ubuntu/flatpak-list.txt'"
  else
    step "Inventario Flatpak"
    echo "flatpak non presente"
    ok "Inventario Flatpak (skipped)"
  fi

  run_sudo "Lista systemd services (unit files)" \
    bash -lc "systemctl list-unit-files --type=service > '$ROOT_OUT/ubuntu/systemd-services.txt'"

  run_sudo "Crontab root (se presente)" \
    bash -lc "crontab -l > '$ROOT_OUT/ubuntu/crontab.root.txt' 2>/dev/null || true"

  run_sudo "Crontab utente fra (se presente)" \
    bash -lc "sudo -u fra crontab -l > '$ROOT_OUT/ubuntu/crontab.fra.txt' 2>/dev/null || true"
}

# ---------- 2) PV tgz ----------
pv_collect_and_verify() {
  step "Trovo ultima cartella /root/PV_BACKUP_*"
  local latest
  latest="$(sudo bash -lc "ls -1dt /root/PV_BACKUP_* 2>/dev/null | head -n1 || true")"
  echo "LATEST_PV_DIR=$latest"
  sudo bash -lc "echo 'LATEST_PV_DIR=$latest' > '$ROOT_OUT/notes/latest_pv_dir.txt'" || true
  if [[ -z "$latest" ]]; then
    fail "PV_BACKUP_* non trovato"
    return 1
  else
    ok "Trovata cartella PV backup: $latest"
  fi

  run_sudo "Lista contenuti PV backup (sorgente)" bash -lc "ls -lah '$latest' > '$ROOT_OUT/pv/pv_backup_ls.txt'"

  run_sudo "Copio TGZ PV dentro al bundle" bash -lc "cp -a '$latest'/*.tgz '$ROOT_OUT/pv/' 2>/dev/null || true"
  run_sudo "Copio SHA256SUMS (se esiste) dentro al bundle" bash -lc "cp -a '$latest'/SHA256SUMS.txt '$ROOT_OUT/pv/' 2>/dev/null || true"

  run_sudo "Lista contenuti PV nel bundle" bash -lc "ls -lah '$ROOT_OUT/pv'"

  run_sudo "Segnalo TGZ < 50MB (possibile errore/volume vuoto)" bash -lc \
    "find '$ROOT_OUT/pv' -maxdepth 1 -type f -name '*.tgz' -printf '%f\\t%s\\n' | awk -F'\\t' '\\$2 < 50000000 {print}' > '$ROOT_OUT/pv/WARN_small_archives_under_50MB.txt' || true"

  if sudo test -f "$ROOT_OUT/pv/SHA256SUMS.txt"; then
    run_sudo "Verifico checksum SHA256 (PV tgz)" bash -lc \
      "cd '$ROOT_OUT/pv' && sha256sum -c SHA256SUMS.txt > '$ROOT_OUT/pv/sha256_check.txt' 2>&1 || true"
    run_sudo "Mostro esito checksum" bash -lc "cat '$ROOT_OUT/pv/sha256_check.txt' || true"
  else
    step "Verifico checksum SHA256 (PV tgz)"
    echo "SHA256SUMS.txt mancante (non posso verificare)"
    fail "Verifico checksum SHA256 (PV tgz)"
  fi
}

# ---------- 3) Kubernetes state + secrets/configmap ----------
k8s_exports() {
  step "Kubernetes exports (se cluster risponde)"
  if ! sudo test -f /etc/rancher/k3s/k3s.yaml; then
    echo "KUBECONFIG non trovato: /etc/rancher/k3s/k3s.yaml"
    fail "Kubernetes exports"
    return 1
  fi

  run_sudo "kubectl version" bash -lc "KUBECONFIG=/etc/rancher/k3s/k3s.yaml k3s kubectl version > '$ROOT_OUT/k8s/kubectl_version.txt' 2>&1 || true"
  run_sudo "Export namespaces" bash -lc "KUBECONFIG=/etc/rancher/k3s/k3s.yaml k3s kubectl get ns -o yaml > '$ROOT_OUT/k8s/namespaces.yaml' 2>/dev/null || true"
  run_sudo "Export storageclasses" bash -lc "KUBECONFIG=/etc/rancher/k3s/k3s.yaml k3s kubectl get sc -o yaml > '$ROOT_OUT/k8s/storageclasses.yaml' 2>/dev/null || true"
  run_sudo "Export pv/pvc" bash -lc "KUBECONFIG=/etc/rancher/k3s/k3s.yaml k3s kubectl get pvc -A -o yaml > '$ROOT_OUT/k8s/pvc.yaml' 2>/dev/null || true; KUBECONFIG=/etc/rancher/k3s/k3s.yaml k3s kubectl get pv -o yaml > '$ROOT_OUT/k8s/pv.yaml' 2>/dev/null || true"
  run_sudo "Export configmaps" bash -lc "KUBECONFIG=/etc/rancher/k3s/k3s.yaml k3s kubectl get cm -A -o yaml > '$ROOT_OUT/k8s/configmaps.yaml' 2>/dev/null || true"

  if command -v jq >/dev/null 2>&1; then
    run_sudo "Export secrets filtrati (no service-account-token)" bash -lc \
      "KUBECONFIG=/etc/rancher/k3s/k3s.yaml k3s kubectl get secret -A -o json \
      | jq 'del(.items[] | select(.type==\"kubernetes.io/service-account-token\"))' \
      > '$ROOT_OUT/k8s/secrets.filtered.json' 2>/dev/null || true"
  else
    step "Export secrets filtrati"
    echo "jq non installato: installa con 'sudo apt-get update && sudo apt-get install -y jq' se vuoi JSON filtrato"
    fail "Export secrets filtrati (jq mancante)"
  fi
}

# ---------- 4) Certificati ----------
cert_exports() {
  step "Certificati: TLS secrets index + cert-manager + /etc/letsencrypt"
  if command -v jq >/dev/null 2>&1; then
    run_sudo "Indice TLS secrets (kubernetes.io/tls)" bash -lc \
      "KUBECONFIG=/etc/rancher/k3s/k3s.yaml k3s kubectl get secret -A -o json \
      | jq '[.items[] | select(.type==\"kubernetes.io/tls\") | {namespace:.metadata.namespace,name:.metadata.name,type:.type,data_keys:(.data|keys)}]' \
      > '$ROOT_OUT/certs/k8s_tls_secrets_index.json' 2>/dev/null || true"
  else
    step "Indice TLS secrets"
    echo "jq non installato -> skipped"
    ok "Indice TLS secrets (skipped)"
  fi

  # cert-manager CRD check
  if sudo bash -lc "KUBECONFIG=/etc/rancher/k3s/k3s.yaml k3s kubectl get crd 2>/dev/null | grep -qi cert-manager"; then
    run_sudo "Export cert-manager Issuer/ClusterIssuer" bash -lc \
      "KUBECONFIG=/etc/rancher/k3s/k3s.yaml k3s kubectl get clusterissuer,issuer -A -o yaml > '$ROOT_OUT/certs/cert-manager-issuers.yaml' 2>/dev/null || true"
    run_sudo "Export cert-manager Certificate" bash -lc \
      "KUBECONFIG=/etc/rancher/k3s/k3s.yaml k3s kubectl get certificate -A -o yaml > '$ROOT_OUT/certs/cert-manager-certificates.yaml' 2>/dev/null || true"
  else
    step "cert-manager non rilevato (CRD assenti) -> skipped"
    ok "cert-manager export (skipped)"
  fi

  if sudo test -d /etc/letsencrypt; then
    run_sudo "Tar /etc/letsencrypt" bash -lc "tar -czf '$ROOT_OUT/certs/etc-letsencrypt.tgz' /etc/letsencrypt"
  else
    step "/etc/letsencrypt non presente -> skipped"
    ok "Tar /etc/letsencrypt (skipped)"
  fi
}

# ---------- 5) Helm state + Keycloak chart/version + values/manifest ----------
helm_exports() {
  step "Helm exports + Keycloak chart/version"
  if ! command -v helm >/dev/null 2>&1; then
    echo "helm non presente nel PATH"
    fail "Helm exports"
    return 1
  fi

  run "helm version" helm version > "$ROOT_OUT/helm/helm_version.txt" 2>&1 || true
  run "helm list -A" helm list -A > "$ROOT_OUT/helm/helm_list_all.txt" 2>&1 || true
  run "helm list -n $KEYCLOAK_NS" helm list -n "$KEYCLOAK_NS" > "$ROOT_OUT/helm/helm_list_${KEYCLOAK_NS}.txt" 2>&1 || true

  run_sudo "Estraggo riga release Keycloak (chart/version)" bash -lc \
    "grep -E '^[[:space:]]*$KEYCLOAK_REL[[:space:]]' '$ROOT_OUT/helm/helm_list_${KEYCLOAK_NS}.txt' > '$ROOT_OUT/helm/keycloak_release_line.txt' 2>/dev/null || true; cat '$ROOT_OUT/helm/keycloak_release_line.txt' || true"

  run "helm get values (Keycloak, all)" helm get values -n "$KEYCLOAK_NS" "$KEYCLOAK_REL" -a \
    > "$ROOT_OUT/helm/${KEYCLOAK_NS}.${KEYCLOAK_REL}.values.yaml" 2> "$ROOT_OUT/helm/${KEYCLOAK_NS}.${KEYCLOAK_REL}.values.err" || true

  run "helm get manifest (Keycloak)" helm get manifest -n "$KEYCLOAK_NS" "$KEYCLOAK_REL" \
    > "$ROOT_OUT/helm/${KEYCLOAK_NS}.${KEYCLOAK_REL}.manifest.yaml" 2> "$ROOT_OUT/helm/${KEYCLOAK_NS}.${KEYCLOAK_REL}.manifest.err" || true
}

# ---------- 6) Keycloak immagine runtime ----------
keycloak_image_runtime() {
  step "Keycloak immagine runtime (deploy/sts images) nel namespace $KEYCLOAK_NS"
  run_sudo "Deploy images" bash -lc \
    "KUBECONFIG=/etc/rancher/k3s/k3s.yaml k3s kubectl -n '$KEYCLOAK_NS' get deploy -o jsonpath='{range .items[*]}{.metadata.name}{\"\\t\"}{range .spec.template.spec.containers[*]}{.image}{\" \"}{end}{\"\\n\"}{end}' \
    > '$ROOT_OUT/k8s/${KEYCLOAK_NS}.deploy_images.txt' 2>/dev/null || true"

  run_sudo "STS images" bash -lc \
    "KUBECONFIG=/etc/rancher/k3s/k3s.yaml k3s kubectl -n '$KEYCLOAK_NS' get sts -o jsonpath='{range .items[*]}{.metadata.name}{\"\\t\"}{range .spec.template.spec.containers[*]}{.image}{\" \"}{end}{\"\\n\"}{end}' \
    > '$ROOT_OUT/k8s/${KEYCLOAK_NS}.sts_images.txt' 2>/dev/null || true"

  run_sudo "Filtro righe con 'keycloak' (immagine effettiva)" bash -lc \
    "cat '$ROOT_OUT/k8s/${KEYCLOAK_NS}.deploy_images.txt' '$ROOT_OUT/k8s/${KEYCLOAK_NS}.sts_images.txt' 2>/dev/null | egrep -i 'keycloak' > '$ROOT_OUT/k8s/keycloak_images_detected.txt' || true; cat '$ROOT_OUT/k8s/keycloak_images_detected.txt' || true"
}

# ---------- 7) Repo storysizer ----------
repo_tar() {
  step "Repo storysizer -> tar"
  if sudo test -d /home/fra/storysizer; then
    run_sudo "Tar /home/fra/storysizer" bash -lc "tar -C /home/fra -czf '$ROOT_OUT/repo/storysizer.tgz' storysizer"
    run_sudo "Mostro dimensione tar repo" bash -lc "ls -lah '$ROOT_OUT/repo/storysizer.tgz'"
  else
    echo "/home/fra/storysizer non trovato"
    fail "Repo storysizer -> tar"
  fi
}

# ---------- 8) Zippone totale ----------
make_archive() {
  step "Creo archivio unico + sha256"
  if command -v zstd >/dev/null 2>&1; then
    run_sudo "Tar+zstd -> $ARCHIVE_ZST" bash -lc \
      "cd /root && tar -cf - 'FORMAT_TOTAL_$TS' | zstd -19 -T0 -o '$ARCHIVE_ZST'"
    run_sudo "SHA256 archive" bash -lc "sha256sum '$ARCHIVE_ZST' > '${ARCHIVE_ZST}.sha256'"
  else
    run_sudo "Tar+gzip -> $ARCHIVE_TGZ" bash -lc "cd /root && tar -czf '$ARCHIVE_TGZ' 'FORMAT_TOTAL_$TS'"
    run_sudo "SHA256 archive" bash -lc "sha256sum '$ARCHIVE_TGZ' > '${ARCHIVE_TGZ}.sha256'"
  fi
}

# ---------- 9) Summary ----------
summary() {
  step "SUMMARY (cose che ti servono subito)"
  echo "BUNDLE DIR: $ROOT_OUT"
  echo

  echo ">> KEYCLOAK CHART+VERSION (Helm):"
  sudo cat "$ROOT_OUT/helm/keycloak_release_line.txt" 2>/dev/null || echo "(non trovato)"
  echo

  echo ">> KEYCLOAK IMMAGINE RUNTIME:"
  sudo cat "$ROOT_OUT/k8s/keycloak_images_detected.txt" 2>/dev/null || echo "(non trovata)"
  echo

  echo ">> PV checksum result:"
  sudo cat "$ROOT_OUT/pv/sha256_check.txt" 2>/dev/null || echo "(checksum non disponibile)"
  echo

  echo ">> WARN TGZ < 50MB:"
  sudo cat "$ROOT_OUT/pv/WARN_small_archives_under_50MB.txt" 2>/dev/null || echo "(nessuno)"
  echo

  echo ">> Comandi per copiare fuori (dal tuo PC):"
  if [[ -f "$ARCHIVE_ZST" ]]; then
    echo "  rsync -avP root@<IP_FRASERVER>:$ARCHIVE_ZST $ARCHIVE_ZST.sha256 ."
    echo "  sha256sum -c $(basename "$ARCHIVE_ZST").sha256"
  else
    echo "  rsync -avP root@<IP_FRASERVER>:$ARCHIVE_TGZ $ARCHIVE_TGZ.sha256 ."
    echo "  sha256sum -c $(basename "$ARCHIVE_TGZ").sha256"
  fi
}

# ========= RUN ALL =========
mkdir_root_out
notes_base
ubuntu_inventory
pv_collect_and_verify
k8s_exports
cert_exports
helm_exports
keycloak_image_runtime
repo_tar
make_archive
summary
