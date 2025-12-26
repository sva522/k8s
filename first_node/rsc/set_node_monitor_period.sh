#!/bin/bash

# Script pour modifier les paramètres de monitoring d'un cluster Kubernetes
# Créé avec kubeadm init

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Vérification des privilèges root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Ce script doit être exécuté en tant que root${NC}"
   exit 1
fi

echo -e "${GREEN}=== Configuration des paramètres de monitoring Kubernetes ===${NC}\n"

# Paramètres à configurer (vous pouvez les modifier selon vos besoins)
NODE_MONITOR_PERIOD="5s"              # Fréquence de vérification de l'état des nodes
NODE_MONITOR_GRACE_PERIOD="40s"       # Délai avant de marquer un node comme Unknown
POD_EVICTION_TIMEOUT="30s"            # Délai avant d'évacuer les pods d'un node défaillant
NODE_STATUS_UPDATE_FREQUENCY="10s"    # Fréquence de mise à jour du statut par kubelet

echo "Paramètres qui seront appliqués :"
echo "  - node-monitor-period: $NODE_MONITOR_PERIOD"
echo "  - node-monitor-grace-period: $NODE_MONITOR_GRACE_PERIOD"
echo "  - pod-eviction-timeout: $POD_EVICTION_TIMEOUT"
echo "  - nodeStatusUpdateFrequency: $NODE_STATUS_UPDATE_FREQUENCY"
echo ""

read -p "Continuer ? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Opération annulée"
    exit 0
fi

# Backup des fichiers de configuration
BACKUP_DIR="/root/k8s-config-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo -e "\n${YELLOW}Création des backups dans $BACKUP_DIR${NC}"
cp /etc/kubernetes/manifests/kube-controller-manager.yaml "$BACKUP_DIR/" 2>/dev/null || true
cp /var/lib/kubelet/config.yaml "$BACKUP_DIR/" 2>/dev/null || true

# 1. Modification du kube-controller-manager
echo -e "\n${GREEN}[1/3] Configuration du kube-controller-manager${NC}"

CONTROLLER_MANIFEST="/etc/kubernetes/manifests/kube-controller-manager.yaml"

if [ ! -f "$CONTROLLER_MANIFEST" ]; then
    echo -e "${RED}Erreur: $CONTROLLER_MANIFEST introuvable${NC}"
    exit 1
fi

# Fonction pour ajouter ou mettre à jour un paramètre
update_controller_param() {
    local param=$1
    local value=$2
    
    if grep -q "\-\-${param}=" "$CONTROLLER_MANIFEST"; then
        # Le paramètre existe, on le met à jour
        sed -i "s|--${param}=.*|--${param}=${value}|" "$CONTROLLER_MANIFEST"
        echo "  ✓ Paramètre --${param} mis à jour"
    else
        # Le paramètre n'existe pas, on l'ajoute
        sed -i "/--controllers=/a\    - --${param}=${value}" "$CONTROLLER_MANIFEST"
        echo "  ✓ Paramètre --${param} ajouté"
    fi
}

update_controller_param "node-monitor-period" "$NODE_MONITOR_PERIOD"
update_controller_param "node-monitor-grace-period" "$NODE_MONITOR_GRACE_PERIOD"
update_controller_param "pod-eviction-timeout" "$POD_EVICTION_TIMEOUT"

# 2. Modification de la configuration kubelet sur le master
echo -e "\n${GREEN}[2/3] Configuration du kubelet (master)${NC}"

KUBELET_CONFIG="/var/lib/kubelet/config.yaml"

if [ ! -f "$KUBELET_CONFIG" ]; then
    echo -e "${RED}Erreur: $KUBELET_CONFIG introuvable${NC}"
    exit 1
fi

# Mise à jour du nodeStatusUpdateFrequency
if grep -q "nodeStatusUpdateFrequency:" "$KUBELET_CONFIG"; then
    sed -i "s|nodeStatusUpdateFrequency:.*|nodeStatusUpdateFrequency: ${NODE_STATUS_UPDATE_FREQUENCY}|" "$KUBELET_CONFIG"
    echo "  ✓ nodeStatusUpdateFrequency mis à jour"
else
    echo "nodeStatusUpdateFrequency: ${NODE_STATUS_UPDATE_FREQUENCY}" >> "$KUBELET_CONFIG"
    echo "  ✓ nodeStatusUpdateFrequency ajouté"
fi

# Redémarrage du kubelet
systemctl restart kubelet
echo "  ✓ Kubelet redémarré"

# 3. Attente du redémarrage du kube-controller-manager
echo -e "\n${GREEN}[3/3] Attente du redémarrage du kube-controller-manager${NC}"
echo "  Le kube-controller-manager va redémarrer automatiquement..."

sleep 10

# Vérification que le pod redémarre
for i in {1..30}; do
    if kubectl get pod -n kube-system -l component=kube-controller-manager 2>/dev/null | grep -q "Running"; then
        echo -e "  ${GREEN}✓ kube-controller-manager redémarré avec succès${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

echo ""

# Affichage des informations de configuration pour les workers
echo -e "\n${YELLOW}=== IMPORTANT ===${NC}"
echo "Pour appliquer ces paramètres sur les nodes workers, exécutez sur chaque worker :"
echo ""
echo -e "${YELLOW}sudo sed -i 's|nodeStatusUpdateFrequency:.*|nodeStatusUpdateFrequency: ${NODE_STATUS_UPDATE_FREQUENCY}|' /var/lib/kubelet/config.yaml${NC}"
echo -e "${YELLOW}sudo systemctl restart kubelet${NC}"
echo ""

# Vérification finale
echo -e "\n${GREEN}=== Vérification de la configuration ===${NC}"
echo ""
echo "Controller Manager :"
kubectl get pod -n kube-system -l component=kube-controller-manager -o yaml | grep -A 3 "node-monitor" || echo "  Paramètres appliqués (vérification manuelle recommandée)"
echo ""
echo "Kubelet (ce node) :"
grep nodeStatusUpdateFrequency "$KUBELET_CONFIG"

echo -e "\n${GREEN}Configuration terminée !${NC}"
echo -e "Les backups ont été sauvegardés dans : ${BACKUP_DIR}"
