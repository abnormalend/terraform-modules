#!/usr/bin/env bash
set -euo pipefail

# Defaults: use default AWS profile if PROFILE is unset/empty
PROFILE=${PROFILE:-}
REGION=${REGION:-us-east-2}

echo "[+] Using AWS profile=${PROFILE:-<default>} region=${REGION}"

cd "$(dirname "$0")"

# Detect terraform or tofu
if command -v terraform >/dev/null 2>&1; then
  TF_CMD=terraform
elif command -v tofu >/dev/null 2>&1; then
  TF_CMD=tofu
else
  echo "[!] Neither terraform nor tofu is installed or on PATH" >&2
  exit 127
fi

step() { echo -e "\n=== $1 ==="; }

step "$TF_CMD init"
$TF_CMD init -upgrade -input=false

step "$TF_CMD apply"
$TF_CMD apply -auto-approve -var="region=${REGION}" -var="profile=${PROFILE}"

FN_NAME=$($TF_CMD output -raw function_name)
if [[ -z "${FN_NAME}" ]]; then
  echo "[!] Failed to read function_name output" >&2
  exit 1
fi

echo "[+] Deployed function: ${FN_NAME}"

# Optional wait for propagation / update ready
WAIT_SECONDS=${WAIT_SECONDS:-}
if [[ -n "${WAIT_SECONDS}" ]]; then
  echo "[+] Waiting ${WAIT_SECONDS}s before testing..."
  sleep "${WAIT_SECONDS}"
fi

# Actively wait until Lambda LastUpdateStatus is Successful
echo "[+] Waiting for Lambda update to complete..."
ATTEMPTS=30
for i in $(seq 1 ${ATTEMPTS}); do
  STATUS=$(aws lambda get-function-configuration \
    --function-name "${FN_NAME}" \
    ${PROFILE:+--profile "${PROFILE}"} \
    --region "${REGION}" \
    --query 'LastUpdateStatus' --output text 2>/dev/null || echo "UNKNOWN")

  if [[ "${STATUS}" == "Successful" ]]; then
    echo "[+] Lambda update status: Successful"
    break
  elif [[ "${STATUS}" == "Failed" ]]; then
    REASON=$(aws lambda get-function-configuration \
      --function-name "${FN_NAME}" \
      ${PROFILE:+--profile "${PROFILE}"} \
      --region "${REGION}" \
      --query 'LastUpdateStatusReason' --output text 2>/dev/null || true)
    echo "[!] Lambda update failed: ${REASON}" >&2
    exit 1
  else
    echo "[.] Lambda update status: ${STATUS} (attempt ${i}/${ATTEMPTS})"
    sleep 2
  fi
done

# Invoke and evaluate success
step "invoke lambda"
TMP_OUT=$(mktemp)
PAYLOAD_FILE=$(mktemp)
echo '{"ping":"pong"}' >"${PAYLOAD_FILE}"

echo "[+] AWS CLI version: $(aws --version 2>&1)"

set +e
aws lambda invoke \
  --function-name "${FN_NAME}" \
  --payload fileb://"${PAYLOAD_FILE}" \
  ${PROFILE:+--profile "${PROFILE}"} \
  --region "${REGION}" \
  --cli-binary-format raw-in-base64-out \
  "${TMP_OUT}"
RC=$?
set -e

if [[ ${RC} -ne 0 ]]; then
  echo "[!] aws lambda invoke failed with exit code ${RC}" >&2
  exit ${RC}
fi

echo "[+] Invocation response:"
if command -v jq >/dev/null 2>&1; then
  # Pretty print full response
  jq '.' <"${TMP_OUT}" | sed -e 's/.*/    &/' || cat "${TMP_OUT}" | sed -e 's/.*/    &/'
else
  cat "${TMP_OUT}" | sed -e 's/.*/    &/'
fi

# Evaluate success by checking for ok:true either at top-level or within .body (API GW style)
if command -v jq >/dev/null 2>&1; then
  if jq -e '.ok == true' <"${TMP_OUT}" >/dev/null 2>&1; then
    echo "[✓] Test passed: handler returned ok:true (top-level)"
  elif jq -re '.body' <"${TMP_OUT}" >/dev/null 2>&1; then
    BODY_JSON=$(jq -r '.body' <"${TMP_OUT}" 2>/dev/null || echo '')
    if [[ -n "${BODY_JSON}" ]] && echo "${BODY_JSON}" | jq -e '.ok == true' >/dev/null 2>&1; then
      echo "[✓] Test passed: handler returned ok:true (inside .body)"
    else
      echo "[!] Test failed: handler did not return ok:true" >&2
      exit 2
    fi
  else
    echo "[!] Test failed: no ok:true found and no .body to inspect" >&2
    exit 2
  fi
else
  echo "[!] jq not found; cannot evaluate response. Install jq or inspect ${TMP_OUT}." >&2
  exit 2
fi

# Optional destroy
if [[ "${DESTROY:-}" == "1" ]]; then
  step "$TF_CMD destroy"
  $TF_CMD destroy -auto-approve -var="region=${REGION}" -var="profile=${PROFILE}"
fi
