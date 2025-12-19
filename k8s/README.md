# Kubernetes Deployment for BloxOne on Azure AKS

This directory contains Kubernetes manifests for deploying BloxOne on Azure Kubernetes Service (AKS).

## Overview

The Kubernetes deployment provides an alternative to the VM-based deployment offered by the Azure ARM templates. This allows you to run BloxOne as a containerized application on AKS with the same configuration options.

## Prerequisites

- Azure Kubernetes Service (AKS) cluster
- `kubectl` configured to access your AKS cluster
- BloxOne join token from your BloxOne portal

## Quick Start

### Option 1: Using the Generation Script (Recommended)

Generate a customized Kubernetes manifest with your specific parameters:

```bash
cd utils
./generate-k8s-manifest.sh jointoken=<your-token> httpProxy=<proxy-url> output=../my-bloxone-manifest.yaml
```

Then deploy:

```bash
kubectl apply -f my-bloxone-manifest.yaml
```

### Option 2: Manual Configuration

1. Copy the template or example:
   ```bash
   # Use the template (without proxy example)
   cp k8s/bloxone-deployment.yaml my-bloxone-deployment.yaml
   
   # OR use the example (with proxy configuration)
   cp k8s/bloxone-deployment-example.yaml my-bloxone-deployment.yaml
   ```

2. Edit the manifest and replace:
   - `__JOINTOKEN__` or `YOUR_JOIN_TOKEN_HERE` with your actual join token
   - Update `httpProxy` value if using proxy (or remove the httpProxy lines if not needed)

3. Deploy to your cluster:
   ```bash
   kubectl apply -f my-bloxone-deployment.yaml
   ```

## Configuration Options

### Required Parameters

- **jointoken**: Join token for connecting to your BloxOne platform (obtained from BloxOne portal)

### Optional Parameters

- **httpProxy**: HTTP proxy URL if your environment requires proxy for external communication
- **namespace**: Kubernetes namespace (default: `bloxone`)
- **replicas**: Number of replicas for the deployment (default: `1`)

## Using the Generation Script

The `utils/generate-k8s-manifest.sh` script helps you generate a properly configured manifest:

```bash
./generate-k8s-manifest.sh [OPTIONS]

Options:
  jointoken=<token>       Join token for BloxOne (required)
  httpProxy=<proxy_url>   HTTP proxy URL (optional)
  namespace=<namespace>   Kubernetes namespace (default: bloxone)
  replicas=<number>       Number of replicas (default: 1)
  output=<file>           Output file path (default: k8s-manifest-generated.yaml)

Example:
  ./generate-k8s-manifest.sh jointoken=mytoken123 httpProxy=http://proxy.example.com:8080
```

## Manifest Components

The Kubernetes deployment includes:

1. **Namespace**: Isolated namespace for BloxOne resources
2. **ConfigMap**: Contains cloud-config data with join token and tags
3. **Deployment**: Defines the BloxOne container deployment
4. **Service**: LoadBalancer service exposing DNS (TCP/UDP port 53) and HTTPS (port 443)
5. **Secret**: Stores sensitive data like the join token securely

## Verifying the Deployment

After deploying, verify the status:

```bash
# Check all resources in the bloxone namespace
kubectl get all -n bloxone

# Check pod status
kubectl get pods -n bloxone

# Check service status and external IP
kubectl get svc -n bloxone

# View pod logs
kubectl logs -n bloxone deployment/bloxone
```

## Architecture Comparison

### VM Deployment (ARM Templates)
- Deploys BloxOne as a virtual machine
- Uses cloud-init for configuration
- Suitable for traditional VM-based infrastructure

### Kubernetes Deployment (K8s Manifests)
- Deploys BloxOne as a containerized application
- Uses ConfigMaps and Secrets for configuration
- Suitable for container orchestration platforms like AKS
- Easier to scale and manage in cloud-native environments

## Features

Both deployment methods support the same core features:

- ✅ Join token configuration
- ✅ HTTP proxy support
- ✅ Tag support (DeployedFrom: AZURE-Marketplace vs AZURE-AKS)
- ✅ Azure integration

## Troubleshooting

### Pod not starting
```bash
kubectl describe pod -n bloxone <pod-name>
kubectl logs -n bloxone <pod-name>
```

### Service not getting external IP
Check the LoadBalancer service status:
```bash
kubectl describe svc -n bloxone bloxone-service
```

Ensure your AKS cluster has the Azure Load Balancer configured properly.

### Configuration issues
Verify the ConfigMap and Secret:
```bash
kubectl get configmap -n bloxone bloxone-config -o yaml
kubectl get secret -n bloxone bloxone-secret -o yaml
```

## Cleanup

To remove the BloxOne deployment:

```bash
kubectl delete -f my-bloxone-deployment.yaml
```

Or delete the namespace:

```bash
kubectl delete namespace bloxone
```

## Notes

- The manifest uses `infoblox/bloxone:latest` as a placeholder image. Update this to the actual BloxOne container image from your registry.
- The join token is stored in both a Secret (for security) and ConfigMap (for backward compatibility with cloud-config format).
- For production deployments, consider implementing:
  - Resource limits and requests
  - Persistent volumes for data
  - Network policies for security
  - Horizontal Pod Autoscaling (HPA)
  - Pod Disruption Budgets (PDB)

## Files in this Directory

- **`bloxone-deployment.yaml`**: Base template Kubernetes manifest with placeholders (`__JOINTOKEN__`)
- **`bloxone-deployment-example.yaml`**: Example manifest with placeholder values showing both jointoken and httpProxy configuration
- **`README.md`**: This documentation file

## Related Files

- `../utils/generate-k8s-manifest.sh`: Script to generate customized manifests from the template
- `../main/mainTemplate.json`: ARM template for VM deployment (alternative deployment method)
