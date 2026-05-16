# HexStrike OpenShift Deployment Package

A streamlined, interactive deployment tool for deploying the HexStrike MCP server to OpenShift Container Platform with built-in authentication.

## MCP Client Setup

Before deploying to OpenShift, set up the MCP client locally to test and interact with the HexStrike service.

### Prerequisites

**For macOS users**, install required dependencies using Homebrew:
```bash
brew install cmake
brew install pkg-config
```

### Setup Steps

1. **Create a Python virtual environment**:
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   ```

2. **Install Python dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure the MCP client**:
   - The `hexstrike_mcp.py` file contains the MCP server implementation
   - Update connection settings as needed for your environment

4. **Test the MCP client locally** (optional):
   ```bash
   python hexstrike_mcp.py
   ```

## Quick Start

1. **Setup MCP Client**: Follow the MCP Client Setup section above
2. **Prerequisites**: Ensure you have `oc` CLI installed and are logged into your OpenShift cluster
3. **Run the deployment**: `./deploy-interactive.sh`
4. **Follow the prompts**: The script will guide you through namespace creation, authentication setup, and deployment
5. **Access your service**: Use the route URL provided at the end of deployment

## Requirements

- OpenShift CLI (`oc`) installed and configured
- Active OpenShift cluster login with appropriate permissions
- Bash or ZSH shell (Linux/macOS compatible)

## What's Included

- `deploy-interactive.sh` - Interactive deployment script with guided setup
- `INTERACTIVE_DEPLOYMENT.md` - Complete documentation with detailed instructions

## Features

- **Interactive Setup**: Guided prompts for all configuration options
- **Authentication Options**: Choose between Basic Auth or OAuth2 Proxy
- **Automated Deployment**: Handles namespace, secrets, deployments, services, and routes
- **Validation**: Built-in checks for prerequisites and deployment status
- **Rollback Support**: Easy cleanup and redeployment options

## Documentation

For detailed instructions, troubleshooting, and advanced configuration options, see [INTERACTIVE_DEPLOYMENT.md](INTERACTIVE_DEPLOYMENT.md).

## Support

For issues or questions:
- Review the full documentation in `INTERACTIVE_DEPLOYMENT.md`
- Check OpenShift logs: `oc logs -f deployment/hexstrike-mcp`
- Verify route status: `oc get route hexstrike-mcp`

## Security Notes

- Never commit `.env` files or secrets to version control
- Use strong passwords for authentication
- Review and customize security settings for production use
- Ensure proper RBAC permissions in your OpenShift cluster

---

**Version**: 1.0  
**License**: As per project license  
**Last Updated**: 2026-05-16