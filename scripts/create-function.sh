#!/usr/bin/env bash
#
# Crée une Azure Function App (Python 3.11, Serverless) et déploie la fonction
# HTTP "hello". Équivalent CLI de la Partie 2 du TP.
# Prérequis : az CLI connecté (az login).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/.env"
  set +a
fi

RESOURCE_GROUP="${RESOURCE_GROUP:-mon-groupe-de-ressources}"
FUNC_APP_NAME="${FUNC_APP_NAME:-api-func-melvin}"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-stfuncmelvinprf26}"
LOCATION="francecentral"
RUNTIME="python"
RUNTIME_VERSION="3.11"
FUNCTIONS_VERSION="4"
FUNC_SRC="${PROJECT_DIR}/funcapp"
ZIP_PATH="$(mktemp -d)/funcapp.zip"

echo "==> Vérification de la connexion Azure..."
az account show >/dev/null 2>&1 || { echo "Pas connecté. Lancez 'az login'."; exit 1; }

echo "==> Vérification du groupe de ressources '${RESOURCE_GROUP}'..."
az group show --name "${RESOURCE_GROUP}" >/dev/null 2>&1 \
  || { echo "Groupe de ressources '${RESOURCE_GROUP}' introuvable."; exit 1; }

echo "==> Vérification du code source '${FUNC_SRC}'..."
[[ -f "${FUNC_SRC}/host.json" && -f "${FUNC_SRC}/hello/__init__.py" ]] \
  || { echo "Projet function introuvable dans ${FUNC_SRC}."; exit 1; }

# Toute Function App exige un compte de stockage (jobs, déploiement).
if az storage account show --name "${STORAGE_ACCOUNT}" --resource-group "${RESOURCE_GROUP}" >/dev/null 2>&1; then
  echo "==> Compte de stockage '${STORAGE_ACCOUNT}' déjà présent."
else
  echo "==> Création du compte de stockage '${STORAGE_ACCOUNT}'..."
  az storage account create \
    --name "${STORAGE_ACCOUNT}" \
    --resource-group "${RESOURCE_GROUP}" \
    --location "${LOCATION}" \
    --sku Standard_LRS
fi

if az functionapp show --name "${FUNC_APP_NAME}" --resource-group "${RESOURCE_GROUP}" >/dev/null 2>&1; then
  echo "==> Function App '${FUNC_APP_NAME}' déjà présente."
else
  echo "==> Création de la Function App '${FUNC_APP_NAME}'..."
  az functionapp create \
    --name "${FUNC_APP_NAME}" \
    --resource-group "${RESOURCE_GROUP}" \
    --storage-account "${STORAGE_ACCOUNT}" \
    --consumption-plan-location "${LOCATION}" \
    --runtime "${RUNTIME}" \
    --runtime-version "${RUNTIME_VERSION}" \
    --functions-version "${FUNCTIONS_VERSION}" \
    --os-type Linux
fi

# SKU réel = Flex Consumption (défaut Python). Ne PAS poser SCM_DO_BUILD_DURING_DEPLOYMENT
# ni ENABLE_ORYX_BUILD : rejetés par ce SKU et corrompent le mode build du conteneur SCM.

echo "==> Empaquetage du code..."
if command -v zip >/dev/null 2>&1; then
  ( cd "${FUNC_SRC}" && zip -r -q "${ZIP_PATH}" . )
else
  python3 - "${FUNC_SRC}" "${ZIP_PATH}" <<'PY'
import os, sys, zipfile
src, dst = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as z:
    for root, _, files in os.walk(src):
        for f in files:
            full = os.path.join(root, f)
            z.write(full, os.path.relpath(full, src))
PY
fi

# Flex Consumption n'accepte QUE « One Deploy » (POST SCM /api/publish).
# 'az ... config-zip' (az 2.86) route à tort vers Kudu/Oryx : on appelle One Deploy en REST.
APP_ID=$(az functionapp show --name "${FUNC_APP_NAME}" --resource-group "${RESOURCE_GROUP}" --query id -o tsv)
APP_HOST=$(az rest --method get \
  --url "https://management.azure.com${APP_ID}?api-version=2023-12-01" \
  --query "properties.defaultHostName" -o tsv)
SCM_HOST="${APP_HOST/./.scm.}"

# Restart : resync le conteneur SCM, sinon faux « settings not supported » si un
# déploiement précédent a pollué le mode build.
echo "==> Resync du conteneur de déploiement (restart)..."
az functionapp restart --name "${FUNC_APP_NAME}" --resource-group "${RESOURCE_GROUP}"
sleep 15

echo "==> Déploiement One Deploy vers '${SCM_HOST}'..."
TOKEN=$(az account get-access-token --resource https://management.azure.com --query accessToken -o tsv)
DEPLOY_ID=$(curl -sS -X POST "https://${SCM_HOST}/api/publish?type=zip" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/zip" \
  --data-binary @"${ZIP_PATH}" | tr -d '"')
echo "    deployment id: ${DEPLOY_ID}"

echo "==> Attente de la fin du déploiement..."
for _ in $(seq 1 40); do
  DONE=$(curl -sS "https://${SCM_HOST}/api/deployments/${DEPLOY_ID}" \
    -H "Authorization: Bearer ${TOKEN}" \
    | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('status'),d.get('complete'))" 2>/dev/null || true)
  echo "    status: ${DONE}"
  case "${DONE}" in
    "4 True") echo "    déploiement réussi."; break ;;
    "3 True") echo "    ÉCHEC du déploiement (voir log SCM)."; exit 1 ;;
  esac
  sleep 5
done

echo "==> Déploiement terminé."
echo "Function App : https://${APP_HOST}"
echo "Endpoint API : https://${APP_HOST}/api/hello"
echo
echo "Test : curl https://${APP_HOST}/api/hello"
