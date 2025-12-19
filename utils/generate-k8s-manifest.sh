#!/bin/bash

# Script to generate Kubernetes manifest for BloxOne deployment on AKS
# This generates a k8s manifest similar to the Azure VM deployment

K8S_MANIFEST_TEMPLATE="k8s/bloxone-deployment.yaml"
OUTPUT_FILE="k8s-manifest-generated.yaml"

function usage() {
    echo -e "\nUsage: $0 [OPTIONS]"
    echo -e "\nOptions:"
    echo -e "  jointoken=<token>       Join token for BloxOne (required)"
    echo -e "  httpProxy=<proxy_url>   HTTP proxy URL (optional)"
    echo -e "  namespace=<namespace>   Kubernetes namespace (default: bloxone)"
    echo -e "  replicas=<number>       Number of replicas (default: 1)"
    echo -e "  output=<file>           Output file path (default: k8s-manifest-generated.yaml)"
    echo -e "\nExample:"
    echo -e "  $0 jointoken=mytoken123 httpProxy=http://proxy.example.com:8080"
    echo -e "\nYou can get the jointoken from your BloxOne portal."
}

# Default values
NAMESPACE="bloxone"
REPLICAS="1"

# Parse arguments
for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    KEY_LENGTH=${#KEY}
    VALUE="${ARGUMENT:$KEY_LENGTH+1}"
    
    case "$KEY" in
        jointoken)      JOINTOKEN="$VALUE" ;;
        httpProxy)      HTTP_PROXY="$VALUE" ;;
        namespace)      NAMESPACE="$VALUE" ;;
        replicas)       REPLICAS="$VALUE" ;;
        output)         OUTPUT_FILE="$VALUE" ;;
        help)           usage; exit 0 ;;
        *)              echo "Unknown parameter: $KEY"; usage; exit 1 ;;
    esac
done

# Validate required parameters
if [ -z "$JOINTOKEN" ]; then
    echo "Error: jointoken is required"
    usage
    exit 1
fi

if [ ! -f "$K8S_MANIFEST_TEMPLATE" ]; then
    echo "Error: Template file $K8S_MANIFEST_TEMPLATE not found"
    exit 1
fi

echo "Generating Kubernetes manifest..."
echo "  Namespace: $NAMESPACE"
echo "  Replicas: $REPLICAS"
echo "  Join Token: ${JOINTOKEN:0:10}..."
[ -n "$HTTP_PROXY" ] && echo "  HTTP Proxy: $HTTP_PROXY"

# Copy template to output
cp "$K8S_MANIFEST_TEMPLATE" "$OUTPUT_FILE"

# Escape special characters in values for sed
JOINTOKEN_ESCAPED=$(echo "$JOINTOKEN" | sed 's/[&/\]/\\&/g')
NAMESPACE_ESCAPED=$(echo "$NAMESPACE" | sed 's/[&/\]/\\&/g')

# Replace placeholders
sed -i "s/__JOINTOKEN__/$JOINTOKEN_ESCAPED/g" "$OUTPUT_FILE"
sed -i "s/replicas: 1/replicas: $REPLICAS/g" "$OUTPUT_FILE"

# Update namespace if not default
if [ "$NAMESPACE" != "bloxone" ]; then
    sed -i "s/namespace: bloxone/namespace: $NAMESPACE_ESCAPED/g" "$OUTPUT_FILE"
    sed -i "s/name: bloxone$/name: $NAMESPACE_ESCAPED/g" "$OUTPUT_FILE"
fi

# Add HTTP proxy if provided
if [ -n "$HTTP_PROXY" ]; then
    HTTP_PROXY_ESCAPED=$(echo "$HTTP_PROXY" | sed 's/[&/\]/\\&/g')
    # Add httpProxy to ConfigMap data section (right after the data: line in ConfigMap section)
    sed -i '/^  cloud-config.yaml: |$/i\  httpProxy: "'"$HTTP_PROXY_ESCAPED"'"' "$OUTPUT_FILE"
    # Add access_https_proxy to cloud-config (after jointoken line, properly indented)
    sed -i '/^      jointoken: /a\      access_https_proxy: '"$HTTP_PROXY" "$OUTPUT_FILE"
fi

echo ""
echo "Kubernetes manifest generated successfully: $OUTPUT_FILE"
echo ""
echo "To deploy to your AKS cluster, run:"
echo "  kubectl apply -f $OUTPUT_FILE"
echo ""
echo "To verify the deployment:"
echo "  kubectl get all -n $NAMESPACE"
echo "  kubectl get pods -n $NAMESPACE"
echo ""
