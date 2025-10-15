# Contributing to Learning InSpec

Thank you for your interest in improving this InSpec security compliance profile! This guide will help you contribute effectively.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
1. [Getting Started](#getting-started)
1. [Development Workflow](#development-workflow)
1. [Writing Controls](#writing-controls)
1. [Testing Your Changes](#testing-your-changes)
1. [Submitting Changes](#submitting-changes)
1. [Style Guide](#style-guide)
1. [Best Practices](#best-practices)

-----

## Code of Conduct

This project aims to be welcoming and inclusive. We expect contributors to:

- Be respectful and professional
- Provide constructive feedback
- Focus on security best practices
- Document decisions and rationale
- Help others learn

-----

## Getting Started

### Fork and Clone

```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR-USERNAME/learning-inspec.git
cd learning-inspec

# Add upstream remote
git remote add upstream https://github.com/ORIGINAL-OWNER/learning-inspec.git
```

### Development Setup

```bash
# Install InSpec
curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec

# Verify installation
inspec --version

# Check profile syntax
inspec check .

# Start test environment
docker-compose up -d
```

### Stay Updated

```bash
# Sync with upstream
git fetch upstream
git checkout main
git merge upstream/main
```

-----

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/add-postgresql-controls
# or
git checkout -b fix/filesystem-permissions-check
# or
git checkout -b docs/improve-readme
```

### 2. Make Your Changes

Work on one logical change per branch:

- Adding new controls
- Fixing existing controls
- Updating documentation
- Improving test coverage

### 3. Test Thoroughly

```bash
# Validate syntax
inspec check .

# Test locally
inspec exec .

# Test against Docker
inspec exec . -t ssh://testuser@localhost:2222 --password testpass123

# Run full test suite
./test-all-environments.sh
```

### 4. Commit with Clear Messages

```bash
git add .
git commit -m "Add PostgreSQL security controls

- Add control for checking postgresql.conf permissions
- Add control for validating pg_hba.conf configuration
- Add control for checking default postgres user
- Update README with PostgreSQL testing instructions

Closes #42"
```

-----

## Writing Controls

### Control Template

Use this template when creating new controls:

```ruby
control 'category-##' do
  impact 0.0  # 0.0-1.0: low, medium, high, critical
  title 'Clear, descriptive title of what this control checks'
  desc 'Detailed description of the security requirement and why it matters'
  tag 'category'  # e.g., filesystem, network, service
  tag 'severity'  # e.g., critical, high, medium, low
  tag 'framework'  # e.g., cis-benchmark, owasp, pci-dss
  
  # Add only_if condition if control is conditional
  only_if { package('target-software').installed? }
  
  describe resource('target') do
    it { should meet_requirement }
    its('property') { should expected_value }
  end
end
```

### Example: Adding a New Control

```ruby
control 'postgresql-01' do
  impact 0.9
  title 'Ensure PostgreSQL data directory has proper permissions'
  desc 'The PostgreSQL data directory contains sensitive database files
        and should only be accessible by the postgres user to prevent
        unauthorized access or data exfiltration.'
  tag 'database'
  tag 'postgresql'
  tag 'high'
  tag 'data-protection'
  
  only_if { package('postgresql').installed? }
  
  # Get PostgreSQL data directory from config
  data_dir = command("sudo -u postgres psql -t -c 'SHOW data_directory;'").stdout.strip
  
  describe directory(data_dir) do
    it { should exist }
    its('owner') { should eq 'postgres' }
    its('group') { should eq 'postgres' }
    its('mode') { should cmp '0700' }
  end
end
```

### Control Naming Convention

- **Format**: `category-##`
- **Categories**:
  - `filesystem-##`: File system security
  - `user-##`: User and access management
  - `service-##`: Service configuration
  - `network-##`: Network security
  - `app-##`: Application security
  - `database-##`: Database security (new category)
  - `container-##`: Container security (new category)

### Impact Levels

Choose appropriate impact based on risk:

```ruby
# Critical (1.0): Immediate security threat
impact 1.0  # Empty passwords, root UID 0, unencrypted credentials

# High (0.7-0.9): Significant security risk
impact 0.9  # Weak SSH config, missing patches, exposed services

# Medium (0.4-0.6): Moderate security concern
impact 0.6  # Suboptimal config, minor vulnerabilities

# Low (0.0-0.3): Best practice or hardening
impact 0.3  # Logging config, banner messages
```

-----

## Testing Your Changes

### Mandatory Pre-Submission Tests

Run ALL of these before submitting:

```bash
# 1. Syntax validation
inspec check .
echo "✓ Syntax check passed"

# 2. Local execution
inspec exec . --reporter cli:verbose
echo "✓ Local execution completed"

# 3. Docker test environment
docker-compose up -d
sleep 10
inspec exec . -t ssh://testuser@localhost:2222 --password testpass123
echo "✓ Docker test passed"

# 4. Multi-environment testing
./test-all-environments.sh
echo "✓ Multi-environment tests passed"

# 5. Check for regressions
# Ensure existing controls still pass
inspec exec . --controls filesystem-* user-* service-*
echo "✓ No regressions detected"
```

### Testing Specific Controls

```bash
# Test only your new control
inspec exec . --controls postgresql-01

# Test with debug output
inspec exec . --controls postgresql-01 --log-level debug

# Test with different inputs
inspec exec . --controls postgresql-01 --input-file inputs-test.yml
```

### Creating Test Cases

For complex controls, add test cases:

```ruby
# In controls/06_postgresql_security.rb

control 'postgresql-01' do
  # ... control definition ...
end

# Test helper (if needed)
def get_postgresql_version
  command("sudo -u postgres psql -t -c 'SELECT version();'").stdout
end
```

-----

## Submitting Changes

### Before Submitting

**Checklist:**

- [ ] All tests pass
- [ ] No syntax errors (`inspec check .`)
- [ ] Control has clear title and description
- [ ] Appropriate impact level set
- [ ] Tags added for categorization
- [ ] `only_if` conditions added where appropriate
- [ ] Documentation updated (README, TESTING, etc.)
- [ ] CHANGELOG.md updated
- [ ] Commit messages are clear and descriptive

### Pull Request Process

1. **Push Your Branch**
   
   ```bash
   git push origin feature/add-postgresql-controls
   ```
1. **Create Pull Request**
- Go to GitHub
- Click “New Pull Request”
- Select your branch
- Fill out the PR template
1. **PR Description Template**
   
   ```markdown
   ## Description
   Brief description of changes
   
   ## Type of Change
   - [ ] New controls added
   - [ ] Existing controls modified
   - [ ] Bug fix
   - [ ] Documentation update
   - [ ] Test improvements
   
   ## Controls Added/Modified
   - `postgresql-01`: PostgreSQL data directory permissions
   - `postgresql-02`: PostgreSQL authentication configuration
   
   ## Testing Performed
   - [x] Local testing
   - [x] Docker environment testing
   - [x] Multi-environment testing
   - [x] No regressions in existing controls
   
   ## Related Issues
   Closes #42
   
   ## Screenshots (if applicable)
   [Add screenshots of test results]
   ```
1. **Address Review Comments**
- Be responsive to feedback
- Make requested changes promptly
- Update tests if needed
- Push updates to the same branch

-----

## Style Guide

### Ruby Style

Follow Ruby community conventions:

```ruby
# Good: Clear variable names
postgresql_data_dir = '/var/lib/postgresql/14/main'

# Bad: Unclear abbreviations
pg_dd = '/var/lib/postgresql/14/main'

# Good: Readable condition
only_if { package('postgresql').installed? }

# Bad: Complex nested condition
only_if { package('postgresql').installed? && service('postgresql').running? && file('/etc/postgresql').exist? }
```

### Control Structure

```ruby
# Good: Well-structured control
control 'app-01' do
  impact 0.8
  title 'Clear title'
  desc 'Detailed description'
  tag 'category'
  tag 'severity'
  
  only_if { condition }
  
  describe resource do
    # tests
  end
end

# Bad: Minimal information
control 'app-01' do
  describe file('/etc/passwd') do
    its('mode') { should cmp '0644' }
  end
end
```

### Documentation

```ruby
# Good: Self-documenting with rationale
control 'network-01' do
  impact 0.9
  title 'Ensure IP forwarding is disabled'
  desc 'IP forwarding should be disabled unless the system acts as a router.
        Enabling IP forwarding on systems that do not require it increases
        the attack surface and may allow attackers to route traffic through
        the compromised system.'
  tag 'network'
  tag 'high'
  
  describe kernel_parameter('net.ipv4.ip_forward') do
    its('value') { should eq 0 }
  end
end
```

### Comments

```ruby
# Good: Explain non-obvious logic
# Check for SSH keys in non-standard locations
# Common in cloud environments with custom provisioning
custom_ssh_dirs = ['/opt/ssh_keys', '/etc/authorized_keys']

# Bad: State the obvious
# Check if file exists
file('/etc/passwd').exist?

# Good: Explain workarounds
# Use grep instead of built-in methods due to InSpec limitation #1234
command("grep '^PASS_MAX_DAYS' /etc/login.defs").stdout
```

-----

## Best Practices

### Security Control Design

1. **Be Specific**: Test exact requirements
   
   ```ruby
   # Good
   its('mode') { should cmp '0644' }
   
   # Bad
   it { should exist }  # Too vague
   ```
1. **Use Appropriate Matchers**
   
   ```ruby
   # For permissions: Use cmp for octal comparison
   its('mode') { should cmp '0600' }
   
   # For strings: Use eq or cmp
   its('owner') { should eq 'root' }
   
   # For booleans: Use be_*
   it { should be_running }
   ```
1. **Handle Edge Cases**
   
   ```ruby
   # Check if file exists before testing permissions
   only_if { file('/etc/special.conf').exist? }
   
   # Or handle both cases
   if file('/etc/special.conf').exist?
     describe file('/etc/special.conf') do
       its('mode') { should cmp '0600' }
     end
   else
     describe 'Special config file' do
       it { should be_nil }  # Document that missing is acceptable
     end
   end
   ```
1. **Provide Context**
   
   ```ruby
   # Good: Explain what's being tested
   describe "SSH cipher configuration" do
     subject { configured_ciphers }
     it { should_not include weak_cipher }
   end
   
   # Bad: No context
   describe sshd_config.ciphers do
     it { should_not include '3des-cbc' }
   end
   ```

### Error Handling

```ruby
# Good: Graceful handling of missing commands
if command('docker').exist?
  describe command('docker ps') do
    its('exit_status') { should eq 0 }
  end
else
  describe 'Docker check skipped' do
    skip 'Docker not installed'
  end
end

# Bad: Assumes command exists
describe command('docker ps') do
  its('exit_status') { should eq 0 }
end
```

### Performance

```ruby
# Good: Cache expensive operations
postgresql_version = command("psql --version").stdout
control 'pg-01' do
  # use postgresql_version
end
control 'pg-02' do
  # reuse postgresql_version
end

# Bad: Repeat expensive operations
control 'pg-01' do
  version = command("psql --version").stdout
end
control 'pg-02' do
  version = command("psql --version").stdout  # Duplicate call
end
```

-----

## Documentation Requirements

### When Adding Controls

Update these files:

1. **README.md**: Add control to appropriate section
1. **TESTING.md**: Add testing instructions if needed
1. **CHANGELOG.md**: Document the addition
1. **inputs.yml**: Add any new input parameters

### Example Documentation

```markdown
### 6. **Database Security** (`06_database_security.rb`)
- Validates PostgreSQL configuration security
- Checks database file permissions
- Ensures authentication is properly configured
- Validates connection encryption settings
```

-----

## Review Process

### What Reviewers Look For

1. **Security Value**: Does this improve security posture?
1. **Correctness**: Does it accurately test the requirement?
1. **Completeness**: Are edge cases handled?
1. **Performance**: Is it efficient?
1. **Documentation**: Is it well-documented?
1. **Testing**: Are tests comprehensive?
1. **Style**: Does it follow conventions?

### Getting Your PR Merged

- Be patient with review process
- Address feedback constructively
- Keep changes focused and scoped
- Ensure all CI checks pass
- Maintain professional communication

-----

## Questions?

- **General Questions**: Open a [Discussion](https://github.com/yourusername/learning-inspec/discussions)
- **Bug Reports**: Open an [Issue](https://github.com/yourusername/learning-inspec/issues)
- **Security Issues**: Email security@example.com privately

-----

## Recognition

Contributors will be:

- Listed in README.md
- Mentioned in CHANGELOG.md
- Credited in release notes

Thank you for helping improve security compliance testing!

-----

**Maintained by**: Willem van Heemstra
**License**: MIT  
**Community**: All security professionals welcome
