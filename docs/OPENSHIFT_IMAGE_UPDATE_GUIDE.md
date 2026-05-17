# OpenShift: Force Image Update Guide

Complete guide for forcing container image updates in existing OpenShift pods.

## Table of Contents

1. [Overview](#overview)
2. [Method 1: Rollout Restart](#method-1-rollout-restart)
3. [Method 2: Delete Pod](#method-2-delete-pod)
4. [Method 3: Update Image Pull Policy](#method-3-update-image-pull-policy)
5. [Method 4: Trigger New Deployment](#method-4-trigger-new-deployment)
6. [Method 5: Image Stream Tags](#method-5-image-stream-tags)
7. [Method 6: Manual Image Update](#method-6-manual-image-update)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

---

## Overview

OpenShift caches container images locally on nodes. When you update an image in a registry with the same tag (e.g., `latest`), existing pods won't automatically pull the new version. This guide covers multiple methods to force image updates.

**Key Concepts:**
- **Image Pull Policy**: Controls when images are pulled (`Always`, `IfNotPresent`, `Never`)
- **Deployment/DeploymentConfig**: Manages pod lifecycle and rolling updates
- **Image Streams**: OpenShift-specific abstraction for managing container images

---

## Method 1: Rollout Restart

**Best for:** Production environments requiring zero-downtime updates.

### Description
Triggers a rolling restart of all pods in a deployment, pulling fresh images if the pull policy allows.

### Commands

```bash
# For Deployments
oc rollout restart deployment/<deployment-name>

# For DeploymentConfigs
oc rollout restart dc/<deploymentconfig-name>

# Check rollout status
oc rollout status deployment/<deployment-name>

# View rollout history
oc rollout history deployment/<deployment-name>
```

### Example

```bash
# Restart deployment
oc rollout restart deployment/my-app

# Monitor progress
oc rollout status deployment/my-app

# Verify new pods are running
oc get pods -l app=my-app
```

### Advantages
- Zero downtime (rolling update)
- Preserves deployment history
- Works with existing configurations
- Safe for production

### Limitations
- Only pulls new images if `imagePullPolicy: Always` is set
- Requires deployment/deploymentconfig resource

---

## Method 2: Delete Pod

**Best for:** Development/testing environments or single-pod updates.

### Description
Manually delete pods to force the controller to recreate them with fresh images.

### Commands

```bash
# Delete specific pod
oc delete pod <pod-name>

# Delete all pods with label
oc delete pods -l app=<app-name>

# Force delete (if pod is stuck)
oc delete pod <pod-name> --grace-period=0 --force

# Watch pod recreation
oc get pods -w
```

### Example

```bash
# Delete pod
oc delete pod my-app-7d8f9c5b6-xk2lm

# Verify new pod created
oc get pods -l app=my-app

# Check new pod is using updated image
oc describe pod <new-pod-name> | grep Image:
```

### Advantages
- Simple and immediate
- Works for any pod
- No configuration changes needed

### Limitations
- Causes downtime for single-replica deployments
- Manual process for multiple pods
- Only pulls new images if `imagePullPolicy: Always`

---

## Method 3: Update Image Pull Policy

**Best for:** Ensuring pods always pull latest images.

### Description
Change the image pull policy to `Always`, then restart pods to force image pulls.

### Commands

```bash
# Edit deployment
oc edit deployment/<deployment-name>

# Or patch directly
oc patch deployment/<deployment-name> -p \
  '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","imagePullPolicy":"Always"}]}}}}'

# Then restart
oc rollout restart deployment/<deployment-name>
```

### Example YAML

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: my-container
        image: registry.example.com/my-app:latest
        imagePullPolicy: Always  # Add or change this line
```

### Advantages
- Ensures fresh images on every pod restart
- Permanent solution
- Works with any restart method

### Limitations
- Increases network traffic
- Slower pod startup times
- May hit registry rate limits

---

## Method 4: Trigger New Deployment

**Best for:** Forcing updates without changing image pull policy.

### Description
Trigger a new deployment by adding/updating annotations or environment variables.

### Commands

```bash
# Add annotation to trigger rollout
oc patch deployment/<deployment-name> -p \
  "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"force-update\":\"$(date +%s)\"}}}}}"

# Or add/update environment variable
oc set env deployment/<deployment-name> FORCE_UPDATE="$(date +%s)"

# Remove the env var later if needed
oc set env deployment/<deployment-name> FORCE_UPDATE-
```

### Example

```bash
# Trigger update with timestamp annotation
oc patch deployment/my-app -p \
  "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"force-update\":\"$(date +%s)\"}}}}}"

# Verify rollout
oc rollout status deployment/my-app
```

### Advantages
- Forces new deployment
- Works regardless of image pull policy
- Trackable via annotations

### Limitations
- Adds metadata to pod spec
- Requires cleanup if using env vars

---

## Method 5: Image Stream Tags

**Best for:** OpenShift-native image management.

### Description
Use OpenShift Image Streams to manage image versions and trigger automatic deployments.

### Commands

```bash
# Import new image to image stream
oc import-image <imagestream-name>:<tag> --from=<external-registry/image:tag> --confirm

# Check image stream
oc describe is/<imagestream-name>

# Manually trigger deployment from image stream
oc set triggers deployment/<deployment-name> --from-image=<imagestream-name>:<tag> --containers=<container-name>
```

### Example

```bash
# Import updated image
oc import-image my-app:latest \
  --from=docker.io/myorg/my-app:latest \
  --confirm

# Verify import
oc describe is/my-app

# Deployment will auto-update if trigger is configured
oc get deployment/my-app -o yaml | grep -A5 triggers
```

### Example ImageStream YAML

```yaml
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  name: my-app
spec:
  lookupPolicy:
    local: false
  tags:
  - name: latest
    from:
      kind: DockerImage
      name: docker.io/myorg/my-app:latest
    importPolicy:
      scheduled: true  # Auto-import on schedule
    referencePolicy:
      type: Source
```

### Advantages
- OpenShift-native solution
- Automatic deployment triggers
- Scheduled imports available
- Image change tracking

### Limitations
- OpenShift-specific (not portable)
- Requires image stream setup
- Additional abstraction layer

---

## Method 6: Manual Image Update

**Best for:** Changing to a different image or tag.

### Commands

```bash
# Update image directly
oc set image deployment/<deployment-name> <container-name>=<new-image:tag>

# Example with specific tag
oc set image deployment/my-app my-container=registry.example.com/my-app:v2.0

# Verify update
oc describe deployment/my-app | grep Image:
```

### Example

```bash
# Update to new version
oc set image deployment/my-app \
  my-container=docker.io/myorg/my-app:v2.1.0

# Check rollout
oc rollout status deployment/my-app

# Rollback if needed
oc rollout undo deployment/my-app
```

### Advantages
- Explicit version control
- Clear audit trail
- Easy rollback

### Limitations
- Requires knowing exact image reference
- Manual process

---

## Best Practices

### 1. Use Specific Image Tags

```bash
# Good: Specific version
image: registry.example.com/my-app:v1.2.3

# Avoid: Mutable tags
image: registry.example.com/my-app:latest
```

### 2. Set Image Pull Policy Appropriately

```yaml
# Production: Use specific tags with IfNotPresent
imagePullPolicy: IfNotPresent
image: my-app:v1.2.3

# Development: Use Always with latest
imagePullPolicy: Always
image: my-app:latest
```

### 3. Configure Image Stream Triggers

```bash
# Enable automatic deployments on image changes
oc set triggers deployment/my-app \
  --from-image=my-app:latest \
  --containers=my-container
```

### 4. Use Rolling Updates

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0  # Zero downtime
```

### 5. Verify Image Updates

```bash
# Check current image
oc get deployment/my-app -o jsonpath='{.spec.template.spec.containers[0].image}'

# Check running pod image
oc get pod <pod-name> -o jsonpath='{.spec.containers[0].image}'

# Compare image digests
oc describe pod <pod-name> | grep "Image ID:"
```

---

## Troubleshooting

### Issue: Pod Not Pulling New Image

**Symptoms:**
- Pod restarts but uses cached image
- `oc describe pod` shows old image ID

**Solutions:**

1. Check image pull policy:
```bash
oc get deployment/my-app -o yaml | grep imagePullPolicy
```

2. Set to Always and restart:
```bash
oc patch deployment/my-app -p \
  '{"spec":{"template":{"spec":{"containers":[{"name":"my-container","imagePullPolicy":"Always"}]}}}}'
oc rollout restart deployment/my-app
```

3. Delete local image cache (requires node access):
```bash
# SSH to node
oc debug node/<node-name>
chroot /host
crictl rmi <image-id>
```

### Issue: ImagePullBackOff Error

**Symptoms:**
- Pod stuck in `ImagePullBackOff` state
- Error: "Failed to pull image"

**Solutions:**

1. Check image exists:
```bash
oc describe pod <pod-name> | grep -A10 Events
```

2. Verify registry credentials:
```bash
oc get secrets
oc describe secret <pull-secret-name>
```

3. Create/update pull secret:
```bash
oc create secret docker-registry my-pull-secret \
  --docker-server=registry.example.com \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email>

oc secrets link default my-pull-secret --for=pull
```

### Issue: Deployment Not Triggering

**Symptoms:**
- Image updated but deployment unchanged
- No new pods created

**Solutions:**

1. Check deployment triggers:
```bash
oc describe deployment/my-app | grep -A5 Triggers
```

2. Manually trigger rollout:
```bash
oc rollout restart deployment/my-app
```

3. Verify image stream import:
```bash
oc describe is/my-app
oc import-image my-app:latest --confirm
```

### Issue: Old Pods Still Running

**Symptoms:**
- New pods created but old pods remain
- Mixed versions running

**Solutions:**

1. Check rollout status:
```bash
oc rollout status deployment/my-app
```

2. Scale down old replica set:
```bash
oc get rs
oc scale rs/<old-replicaset> --replicas=0
```

3. Force complete rollout:
```bash
oc rollout restart deployment/my-app
oc delete pods -l app=my-app
```

### Issue: Registry Rate Limiting

**Symptoms:**
- Error: "Too many requests"
- Slow image pulls

**Solutions:**

1. Use authenticated registry access
2. Set up local registry mirror
3. Change to `IfNotPresent` pull policy
4. Use specific image tags instead of `latest`

---

## Quick Reference

| Method | Downtime | Pull Policy Required | Best For |
|--------|----------|---------------------|----------|
| `oc rollout restart` | No | Always | Production |
| Delete pod | Yes (single pod) | Always | Development |
| Update pull policy | No | N/A (sets it) | Permanent fix |
| Trigger deployment | No | Always | One-time update |
| Image stream import | No | N/A | OpenShift native |
| `oc set image` | No | Any | Version changes |

## Common Commands Cheat Sheet

```bash
# Quick restart
oc rollout restart deployment/<name>

# Force image pull
oc patch deployment/<name> -p \
  '{"spec":{"template":{"spec":{"containers":[{"name":"<container>","imagePullPolicy":"Always"}]}}}}'

# Delete and recreate
oc delete pod -l app=<name>

# Update image
oc set image deployment/<name> <container>=<image:tag>

# Import image stream
oc import-image <stream>:<tag> --confirm

# Check status
oc rollout status deployment/<name>
oc get pods -w
oc describe pod <pod-name>
```

---

## Additional Resources

- [OpenShift Documentation: Managing Images](https://docs.openshift.com/container-platform/latest/openshift_images/index.html)
- [Kubernetes Image Pull Policy](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy)
- [OpenShift Deployment Strategies](https://docs.openshift.com/container-platform/latest/applications/deployments/deployment-strategies.html)
- [Image Streams Documentation](https://docs.openshift.com/container-platform/latest/openshift_images/image-streams-manage.html)

---

**Last Updated:** 2026-05-17  
**Version:** 1.0