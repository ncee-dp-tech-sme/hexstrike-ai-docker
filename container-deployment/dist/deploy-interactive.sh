#!/usr/bin/env bash

# HexStrike AI Docker - Interactive Deployment Script
# Works with both OpenShift and Kubernetes
# Compatible with Bash and ZSH on Linux and macOS
# 2026-05-16: Created interactive deployment script with authentication

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Global variables
PLATFORM=""
NAMESPACE=""
ADMIN_USERNAME="admin"
ADMIN_PASSWORD=""
ROUTE_HOST=""
USE_AUTH="yes"

# Function to print colored output
print_banner() {
    echo ""
    echo -e "${CYAN}=========================================="
    echo -e "  HexStrike AI - Interactive Deployment"
    echo -e "==========================================${NC}"
    echo ""
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo ""
    echo -e "${MAGENTA}▶ $1${NC}"
    echo ""
}

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to detect platform
detect_platform() {
    print_step "Step 1: Platform Detection"
    
    if command_exists oc; then
        if oc whoami &> /dev/null; then
            print_info "OpenShift CLI detected and logged in"
            PLATFORM="openshift"
            return 0
        else
            print_warning "OpenShift CLI found but not logged in"
        fi
    fi
    
    if command_exists kubectl; then
        if kubectl cluster-info &> /dev/null; then
            print_info "Kubernetes CLI detected and connected"
            PLATFORM="kubernetes"
            return 0
        else
            print_warning "Kubernetes CLI found but not connected"
        fi
    fi
    
    return 1
}

# Function to prompt for platform
prompt_platform() {
    echo -e "${CYAN}Which platform are you deploying to?${NC}"
    echo "  1) OpenShift"
    echo "  2) Kubernetes"
    echo ""
    read -p "Enter choice (1 or 2): " platform_choice
    
    case $platform_choice in
        1)
            PLATFORM="openshift"
            if ! command_exists oc; then
                print_error "OpenShift CLI (oc) not found. Please install it first."
                exit 1
            fi
            if ! oc whoami &> /dev/null; then
                print_error "Not logged in to OpenShift. Please run 'oc login' first."
                exit 1
            fi
            print_success "Using OpenShift"
            ;;
        2)
            PLATFORM="kubernetes"
            if ! command_exists kubectl; then
                print_error "Kubernetes CLI (kubectl) not found. Please install it first."
                exit 1
            fi
            if ! kubectl cluster-info &> /dev/null; then
                print_error "Not connected to Kubernetes cluster. Please configure kubectl first."
                exit 1
            fi
            print_success "Using Kubernetes"
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
}

# Function to get CLI command based on platform
get_cli() {
    if [ "$PLATFORM" = "openshift" ]; then
        echo "oc"
    else
        echo "kubectl"
    fi
}

# Function to prompt for namespace
prompt_namespace() {
    print_step "Step 2: Namespace Configuration"
    
    local cli=$(get_cli)
    
    echo -e "${CYAN}Enter the namespace to deploy to:${NC}"
    read -p "Namespace [default: hexstrike]: " input_namespace
    NAMESPACE=${input_namespace:-hexstrike}
    
    # Check if namespace exists
    if $cli get namespace "$NAMESPACE" &> /dev/null; then
        print_success "Namespace '$NAMESPACE' exists"
    else
        print_warning "Namespace '$NAMESPACE' does not exist"
        read -p "Create namespace '$NAMESPACE'? (y/n): " create_ns
        if [[ $create_ns =~ ^[Yy]$ ]]; then
            $cli create namespace "$NAMESPACE"
            print_success "Namespace '$NAMESPACE' created"
        else
            print_error "Namespace required. Exiting."
            exit 1
        fi
    fi
}

# Function to prompt for authentication
prompt_authentication() {
    print_step "Step 3: Authentication Configuration"
    
    echo -e "${CYAN}Enable basic authentication? (Recommended)${NC}"
    read -p "Enable authentication? (Y/n): " enable_auth
    
    if [[ $enable_auth =~ ^[Nn]$ ]]; then
        USE_AUTH="no"
        print_warning "Authentication disabled - deployment will be publicly accessible"
        return
    fi
    
    USE_AUTH="yes"
    
    echo ""
    echo -e "${CYAN}Enter admin username:${NC}"
    read -p "Username [default: admin]: " input_username
    ADMIN_USERNAME=${input_username:-admin}
    
    echo ""
    echo -e "${CYAN}Enter admin password:${NC}"
    echo -e "${YELLOW}(Password will not be displayed)${NC}"
    read -s -p "Password: " ADMIN_PASSWORD
    echo ""
    
    if [ -z "$ADMIN_PASSWORD" ]; then
        print_error "Password cannot be empty"
        exit 1
    fi
    
    # Confirm password
    read -s -p "Confirm password: " password_confirm
    echo ""
    
    if [ "$ADMIN_PASSWORD" != "$password_confirm" ]; then
        print_error "Passwords do not match"
        exit 1
    fi
    
    print_success "Authentication configured"
}

# Function to generate htpasswd hash
generate_htpasswd() {
    local username=$1
    local password=$2
    
    if command_exists htpasswd; then
        htpasswd -nbB "$username" "$password" 2>/dev/null
    elif command_exists openssl; then
        # Fallback to openssl if htpasswd not available
        echo "$username:$(openssl passwd -apr1 "$password")"
    else
        print_error "Neither htpasswd nor openssl found. Cannot generate password hash."
        exit 1
    fi
}

# Function to create secret
create_auth_secret() {
    local cli=$(get_cli)
    local htpasswd_entry=$(generate_htpasswd "$ADMIN_USERNAME" "$ADMIN_PASSWORD")
    
    print_info "Creating authentication secret..."
    
    # Create secret YAML
    cat > /tmp/hexstrike-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: hexstrike-basic-auth
  namespace: $NAMESPACE
  labels:
    app: hexstrike-ai-docker
type: Opaque
stringData:
  htpasswd: |
    $htpasswd_entry
EOF
    
    $cli apply -f /tmp/hexstrike-secret.yaml
    rm -f /tmp/hexstrike-secret.yaml
    
    print_success "Authentication secret created"
}

# Function to deploy nginx auth proxy
deploy_nginx_auth() {
    local cli=$(get_cli)
    
    print_info "Deploying nginx authentication proxy..."
    
    # Create nginx configmap
    cat > /tmp/nginx-auth-config.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-auth-config
  namespace: $NAMESPACE
data:
  nginx.conf: |
    events {
        worker_connections 1024;
    }
    http {
        server {
            listen 8080;
            location / {
                auth_basic "HexStrike AI - Authentication Required";
                auth_basic_user_file /etc/nginx/htpasswd/htpasswd;
                proxy_pass http://hexstrike-ai-docker:8888;
                proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto \$scheme;
            }
        }
    }
EOF
    
    $cli apply -f /tmp/nginx-auth-config.yaml
    rm -f /tmp/nginx-auth-config.yaml
    
    # Create nginx deployment
    cat > /tmp/nginx-auth-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hexstrike-nginx-auth
  namespace: $NAMESPACE
  labels:
    app: hexstrike-nginx-auth
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hexstrike-nginx-auth
  template:
    metadata:
      labels:
        app: hexstrike-nginx-auth
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
        - name: htpasswd
          mountPath: /etc/nginx/htpasswd
          readOnly: true
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-auth-config
      - name: htpasswd
        secret:
          secretName: hexstrike-basic-auth
EOF
    
    $cli apply -f /tmp/nginx-auth-deployment.yaml
    rm -f /tmp/nginx-auth-deployment.yaml
    
    # Create nginx service
    cat > /tmp/nginx-auth-service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: hexstrike-nginx-auth
  namespace: $NAMESPACE
  labels:
    app: hexstrike-nginx-auth
spec:
  selector:
    app: hexstrike-nginx-auth
  ports:
  - port: 8080
    targetPort: 8080
    protocol: TCP
EOF
    
    $cli apply -f /tmp/nginx-auth-service.yaml
    rm -f /tmp/nginx-auth-service.yaml
    
    print_success "Nginx authentication proxy deployed"
}

# Function to deploy main application
deploy_application() {
    local cli=$(get_cli)
    
    print_step "Step 4: Deploying HexStrike AI Application"
    
    # Create ServiceAccount with correct namespace
    print_info "Creating ServiceAccount..."
    cat > /tmp/hexstrike-serviceaccount.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app: hexstrike-ai-docker
  name: hexstrike-ai-privileged
  namespace: $NAMESPACE
EOF
    
    $cli apply -f /tmp/hexstrike-serviceaccount.yaml
    rm -f /tmp/hexstrike-serviceaccount.yaml
    
    if [ "$PLATFORM" = "openshift" ]; then
        # Create SCC RoleBinding with correct namespace
        print_info "Creating SCC RoleBinding for privileged access..."
        cat > /tmp/hexstrike-scc-rolebinding.yaml <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: system:openshift:scc:privileged
  namespace: $NAMESPACE
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:openshift:scc:privileged
subjects:
- kind: ServiceAccount
  name: hexstrike-ai-privileged
  namespace: $NAMESPACE
EOF
        
        $cli apply -f /tmp/hexstrike-scc-rolebinding.yaml
        rm -f /tmp/hexstrike-scc-rolebinding.yaml
        
        print_info "Waiting for RBAC to propagate..."
        sleep 3
    fi
    
    # Create deployment with correct namespace and serviceAccount
    print_info "Creating Deployment..."
    cat > /tmp/hexstrike-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: hexstrike-ai-docker
  name: hexstrike-ai-docker
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hexstrike-ai-docker
  template:
    metadata:
      labels:
        app: hexstrike-ai-docker
    spec:
      serviceAccountName: hexstrike-ai-privileged
      containers:
      - image: quay.io/erwin_/hexstrike-ai-docker:latest
        imagePullPolicy: Always
        name: hexstrike-ai-docker
        ports:
        - containerPort: 8888
          protocol: TCP
        resources:
          limits:
            cpu: "2"
            memory: 4Gi
          requests:
            cpu: "1"
            memory: 2Gi
        securityContext:
          allowPrivilegeEscalation: true
          capabilities:
            add:
            - NET_ADMIN
            - NET_RAW
            - SYS_ADMIN
          privileged: true
          runAsUser: 0
        volumeMounts:
        - mountPath: /dev/net/tun
          name: tun-device
      volumes:
      - hostPath:
          path: /dev/net/tun
          type: CharDevice
        name: tun-device
EOF
    
    $cli apply -f /tmp/hexstrike-deployment.yaml
    rm -f /tmp/hexstrike-deployment.yaml
    
    # Create service with correct namespace
    print_info "Creating Service..."
    cat > /tmp/hexstrike-service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: hexstrike-ai-docker
  name: hexstrike-ai-docker
  namespace: $NAMESPACE
spec:
  ports:
  - port: 8888
    protocol: TCP
    targetPort: 8888
  selector:
    app: hexstrike-ai-docker
  type: ClusterIP
EOF
    
    $cli apply -f /tmp/hexstrike-service.yaml
    rm -f /tmp/hexstrike-service.yaml
    
    print_success "Application deployed with privileged access"
}

# Function to create route/ingress
create_route() {
    local cli=$(get_cli)
    
    print_step "Step 5: Creating External Access"
    
    if [ "$PLATFORM" = "openshift" ]; then
        if [ "$USE_AUTH" = "yes" ]; then
            # Create route for nginx auth proxy
            cat > /tmp/hexstrike-route.yaml <<EOF
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: hexstrike-ai-docker
  namespace: $NAMESPACE
  labels:
    app: hexstrike-ai-docker
spec:
  to:
    kind: Service
    name: hexstrike-nginx-auth
  port:
    targetPort: 8080
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
EOF
        else
            # Create route for direct access
            $cli apply -f route.yaml -n "$NAMESPACE"
            ROUTE_HOST=$($cli get route hexstrike-ai-docker -n "$NAMESPACE" -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
            return
        fi
        
        $cli apply -f /tmp/hexstrike-route.yaml
        rm -f /tmp/hexstrike-route.yaml
        
        ROUTE_HOST=$($cli get route hexstrike-ai-docker -n "$NAMESPACE" -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
        print_success "Route created: https://$ROUTE_HOST"
    else
        # Kubernetes - create ingress or use LoadBalancer
        print_warning "Kubernetes ingress configuration depends on your cluster setup"
        print_info "Service created. Use 'kubectl get svc -n $NAMESPACE' to see access details"
        
        if [ "$USE_AUTH" = "yes" ]; then
            print_info "Service: hexstrike-nginx-auth"
        else
            print_info "Service: hexstrike-ai-docker"
        fi
    fi
}

# Function to wait for deployment
wait_for_deployment() {
    local cli=$(get_cli)
    local deployment=$1
    
    print_info "Waiting for deployment '$deployment' to be ready..."
    
    if [ "$PLATFORM" = "openshift" ]; then
        $cli rollout status deployment/"$deployment" -n "$NAMESPACE" --timeout=300s
    else
        $cli rollout status deployment/"$deployment" -n "$NAMESPACE" --timeout=300s
    fi
    
    print_success "Deployment '$deployment' is ready"
}

# Function to print MCP configuration
print_mcp_config() {
    print_step "MCP Client Configuration"
    
    local server_url=""
    if [ "$PLATFORM" = "openshift" ] && [ -n "$ROUTE_HOST" ]; then
        server_url="https://$ROUTE_HOST/"
    else
        server_url="http://localhost:8888/"
        print_warning "For Kubernetes, you may need to port-forward: kubectl port-forward svc/hexstrike-ai-docker 8888:8888 -n $NAMESPACE"
    fi
    
    echo ""
    echo -e "${CYAN}Add this configuration to your .bob/mcp.json:${NC}"
    echo ""
    echo -e "${GREEN}{"
    echo "    \"mcpServers\": {"
    echo "        \"hexstrike-ai\": {"
    echo "            \"command\": \"/path/to/python\","
    echo "            \"args\": ["
    echo "                \"/path/to/hexstrike_mcp.py\","
    echo "                \"--server\","
    echo "                \"$server_url\","
    echo "                \"--timeout\","
    echo "                \"1800\""
    
    if [ "$USE_AUTH" = "yes" ]; then
        echo "                ,\"--username\","
        echo "                \"$ADMIN_USERNAME\","
        echo "                \"--password\","
        echo "                \"$ADMIN_PASSWORD\""
    fi
    
    echo "            ],"
    echo "            \"disabled\": false,"
    echo "            \"timeout\": 1800"
    echo "        }"
    echo "    }"
    echo -e "}${NC}"
    echo ""
}

# Function to print summary
print_summary() {
    print_step "Deployment Summary"
    
    local cli=$(get_cli)
    
    echo -e "${GREEN}✓ Platform:${NC} $PLATFORM"
    echo -e "${GREEN}✓ Namespace:${NC} $NAMESPACE"
    echo -e "${GREEN}✓ Authentication:${NC} $([ "$USE_AUTH" = "yes" ] && echo "Enabled" || echo "Disabled")"
    
    if [ "$USE_AUTH" = "yes" ]; then
        echo -e "${GREEN}✓ Username:${NC} $ADMIN_USERNAME"
        echo -e "${GREEN}✓ Password:${NC} ********"
    fi
    
    if [ "$PLATFORM" = "openshift" ] && [ -n "$ROUTE_HOST" ]; then
        echo -e "${GREEN}✓ URL:${NC} https://$ROUTE_HOST"
        echo ""
        
        if [ "$USE_AUTH" = "yes" ]; then
            echo -e "${CYAN}Test the deployment:${NC}"
            echo "  curl -u $ADMIN_USERNAME:$ADMIN_PASSWORD https://$ROUTE_HOST/health"
        else
            echo -e "${CYAN}Test the deployment:${NC}"
            echo "  curl https://$ROUTE_HOST/health"
        fi
    else
        echo ""
        echo -e "${CYAN}View services:${NC}"
        echo "  $cli get svc -n $NAMESPACE"
        echo ""
        echo -e "${CYAN}Port forward (if needed):${NC}"
        if [ "$USE_AUTH" = "yes" ]; then
            echo "  $cli port-forward svc/hexstrike-nginx-auth 8080:8080 -n $NAMESPACE"
        else
            echo "  $cli port-forward svc/hexstrike-ai-docker 8888:8888 -n $NAMESPACE"
        fi
    fi
    
    echo ""
    echo -e "${CYAN}View logs:${NC}"
    echo "  $cli logs -l app=hexstrike-ai-docker -n $NAMESPACE -f"
    echo ""
    echo -e "${CYAN}View pods:${NC}"
    echo "  $cli get pods -n $NAMESPACE"
    echo ""
}

# Main function
main() {
    print_banner
    
    # Step 1: Detect or prompt for platform
    if ! detect_platform; then
        prompt_platform
    else
        print_success "Platform detected: $PLATFORM"
    fi
    
    # Step 2: Prompt for namespace
    prompt_namespace
    
    # Step 3: Prompt for authentication
    prompt_authentication
    
    # Confirmation
    echo ""
    print_warning "Ready to deploy with the following configuration:"
    echo "  Platform: $PLATFORM"
    echo "  Namespace: $NAMESPACE"
    echo "  Authentication: $([ "$USE_AUTH" = "yes" ] && echo "Enabled" || echo "Disabled")"
    echo ""
    read -p "Continue with deployment? (y/n): " confirm
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_info "Deployment cancelled"
        exit 0
    fi
    
    # Create authentication if enabled
    if [ "$USE_AUTH" = "yes" ]; then
        create_auth_secret
        deploy_nginx_auth
    fi
    
    # Deploy application
    deploy_application
    
    # Create route/ingress
    create_route
    
    # Wait for deployments
    echo ""
    wait_for_deployment "hexstrike-ai-docker"
    
    if [ "$USE_AUTH" = "yes" ]; then
        wait_for_deployment "hexstrike-nginx-auth"
    fi
    
    # Print MCP configuration
    print_mcp_config
    
    # Print summary
    print_summary
    
    echo ""
    print_success "Deployment completed successfully!"
    echo ""
}

# Run main function
main "$@"

# Made with Bob
# 2026-05-16: Created interactive deployment script for OpenShift and Kubernetes