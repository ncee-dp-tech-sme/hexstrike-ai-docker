# HexStrike OpenShift Deployment Package

A streamlined, interactive deployment tool for deploying the HexStrike MCP server to OpenShift and Kubernetes with built-in basic authentication.

## MCP Client Setup

Before deploying to OpenShift, set up the MCP client locally to test and interact with the HexStrike service.

### Prerequisites

**For macOS users**, install required dependencies using Homebrew:
```bash
brew install cmake
brew install pkg-config
```

### Setup Steps


1. **Clone the repository
   git clone https://github.com/ncee-dp-tech-sme/hexstrike-ai-docker.git
   cd hexstrike-ai-docker
2. Create a Python virtual environment**:
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   ```

3. **Install Python dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure the MCP client**:
   - The `hexstrike_mcp.py` file contains the MCP server implementation
   - Update connection settings as needed for your environment

5. **Test the MCP client locally** (optional):
   ```bash
   python hexstrike_mcp.py
   ```

## Bob Pentest Mode Configuration

The HexStrike deployment includes a specialized **Pentest Mode** for Bob (your AI coding assistant) that provides security testing workflows, best practices, and tool usage patterns.

### What is Bob Pentest Mode?

Bob Pentest Mode is a custom AI mode that transforms Bob into a security testing expert, providing:
- Structured penetration testing workflows
- Security tool usage guidance
- Common vulnerability patterns and detection methods
- Best practices for ethical hacking
- Real-world security testing examples

### Configuration Options

You can configure Bob Pentest Mode at two levels using **either** of two methods:

#### Method A: Quick Import (Recommended)

**Simply import the YAML file** - it contains all rules embedded within it:

1. Open Bob settings in your IDE (VS Code, Cursor, etc.)
2. Navigate to Custom Modes
3. Click "Import Mode"
4. Select `rules-pentest/pentest-export.yaml`

This method works for both global and project-level configuration.

#### Method B: Manual XML Files (Advanced)

**Copy individual XML rule files** if you want to customize or manage rules separately:

**For Global Configuration (All Projects):**

1. **Locate your Bob global rules directory**:
   - macOS/Linux: `~/.bob/rules-pentest/`
   - Windows: `%USERPROFILE%\.bob\rules-pentest\`

2. **Copy the pentest rules**:
   ```bash
   # From the deployment package directory
   mkdir -p ~/.bob/rules-pentest
   cp rules-pentest/*.xml ~/.bob/rules-pentest/
   ```

3. **Manually configure the mode** in Bob settings to reference these XML files

**For Project-Level Configuration (Current Project Only):**

1. **Create project rules directory**:
   ```bash
   # In your project root
   mkdir -p .bob/rules-pentest
   ```

2. **Copy the pentest rules**:
   ```bash
   # From the deployment package directory
   cp rules-pentest/*.xml .bob/rules-pentest/
   ```

3. **Manually configure the mode** in Bob settings to reference these XML files

### Included Rules Files

The pentest mode includes the following rule files:

- `1_workflow.xml` - Structured penetration testing workflows and methodologies
- `2_best_practices.xml` - Security testing best practices and ethical guidelines
- `3_common_patterns.xml` - Common vulnerability patterns and detection techniques
- `4_tool_usage.xml` - HexStrike tool usage patterns and command examples
- `5_examples.xml` - Real-world security testing scenarios and examples
- `pentest-export.yaml` - Complete mode configuration for import

### Using Pentest Mode

Once configured, activate Pentest Mode in Bob:

1. Open the mode selector in your IDE
2. Select "🔐 Pentest" mode
3. Bob will now provide security-focused assistance with:
   - Vulnerability assessment guidance
   - Security tool recommendations
   - Penetration testing workflows
   - Exploit development assistance
   - Security report generation

### When to Use Pentest Mode

Activate Pentest Mode when:
- Performing security testing or vulnerability assessments
- Conducting code reviews focused on security
- Testing authentication and authorization mechanisms
- Assessing API security
- Scanning for hardcoded secrets or credentials
- Analyzing container and infrastructure security
- Creating security assessment reports
- Providing remediation guidance for security issues

### Security Considerations

**Important**: Pentest Mode is designed for authorized security testing only:
- Always obtain proper authorization before testing
- Use only on systems you own or have explicit permission to test
- Follow responsible disclosure practices
- Comply with all applicable laws and regulations
- Never use for malicious purposes

## Quick Start

1. **Setup MCP Client**: Follow the MCP Client Setup section above
2. **Prerequisites**: Ensure you have `oc` CLI installed and are logged into your OpenShift cluster
3. **Run the deployment**: `./deploy-interactive.sh`
4. **Follow the prompts**: The script will guide you through namespace creation, basic authentication setup, and deployment
5. **Access your service**: Use the OpenShift route URL provided at the end of deployment, or the Kubernetes Service access details

## Requirements

- OpenShift CLI (`oc`) installed and configured
- Active OpenShift cluster login with appropriate permissions
- Bash or ZSH shell (Linux/macOS compatible)

## What's Included

- `deploy-interactive.sh` - Interactive deployment script with guided setup
- `INTERACTIVE_DEPLOYMENT.md` - Complete documentation with detailed instructions

## Features

- **Interactive Setup**: Guided prompts for all configuration options
- **Authentication**: Optional basic authentication using an nginx proxy and htpasswd secret
- **Automated Deployment**: Handles namespaces, secrets, service accounts, role bindings, configmaps, deployments, services, and OpenShift routes
- **Automatic Service Exposure**: On Kubernetes, the script automatically starts a port-forward to `localhost:8080` — no manual step required
- **Correct MCP URL**: The generated MCP configuration always contains the correct service URL (route URL on OpenShift, `http://localhost:8080/` on Kubernetes)
- **Validation**: Built-in checks for prerequisites and deployment status
- **Rollback Support**: Easy cleanup and redeployment options

## Documentation

For detailed instructions, troubleshooting, and advanced configuration options, see [INTERACTIVE_DEPLOYMENT.md](INTERACTIVE_DEPLOYMENT.md).

## Support

For issues or questions:
- Review the full documentation in `INTERACTIVE_DEPLOYMENT.md`
- Check logs: `oc logs -l app=hexstrike-ai-docker -n <namespace> -f`
- Verify route status: `oc get route hexstrike-ai-docker -n <namespace>`
- This Bob mode and MCP Deployment script are created by Erwin Friethoff, Security Architect at IBM. This is 100% free and open source and not in any way endorsed by IBM. All done on personal title. If you have any questions, please reach out to me on LinkedIn or as IBMer, on Slack. I'm happy to help.
100% free and open source. No warranty. Use at your own risk.

## Security Notes

- Never commit `.env` files or secrets to version control
- Use strong passwords for authentication
- Review and customize security settings for production use
- Ensure proper RBAC permissions in your OpenShift cluster

---

**Version**: 1.1
**License**: As per project license
**Last Updated**: 2026-05-17
