# Testing Guide for InSpec Profile

This guide provides comprehensive instructions for testing and validating the Linux Security Baseline InSpec profile in various environments.

## Table of Contents

1. [Quick Start Testing](#quick-start-testing)
1. [Local Testing](#local-testing)
1. [Testing Against Docker Containers](#testing-against-docker-containers)
1. [Remote System Testing](#remote-system-testing)
1. [Testing with Kitchen](#testing-with-kitchen)
1. [Troubleshooting](#troubleshooting)
1. [Creating Test Environments](#creating-test-environments)

-----

## Quick Start Testing

### Test Locally (Fastest)

```bash
# Run all controls on your local machine
inspec exec .

# Run with detailed output
inspec exec . --reporter cli:verbose

# Run specific controls
inspec exec . --controls filesystem-01 filesystem-02
```

### Generate Reports

```bash
# HTML Report
inspec exec . --reporter html:report.html

# JSON Report (for programmatic analysis)
inspec exec . --reporter json:report.json

# Multiple reporters at once
inspec exec . --reporter cli json:report.json html:report.html
```

-----

## Local Testing

### Prerequisites

```bash
# Install InSpec
curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec

# Verify installation
inspec --version
```

### Run Profile Locally

```bash
# Check profile syntax
inspec check .

# Run with progress indicators
inspec exec . --show-progress

# Run with custom inputs
inspec exec . --input-file inputs.yml

# Run only high-impact controls
inspec exec . --controls $(grep -l "impact 0.9\|impact 1.0" controls/*.rb | xargs -n1 basename | cut -d. -f1 | paste -sd,)
```

### Testing Specific Control Groups

```bash
# Test only filesystem security
inspec exec . --controls filesystem-*

# Test only user management
inspec exec . --controls user-*

# Test only network security
inspec exec . --controls network-*

# Test only service hardening
inspec exec . --controls service-*

# Test only application security
inspec exec . --controls app-*
```

-----

## Testing Against Docker Containers

### Setup Test Container

Create a Docker container for testing:

```bash
# Start a Ubuntu container
docker run -d --name inspec-test \
  -p 2222:22 \
  ubuntu:22.04 \
  /bin/bash -c "apt-get update && apt-get install -y openssh-server sudo && \
  mkdir /var/run/sshd && \
  echo 'root:testpass' | chpasswd && \
  sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
  /usr/sbin/sshd -D"

# Or use the provided docker-compose.yml
docker-compose up -d
```

### Run InSpec Against Container

```bash
# Test against Docker container directly
inspec exec . -t docker://inspec-test

# Test via SSH
inspec exec . -t ssh://root@localhost:2222 --password testpass

# Generate report
inspec exec . -t docker://inspec-test \
  --reporter json:docker-test-report.json \
  --reporter html:docker-test-report.html
```

### Cleanup

```bash
# Stop and remove container
docker stop inspec-test
docker rm inspec-test

# Or with docker-compose
docker-compose down
```

-----

## Remote System Testing

### SSH Authentication Methods

#### Using Password

```bash
inspec exec . -t ssh://user@hostname --password 'yourpassword'
```

#### Using SSH Key (Recommended)

```bash
# With default SSH key
inspec exec . -t ssh://user@hostname

# With specific key
inspec exec . -t ssh://user@hostname -i ~/.ssh/specific_key

# With specific port
inspec exec . -t ssh://user@hostname:2222 -i ~/.ssh/id_rsa
```

#### Using SSH Config

```bash
# ~/.ssh/config
Host test-server
    HostName 192.168.1.100
    User admin
    Port 22
    IdentityFile ~/.ssh/test_key

# Run InSpec
inspec exec . -t ssh://test-server
```

### Testing Multiple Hosts

Create a hosts file (`hosts.txt`):

```
ssh://admin@server1.example.com
ssh://admin@server2.example.com
ssh://admin@server3.example.com
```

Run against all hosts:

```bash
#!/bin/bash
while IFS= read -r host; do
  echo "Testing $host"
  inspec exec . -t "$host" -i ~/.ssh/id_rsa \
    --reporter json:reports/$(echo $host | sed 's/.*@//; s/\..*//').json
done < hosts.txt
```

-----

## Testing with Kitchen

Test Kitchen provides automated testing across multiple platforms.

### Install Kitchen

```bash
gem install test-kitchen
gem install kitchen-inspec
gem install kitchen-docker
```

### Kitchen Configuration

Create `.kitchen.yml`:

```yaml
---
driver:
  name: docker
  use_sudo: false

provisioner:
  name: shell

verifier:
  name: inspec
  sudo: true

platforms:
  - name: ubuntu-22.04
  - name: ubuntu-20.04
  - name: centos-8
  - name: debian-11

suites:
  - name: default
    verifier:
      inspec_tests:
        - path: .
      controls:
        - /filesystem-.*/
        - /user-.*/
        - /service-.*/
        - /network-.*/
        - /app-.*/
```

### Run Kitchen Tests

```bash
# List instances
kitchen list

# Create instances
kitchen create

# Run tests
kitchen verify

# Run full cycle (create, converge, verify, destroy)
kitchen test

# Test specific platform
kitchen test ubuntu-2204

# Keep instance alive for debugging
kitchen verify ubuntu-2204
```

-----

## Troubleshooting

### Common Issues and Solutions

#### Issue: Permission Denied

```bash
# Error
Permission denied (publickey,password)

# Solution
# Ensure SSH key has correct permissions
chmod 600 ~/.ssh/id_rsa

# Or use password authentication
inspec exec . -t ssh://user@host --password 'yourpassword'
```

#### Issue: Control Failures Due to Missing Packages

```bash
# Error
×  package 'docker' is expected not to be installed
   expected that `package 'docker'` is not installed

# Solution
# Use waivers for environment-specific exceptions (see waivers.yml)
inspec exec . --waiver-file waivers.yml
```

#### Issue: Timeout Connecting to Remote Host

```bash
# Error
Train::Transports::SSHFailed: SSH connection failed

# Solution
# Increase timeout
inspec exec . -t ssh://user@host --connection-timeout 60

# Check connectivity first
ssh user@host "echo 'Connection OK'"
```

#### Issue: Profile Dependencies Not Found

```bash
# Error
Profile dependency 'linux-baseline' cannot be fetched

# Solution
# Install dependencies
inspec vendor --overwrite
```

### Debug Mode

Run InSpec with debugging enabled:

```bash
# Enable debug output
inspec exec . --log-level debug

# Verbose output
inspec exec . --reporter cli:verbose

# Show all skip messages
inspec exec . --show-progress
```

### Validate Profile

```bash
# Check profile for errors
inspec check .

# Archive profile (useful for distribution)
inspec archive . --output linux-security-baseline.tar.gz

# Extract and run archived profile
tar -xzf linux-security-baseline.tar.gz
inspec exec linux-security-baseline
```

-----

## Creating Test Environments

### Vagrant Test Environment

Create `Vagrantfile`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  
  config.vm.define "secure-server" do |server|
    server.vm.hostname = "secure-server"
    server.vm.network "private_network", ip: "192.168.56.10"
  end
  
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y openssh-server
  SHELL
end
```

Start and test:

```bash
vagrant up
inspec exec . -t ssh://vagrant@192.168.56.10 --password vagrant
vagrant destroy
```

### Docker Compose Test Environment

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  ubuntu-test:
    image: ubuntu:22.04
    container_name: inspec-ubuntu-test
    command: /bin/bash -c "apt-get update && apt-get install -y openssh-server sudo && 
             mkdir /var/run/sshd && 
             useradd -m -s /bin/bash testuser && 
             echo 'testuser:testpass' | chpasswd && 
             echo 'testuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && 
             /usr/sbin/sshd -D"
    ports:
      - "2222:22"
    networks:
      - test-network

  centos-test:
    image: centos:8
    container_name: inspec-centos-test
    command: /bin/bash -c "yum install -y openssh-server sudo && 
             ssh-keygen -A && 
             useradd -m -s /bin/bash testuser && 
             echo 'testuser:testpass' | chpasswd && 
             echo 'testuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && 
             /usr/sbin/sshd -D"
    ports:
      - "2223:22"
    networks:
      - test-network

networks:
  test-network:
    driver: bridge
```

Test both environments:

```bash
docker-compose up -d

# Test Ubuntu
inspec exec . -t ssh://testuser@localhost:2222 --password testpass

# Test CentOS
inspec exec . -t ssh://testuser@localhost:2223 --password testpass

docker-compose down
```

-----

## Performance Testing

### Measure Execution Time

```bash
# Time the execution
time inspec exec .

# With detailed timing per control
inspec exec . --reporter json:report.json
jq '.profiles[0].controls[] | {title: .title, time: .results[0].run_time}' report.json
```

### Optimize Profile Performance

```bash
# Run only critical controls
inspec exec . --controls $(grep -l "impact 1.0" controls/*.rb | xargs -n1 basename | cut -d. -f1 | paste -sd,)

# Cache results (for repeated testing)
inspec exec . --backend-cache

# Parallel execution (experimental)
inspec exec . --parallel
```

-----

## Continuous Testing

### Cron Job for Regular Scans

```bash
# Add to crontab
crontab -e

# Run daily at 2 AM
0 2 * * * /usr/bin/inspec exec /path/to/profile -t ssh://server --reporter json:/var/log/inspec/daily-$(date +\%Y\%m\%d).json

# Weekly comprehensive scan
0 3 * * 0 /usr/bin/inspec exec /path/to/profile -t ssh://server --reporter html:/var/log/inspec/weekly-$(date +\%Y\%m\%d).html
```

### Monitoring Integration

Send results to monitoring systems:

```bash
# Send to Splunk
inspec exec . --reporter json | curl -X POST http://splunk:8088/services/collector -H "Authorization: Splunk YOUR_TOKEN" -d @-

# Send to Elasticsearch
inspec exec . --reporter json:report.json
curl -X POST "localhost:9200/compliance/_doc" -H 'Content-Type: application/json' -d @report.json

# Send metrics to Prometheus
# (Requires custom exporter script)
```

-----

## Best Practices

1. **Always validate profile before deployment**: `inspec check .`
1. **Use waivers for known exceptions**: Document why controls are waived
1. **Test incrementally**: Start with one control group at a time
1. **Keep reports organized**: Use timestamps and descriptive names
1. **Test in non-production first**: Validate changes in dev/staging
1. **Monitor trends**: Track compliance scores over time
1. **Document failures**: Create tickets for failed controls
1. **Regular updates**: Keep profile updated with new security standards

-----

## Additional Resources

- [InSpec Documentation](https://docs.chef.io/inspec/)
- [InSpec Resources Reference](https://docs.chef.io/inspec/resources/)
- [Dev-Sec Hardening Framework](https://dev-sec.io/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)

-----

**Created by**: Willem van Heemstra
**Purpose**: Demonstrate practical InSpec testing methodologies for security compliance
