# 300 - Learning Our Subject

# Learning InSpec

A comprehensive InSpec security compliance and infrastructure testing profile demonstrating practical knowledge of security hardening and compliance automation.

## About This Repository

This repository contains a production-ready InSpec profile for validating Linux server security configurations against industry best practices and security baselines. The profile demonstrates advanced InSpec concepts including:

- Multi-layered security controls (filesystem, network, users, services)
- OWASP security principles integration
- CIS Benchmark alignment concepts
- Practical security hardening validation
- Reusable control patterns for infrastructure as code

## What is InSpec?

InSpec is an open-source testing framework by Chef for infrastructure with a human-readable language for specifying compliance, security, and policy requirements. It’s used for:

- Security compliance testing
- Infrastructure configuration validation
- Continuous compliance in CI/CD pipelines
- Audit and regulatory compliance (PCI-DSS, HIPAA, SOC2, ISO27001)

## Repository Structure

```
learning-inspec/
├── 300/README.md
├── inspec.yml                          # Profile metadata
├── controls/
│   ├── 01_filesystem_security.rb       # File permissions and ownership
│   ├── 02_user_management.rb           # User account security
│   ├── 03_service_hardening.rb         # Service configuration
│   ├── 04_network_security.rb          # Network and firewall rules
│   └── 05_application_security.rb      # Application-level security
├── libraries/
│   └── helpers.rb                      # Custom helper methods
└── files/
    └── sample_config.yml               # Sample configuration data
```

## The Demo Profile: Linux Security Baseline

This profile validates critical security controls on Linux systems:

### 1. **Filesystem Security** (`01_filesystem_security.rb`)

- Validates permissions on sensitive system files
- Checks for world-writable files
- Ensures proper ownership of critical directories
- Validates SSH configuration hardening

### 2. **User Management** (`02_user_management.rb`)

- Validates no users have empty passwords
- Checks for UID 0 accounts (root equivalents)
- Ensures proper home directory permissions
- Validates password aging policies

### 3. **Service Hardening** (`03_service_hardening.rb`)

- Ensures unnecessary services are disabled
- Validates critical services are running
- Checks service configurations for security settings

### 4. **Network Security** (`04_network_security.rb`)

- Validates firewall is active
- Checks for open ports against baseline
- Ensures IP forwarding is disabled when not needed
- Validates secure network parameters

### 5. **Application Security** (`05_application_security.rb`)

- Checks Docker security configuration (if applicable)
- Validates web server security headers
- Ensures package managers are properly configured

## Prerequisites

### Install InSpec

```bash
# macOS
brew install inspec

# Linux (Debian/Ubuntu)
curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec

# Windows (PowerShell as Administrator)
. { iwr -useb https://omnitruck.chef.io/install.ps1 } | iex; install -project inspec
```

### Verify Installation

```bash
inspec --version
```

## Usage

### Run the Complete Profile Locally

```bash
# Clone the repository
git clone https://github.com/yourusername/learning-inspec.git
cd learning-inspec

# Run all controls
inspec exec . -t ssh://user@hostname

# Or for local system
inspec exec .
```

### Run Specific Controls

```bash
# Run only filesystem security controls
inspec exec . --controls filesystem-*

# Run only user management controls
inspec exec . --controls user-*
```

### Generate Reports

```bash
# JSON output
inspec exec . --reporter json:results.json

# HTML report
inspec exec . --reporter html:results.html

# CLI + JSON
inspec exec . --reporter cli json:results.json
```

### Run Against Remote Systems

```bash
# SSH
inspec exec . -t ssh://username@hostname -i ~/.ssh/id_rsa

# WinRM (Windows)
inspec exec . -t winrm://username@hostname --password 'password'

# Docker container
inspec exec . -t docker://container_id

# Kubernetes pod
inspec exec . -t k8s://pod-name --namespace default
```

## Integration with CI/CD

### Jenkins Pipeline Example

```groovy
stage('Security Compliance') {
    steps {
        sh '''
            inspec exec ./learning-inspec \
                -t ssh://admin@${SERVER_IP} \
                --reporter cli json:inspec-results.json \
                --no-distinct-exit
        '''
        
        publishHTML([
            reportDir: '.',
            reportFiles: 'inspec-results.json',
            reportName: 'InSpec Security Report'
        ])
    }
}
```

### Azure DevOps Pipeline Example

```yaml
- task: Bash@3
  displayName: 'Run InSpec Security Tests'
  inputs:
    targetType: 'inline'
    script: |
      inspec exec ./learning-inspec \
        -t ssh://$(adminUser)@$(serverIP) \
        --reporter cli json:$(Build.ArtifactStagingDirectory)/inspec-results.json
      
- task: PublishBuildArtifacts@1
  inputs:
    pathToPublish: '$(Build.ArtifactStagingDirectory)'
    artifactName: 'InSpec-Results'
```

## Customization

### Adding Custom Controls

Create a new control file in the `controls/` directory:

```ruby
control 'custom-01' do
  impact 1.0
  title 'Custom Security Check'
  desc 'Description of what this control validates'
  
  describe file('/path/to/file') do
    it { should exist }
    its('mode') { should cmp '0644' }
  end
end
```

### Using Inputs for Flexibility

Define inputs in `inspec.yml`:

```yaml
inputs:
  - name: allowed_ssh_port
    type: Numeric
    value: 22
```

Use in controls:

```ruby
describe port(input('allowed_ssh_port')) do
  it { should be_listening }
end
```

## Key InSpec Concepts Demonstrated

### 1. **Resource DSL**

InSpec provides resources like `file`, `user`, `service`, `package`, `port`, etc.

```ruby
describe file('/etc/passwd') do
  it { should exist }
  its('mode') { should cmp '0644' }
  its('owner') { should eq 'root' }
end
```

### 2. **Impact Levels**

Controls have impact ratings (0.0 - 1.0) indicating criticality:

- 0.0 - 0.3: Low
- 0.4 - 0.6: Medium
- 0.7 - 0.8: High
- 0.9 - 1.0: Critical

### 3. **Matchers**

InSpec uses RSpec-style matchers:

- `should exist`
- `should be_running`
- `should cmp '0644'`
- `should include 'value'`

### 4. **Control Tags**

Organize controls with tags for easy filtering:

```ruby
control 'ssh-01' do
  tag 'ssh'
  tag 'network'
  tag 'cis-benchmark'
  # ... control logic
end
```

### 5. **Only_if Conditionals**

Skip controls when conditions aren’t met:

```ruby
control 'docker-01' do
  only_if { package('docker').installed? }
  # ... control logic
end
```

## Real-World Application

InSpec profiles like this are integrated into:

1. **CI/CD Pipelines**: Automated compliance checks before deployment
1. **Infrastructure as Code**: Validate Terraform/Ansible deployments
1. **Continuous Monitoring**: Regular compliance scans of Developer Services environment
1. **Security Audits**: Evidence generation for ISO27001 and internal audits
1. **Configuration Management**: Validate system configurations match security baselines

## Learning Path

### Beginner

- ✅ Understand InSpec resources (file, package, service)
- ✅ Write basic controls with simple matchers
- ✅ Run InSpec locally

### Intermediate

- ✅ Create structured profiles with multiple control files
- ✅ Use tags and impacts effectively
- ✅ Generate and analyze reports
- ✅ Integrate with CI/CD pipelines

### Advanced

- ✅ Create custom resources
- ✅ Write reusable profile libraries
- ✅ Implement input-driven profiles for multi-environment testing
- ✅ Contribute to compliance baseline profiles (CIS, STIG, etc.)

## Resources

- [InSpec Official Documentation](https://docs.chef.io/inspec/)
- [InSpec Resources Reference](https://docs.chef.io/inspec/resources/)
- [InSpec DSL](https://docs.chef.io/inspec/dsl_inspec/)
- [Dev-Sec Hardening Framework](https://dev-sec.io/) - Production InSpec profiles
- [CIS InSpec Profiles](https://github.com/dev-sec/cis-docker-benchmark)

## Contributing

This is a learning repository demonstrating InSpec expertise. Feel free to:

- Add more security controls
- Improve existing checks
- Add support for different operating systems
- Enhance documentation

## License

MIT License - Feel free to use this as a template for your own InSpec profiles.

## Author

**Willem van Heemstra**

- Email: wvanheemstra@icloud.com
- Focus: DevSecOps, Infrastructure Security, Compliance Automation

-----

**Note**: This profile is designed as a demonstration of InSpec capabilities and should be adapted to your specific security requirements and compliance frameworks before production use.
