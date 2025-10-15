# Quick Start Guide - Learning InSpec

Get up and running with this InSpec security compliance profile in 5 minutes!

## Prerequisites

You need one of these installed:

- **macOS**: `brew install inspec`
- **Linux**: `curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec`
- **Windows**: See [InSpec Installation](https://docs.chef.io/inspec/install/)

Verify installation:

```bash
inspec --version
# Should show: InSpec 5.x.x or higher
```

-----

## 🚀 Option 1: Test Your Local Machine (30 seconds)

The fastest way to see InSpec in action:

```bash
# Clone this repository
git clone https://github.com/yourusername/learning-inspec.git
cd learning-inspec

# Run the profile locally
inspec exec .
```

**What you’ll see:**

- Green ✓ for passing controls
- Red ✗ for failing controls
- Summary statistics at the end

**Example Output:**

```
Profile: Linux Security Baseline Profile (linux-security-baseline)
Version: 1.0.0
Target:  local://

  ✓  filesystem-01: Ensure /etc/passwd permissions are configured
  ✓  filesystem-02: Ensure /etc/shadow permissions are configured
  ✗  service-03: Ensure SSH root login is disabled
  ...

Profile Summary: 15 successful, 5 failures, 0 skipped
Test Summary: 45 successful, 12 failures, 0 skipped
```

-----

## 🐳 Option 2: Test with Docker (2 minutes)

Test against a clean Ubuntu container:

```bash
# Start test environment
docker-compose up -d

# Wait 10 seconds for SSH to start
sleep 10

# Run InSpec against the container
inspec exec . -t ssh://testuser@localhost:2222 --password testpass123
```

**Generate an HTML report:**

```bash
inspec exec . \
  -t ssh://testuser@localhost:2222 \
  --password testpass123 \
  --reporter html:report.html

# Open the report
open report.html  # macOS
xdg-open report.html  # Linux
```

**Stop the test environment:**

```bash
docker-compose down
```

-----

## 🌐 Option 3: Test a Remote Server (1 minute)

Test against any server you have SSH access to:

```bash
# Using SSH key
inspec exec . -t ssh://user@your-server.com -i ~/.ssh/id_rsa

# Using password
inspec exec . -t ssh://user@your-server.com --password 'yourpassword'

# With custom SSH port
inspec exec . -t ssh://user@your-server.com:2222 -i ~/.ssh/id_rsa
```

-----

## 📊 Generate Reports

### HTML Report (Easy to Share)

```bash
inspec exec . --reporter html:security-report.html
```

### JSON Report (For Automation)

```bash
inspec exec . --reporter json:security-report.json
```

### Multiple Reports at Once

```bash
inspec exec . \
  --reporter cli \
  --reporter json:report.json \
  --reporter html:report.html
```

-----

## 🎯 Run Specific Controls

Don’t want to run everything? Filter by control groups:

```bash
# Only filesystem security
inspec exec . --controls filesystem-*

# Only user management
inspec exec . --controls user-*

# Only network security
inspec exec . --controls network-*

# Specific controls
inspec exec . --controls filesystem-01 user-01 service-01
```

-----

## 🛠 Customize for Your Environment

### 1. Create Custom Inputs

Copy and modify `inputs.yml`:

```bash
cp inputs.yml my-inputs.yml

# Edit my-inputs.yml with your settings
vim my-inputs.yml
```

Example customization:

```yaml
# Allow different SSH port
allowed_ssh_port: 2222

# Custom critical services
critical_services:
  - sshd
  - nginx
  - mysql

# Stricter password policy
max_password_age: 60
```

### 2. Run with Custom Inputs

```bash
inspec exec . --input-file my-inputs.yml
```

-----

## 🚫 Handle Exceptions with Waivers

Some controls don’t apply to your environment? Use waivers:

### 1. Create Waiver File

```bash
cp waivers.yml my-waivers.yml
```

### 2. Add Your Exceptions

```yaml
# Example: Docker not installed
app-01:
  run: false
  justification: "Docker not used in this environment"
  approver: "Security Team"
```

### 3. Run with Waivers

```bash
inspec exec . --waiver-file my-waivers.yml
```

-----

## 🧪 Test Multiple Environments

We’ve included a script to test multiple systems:

```bash
# Make script executable
chmod +x test-all-environments.sh

# Run tests against all Docker containers
./test-all-environments.sh
```

This will:

- Start Docker test containers
- Run InSpec against each one
- Generate comparison reports
- Create a summary dashboard

Reports saved to: `reports/multi-env-TIMESTAMP/`

-----

## 📈 Understand the Results

### Control Status

- **✓ Passed**: Control requirements met
- **✗ Failed**: Control requirements NOT met
- **⊘ Skipped**: Control skipped (waiver or only_if condition)

### Impact Levels

- **1.0 - Critical**: Must be fixed immediately
- **0.7-0.9 - High**: Should be fixed soon
- **0.4-0.6 - Medium**: Fix in next sprint
- **0.0-0.3 - Low**: Nice to fix when possible

### Compliance Score

```
Compliance % = (Passed Controls / Total Controls) × 100
```

**Targets:**

- **95-100%**: Excellent security posture
- **80-94%**: Good, but needs attention
- **60-79%**: Requires immediate remediation
- **<60%**: Critical security gaps

-----

## 🔍 Common Use Cases

### Check Before Deployment

```bash
# Quick pre-deployment check
inspec exec . -t ssh://staging-server --controls filesystem-* service-* network-*
```

### Daily Compliance Monitoring

```bash
# Add to cron for daily scans
0 2 * * * inspec exec /path/to/profile --reporter json:/var/log/inspec/daily-$(date +\%Y\%m\%d).json
```

### Security Audit

```bash
# Comprehensive audit with all reports
inspec exec . \
  --reporter cli \
  --reporter json:audit-$(date +%Y%m%d).json \
  --reporter html:audit-$(date +%Y%m%d).html \
  --show-progress
```

### CI/CD Integration

```bash
# Always exit 0 for CI/CD
inspec exec . \
  --no-distinct-exit \
  --reporter json:compliance.json
```

-----

## 🆘 Troubleshooting

### Problem: “Permission denied (publickey)”

```bash
# Solution 1: Use password authentication
inspec exec . -t ssh://user@host --password 'yourpassword'

# Solution 2: Fix SSH key permissions
chmod 600 ~/.ssh/id_rsa

# Solution 3: Specify exact key
inspec exec . -t ssh://user@host -i ~/.ssh/specific_key
```

### Problem: Controls failing that shouldn’t

```bash
# Check profile syntax
inspec check .

# Run with debug output
inspec exec . --log-level debug

# Use waivers for known exceptions
inspec exec . --waiver-file waivers.yml
```

### Problem: Slow execution

```bash
# Test specific controls only
inspec exec . --controls filesystem-01 user-01

# Cache results
inspec exec . --backend-cache
```

-----

## 📚 Next Steps

Now that you’ve run your first scans:

1. **Review Failed Controls**: Understand why they failed
1. **Prioritize Fixes**: Start with critical/high impact
1. **Create Remediation Plan**: Document fixes needed
1. **Implement Changes**: Apply security hardening
1. **Re-test**: Verify improvements
1. **Automate**: Add to CI/CD pipeline

### Learn More

- Read full <README.md> for detailed information
- Check <TESTING.md> for advanced testing scenarios
- Review <CI-CD-Integration-Examples.md> for automation
- Study the [control files](controls/) to understand checks

-----

## 💡 Pro Tips

1. **Start Small**: Test one control group at a time
1. **Document Everything**: Use waivers with good justification
1. **Track Progress**: Save reports to see improvement over time
1. **Share Results**: HTML reports are great for stakeholders
1. **Automate Early**: Integrate into CI/CD from the start
1. **Regular Scans**: Weekly minimum, daily recommended
1. **Custom Profiles**: Adapt this profile for your needs

-----

## 🎓 Understanding InSpec

### Key Concepts in 30 Seconds

**Profile**: Collection of security controls (this repository)

**Control**: Individual security check (e.g., “SSH root login disabled”)

**Resource**: InSpec object to test (e.g., `file`, `service`, `user`)

**Matcher**: Test assertion (e.g., `should exist`, `should be_running`)

**Example Control:**

```ruby
control 'ssh-01' do
  impact 1.0
  title 'Ensure SSH root login is disabled'
  
  describe sshd_config do
    its('PermitRootLogin') { should cmp 'no' }
  end
end
```

**Translation**: Check if SSH config has `PermitRootLogin no`

-----

## 🚀 Ready to Start?

Pick your quickstart option above and run your first security scan in under 5 minutes!

**Questions?** Check the detailed <README.md> or [open an issue](https://github.com/yourusername/learning-inspec/issues).

-----

**Created by**: Willem van Heemstra  

**Purpose**: Make security compliance testing accessible and practical
