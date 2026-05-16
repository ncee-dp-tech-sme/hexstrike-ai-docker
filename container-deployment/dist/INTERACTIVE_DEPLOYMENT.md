# HexStrike AI - Interactive Deployment Guide

This guide explains how to use the interactive deployment script to deploy HexStrike AI to OpenShift or Kubernetes clusters.

## Overview

The `deploy-interactive.sh` script provides a user-friendly, interactive way to deploy HexStrike AI with the following features:

- ✅ **Platform Detection**: Automatically detects OpenShift or Kubernetes
- ✅ **Interactive Configuration**: Prompts for all necessary settings
- ✅ **Authentication Support**: Built-in basic authentication with nginx proxy
- ✅ **Cross-Platform**: Works on Linux and macOS with Bash or ZSH
- ✅ **MCP Configuration**: Generates ready-to-use MCP client configuration

## Prerequisites

### For OpenShift
- OpenShift CLI (`oc`) installed
- Logged in to your OpenShift cluster: `oc login`
- Appropriate permissions to create resources

### For Kubernetes
- Kubernetes CLI (`kubectl`) installed
- Connected to your Kubernetes cluster
- Appropriate permissions to create resources

### Additional Requirements
- `htpasswd` or `openssl` (for password hashing)
- Bash or ZSH shell

## Quick Start

1. **Navigate to the deployment directory**:
   ```bash
   cd hexstrike-ocp
   ```

2. **Run the interactive deployment script**:
   ```bash
   ./deploy-interactive.sh
   ```

3. **Follow the prompts**:
   - Select your platform (OpenShift or Kubernetes)
   - Enter the namespace to deploy to
   - Configure authentication (username and password)
   - Confirm deployment

4. **Copy the MCP configuration** displayed at the end

## Deployment Steps Explained

### Step 1: Platform Detection
The script will automatically detect if you're connected to OpenShift or Kubernetes. If both are available, you'll be prompted to choose.

```
Which platform are you deploying to?
  1) OpenShift
  2) Kubernetes

Enter choice (1 or 2):
```

### Step 2: Namespace Configuration
Enter the namespace where you want to deploy HexStrike AI. The default is `hexstrike`.

```
Enter the namespace to deploy to:
Namespace [default: hexstrike]:
```

If the namespace doesn't exist, the script will offer to create it.

### Step 3: Authentication Configuration
Choose whether to enable basic authentication (recommended for production).

```
Enable basic authentication? (Recommended)
Enable authentication? (Y/n):
```

If enabled, you'll be prompted for:
- **Username** (default: admin)
- **Password** (hidden input)
- **Password confirmation**

**Security Note**: The password will not be displayed on screen.

### Step 4: Deployment
The script will:
1. Create authentication secret (if enabled)
2. Deploy nginx authentication proxy (if enabled)
3. Deploy the HexStrike AI application
4. Create external access (Route for OpenShift, Service for Kubernetes)
5. Wait for deployments to be ready

### Step 5: Configuration Output
After successful deployment, the script displays:
- MCP client configuration (ready to copy)
- Deployment summary
- Access URLs and test commands
- Useful management commands

## MCP Client Configuration

The script generates a complete MCP configuration that you can add to your `.bob/mcp.json` file:

```json
{
    "mcpServers": {
        "hexstrike-ai": {
            "command": "/path/to/python",
            "args": [
                "/path/to/hexstrike_mcp.py",
                "--server",
                "https://your-route-url/",
                "--timeout",
                "1800",
                "--username",
                "admin",
                "--password",
                "your-password"
            ],
            "disabled": false,
            "timeout": 1800
        }
    }
}
```

**Important**: Update the paths to match your local setup:
- Replace `/path/to/python` with your Python interpreter path
- Replace `/path/to/hexstrike_mcp.py` with the actual script path

## Testing the Deployment

### OpenShift
```bash
# Test with authentication
curl -u admin:your-password https://your-route-url/health

# View logs
oc logs -l app=hexstrike-ai-docker -n hexstrike -f

# View pods
oc get pods -n hexstrike
```

### Kubernetes
```bash
# Port forward (if needed)
kubectl port-forward svc/hexstrike-nginx-auth 8080:8080 -n hexstrike

# Test with authentication
curl -u admin:your-password http://localhost:8080/health

# View logs
kubectl logs -l app=hexstrike-ai-docker -n hexstrike -f

# View pods
kubectl get pods -n hexstrike
```

## Authentication Details

When authentication is enabled, the script:

1. **Generates a secure password hash** using bcrypt (via htpasswd)
2. **Creates a Kubernetes secret** containing the htpasswd file
3. **Deploys an nginx proxy** that:
   - Sits in front of the HexStrike AI application
   - Enforces basic authentication
   - Proxies authenticated requests to the backend

### Architecture with Authentication

```
Internet → Route/Ingress → Nginx Auth Proxy → HexStrike AI
                            (Basic Auth)        (Port 8888)
                            (Port 8080)
```

### Architecture without Authentication

```
Internet → Route/Ingress → HexStrike AI
                            (Port 8888)
```

## Troubleshooting

### Script fails with "command not found"
- **OpenShift**: Install the `oc` CLI
- **Kubernetes**: Install the `kubectl` CLI
- **Password hashing**: Install `htpasswd` (usually in `apache2-utils` package) or ensure `openssl` is available

### Authentication not working
1. Check if the secret was created:
   ```bash
   oc get secret hexstrike-basic-auth -n hexstrike
   ```

2. Check nginx proxy logs:
   ```bash
   oc logs -l app=hexstrike-nginx-auth -n hexstrike
   ```

3. Verify the password hash:
   ```bash
   oc get secret hexstrike-basic-auth -n hexstrike -o jsonpath='{.data.htpasswd}' | base64 -d
   ```

### Deployment not ready
1. Check pod status:
   ```bash
   oc get pods -n hexstrike
   ```

2. View pod events:
   ```bash
   oc describe pod -l app=hexstrike-ai-docker -n hexstrike
   ```

3. Check logs:
   ```bash
   oc logs -l app=hexstrike-ai-docker -n hexstrike
   ```

### Route not accessible (OpenShift)
1. Verify route exists:
   ```bash
   oc get route hexstrike-ai-docker -n hexstrike
   ```

2. Check route details:
   ```bash
   oc describe route hexstrike-ai-docker -n hexstrike
   ```

## Updating the Deployment

### Change Password
1. Run the script again with new credentials
2. The script will update the existing secret
3. Restart the nginx proxy:
   ```bash
   oc rollout restart deployment/hexstrike-nginx-auth -n hexstrike
   ```

### Disable Authentication
1. Delete the nginx proxy:
   ```bash
   oc delete deployment hexstrike-nginx-auth -n hexstrike
   oc delete service hexstrike-nginx-auth -n hexstrike
   ```

2. Update the route to point directly to the application:
   ```bash
   oc apply -f route.yaml -n hexstrike
   ```

### Enable Authentication (if previously disabled)
1. Run the script again
2. Choose to enable authentication
3. The script will deploy the nginx proxy

## Uninstalling

To remove the deployment:

```bash
# OpenShift
oc delete all -l app=hexstrike-ai-docker -n hexstrike
oc delete all -l app=hexstrike-nginx-auth -n hexstrike
oc delete secret hexstrike-basic-auth -n hexstrike
oc delete configmap nginx-auth-config -n hexstrike
oc delete serviceaccount hexstrike-sa -n hexstrike

# Kubernetes
kubectl delete all -l app=hexstrike-ai-docker -n hexstrike
kubectl delete all -l app=hexstrike-nginx-auth -n hexstrike
kubectl delete secret hexstrike-basic-auth -n hexstrike
kubectl delete configmap nginx-auth-config -n hexstrike
kubectl delete serviceaccount hexstrike-sa -n hexstrike
```

## Security Best Practices

1. **Use Strong Passwords**: Minimum 16 characters with mixed case, numbers, and symbols
2. **Rotate Credentials**: Change passwords regularly
3. **Secure Storage**: Store credentials in a password manager
4. **Network Policies**: Consider implementing network policies to restrict access
5. **TLS/SSL**: Always use HTTPS/TLS for external access (enabled by default on OpenShift routes)
6. **RBAC**: Follow principle of least privilege for service accounts

## Advanced Configuration

### Custom Namespace
```bash
./deploy-interactive.sh
# When prompted, enter your custom namespace
```

### Multiple Deployments
You can deploy multiple instances by using different namespaces:
```bash
# First deployment
./deploy-interactive.sh  # Use namespace: hexstrike-prod

# Second deployment
./deploy-interactive.sh  # Use namespace: hexstrike-dev
```

### Integration with CI/CD
For automated deployments, you can pre-configure values:
```bash
# Set environment variables (not recommended for passwords)
export HEXSTRIKE_NAMESPACE="hexstrike"
export HEXSTRIKE_USERNAME="admin"

# Run script (will still prompt for password)
./deploy-interactive.sh
```

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review pod logs for error messages
3. Verify all prerequisites are met
4. Ensure you have appropriate cluster permissions

## Made with Bob
2026-05-16: Created interactive deployment documentation