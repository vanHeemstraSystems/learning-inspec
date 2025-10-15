# Application Security Controls

# These controls validate application-level security configurations including

# Docker security, web server hardening, and package management security.

control ‘app-01’ do
impact 0.8
title ‘Ensure Docker daemon is running with secure configuration’
desc ‘Docker should be configured with security best practices’
tag ‘application’
tag ‘docker’
tag ‘high’

only_if { package(‘docker’).installed? || package(‘docker-ce’).installed? }

describe service(‘docker’) do
it { should be_running }
end

# Check Docker daemon configuration

if file(’/etc/docker/daemon.json’).exist?
describe json(’/etc/docker/daemon.json’) do
its([‘icc’]) { should cmp false }
its([‘live-restore’]) { should cmp true }
end
end
end

control ‘app-02’ do
impact 0.9
title ‘Ensure Docker socket has proper permissions’
desc ‘Docker socket should not be world-readable or world-writable’
tag ‘application’
tag ‘docker’
tag ‘high’

only_if { file(’/var/run/docker.sock’).exist? }

describe file(’/var/run/docker.sock’) do
it { should exist }
it { should_not be_readable.by(‘others’) }
it { should_not be_writable.by(‘others’) }
its(‘owner’) { should eq ‘root’ }
its(‘group’) { should eq ‘docker’ }
end
end

control ‘app-03’ do
impact 0.8
title ‘Ensure Docker TLS authentication is configured’
desc ‘Docker daemon should use TLS for remote connections’
tag ‘application’
tag ‘docker’
tag ‘high’
tag ‘cryptography’

only_if { package(‘docker’).installed? || package(‘docker-ce’).installed? }
only_if { file(’/etc/docker/daemon.json’).exist? }

describe json(’/etc/docker/daemon.json’) do
its([‘tls’]) { should cmp true }
its([‘tlsverify’]) { should cmp true }
end
end

control ‘app-04’ do
impact 0.7
title ‘Ensure unnecessary packages are not installed’
desc ‘Remove or do not install unnecessary packages to reduce attack surface’
tag ‘application’
tag ‘packages’
tag ‘medium’
tag ‘attack-surface’

unnecessary_packages = [‘telnet’, ‘rsh-client’, ‘rsh-redone-client’, ‘talk’, ‘xinetd’]

unnecessary_packages.each do |pkg|
describe package(pkg) do
it { should_not be_installed }
end
end
end

control ‘app-05’ do
impact 0.8
title ‘Ensure package manager GPG keys are configured’
desc ‘Package managers should verify package signatures’
tag ‘application’
tag ‘packages’
tag ‘high’
tag ‘supply-chain-security’

# For Debian/Ubuntu systems

if file(’/etc/apt/apt.conf.d’).exist?
describe file(’/etc/apt/apt.conf.d/99verify-peer.conf’) do
it { should exist }
its(‘content’) { should match(/Acquire::https::Verify-Peer “true”/) }
end
end

# For RedHat/CentOS systems

if file(’/etc/yum.conf’).exist?
describe file(’/etc/yum.conf’) do
its(‘content’) { should match(/gpgcheck=1/) }
end
end
end

control ‘app-06’ do
impact 0.9
title ‘Ensure web server security headers are configured’
desc ‘Web servers should return security headers’
tag ‘application’
tag ‘web’
tag ‘high’
tag ‘owasp’

only_if { package(‘nginx’).installed? || package(‘apache2’).installed? || package(‘httpd’).installed? }

# This is a demonstration - in production, you would test actual HTTP responses

# Check Nginx configuration if installed

if package(‘nginx’).installed? && file(’/etc/nginx/nginx.conf’).exist?
describe file(’/etc/nginx/nginx.conf’) do
its(‘content’) { should match(/add_header X-Frame-Options/) }
its(‘content’) { should match(/add_header X-Content-Type-Options/) }
its(‘content’) { should match(/add_header X-XSS-Protection/) }
end
end

# Check Apache configuration if installed

if (package(‘apache2’).installed? || package(‘httpd’).installed?) && file(’/etc/apache2/apache2.conf’).exist?
describe file(’/etc/apache2/apache2.conf’) do
its(‘content’) { should match(/Header.*X-Frame-Options/) }
end
end
end

control ‘app-07’ do
impact 0.8
title ‘Ensure web server directory listing is disabled’
desc ‘Directory listing should be disabled to prevent information disclosure’
tag ‘application’
tag ‘web’
tag ‘high’
tag ‘information-disclosure’

# Check Nginx configuration

if package(‘nginx’).installed? && file(’/etc/nginx/nginx.conf’).exist?
describe file(’/etc/nginx/nginx.conf’) do
its(‘content’) { should match(/autoindex off/) }
end
end

# Check Apache configuration

if (package(‘apache2’).installed? || package(‘httpd’).installed?)
apache_conf = file(’/etc/apache2/apache2.conf’).exist? ? ‘/etc/apache2/apache2.conf’ : ‘/etc/httpd/conf/httpd.conf’

```
if file(apache_conf).exist?
  describe file(apache_conf) do
    its('content') { should_not match(/Options.*Indexes/) }
  end
end
```

end
end

control ‘app-08’ do
impact 0.7
title ‘Ensure web server runs as non-privileged user’
desc ‘Web server should not run as root’
tag ‘application’
tag ‘web’
tag ‘medium’
tag ‘privilege-escalation’

# Check Nginx

if package(‘nginx’).installed?
describe processes(‘nginx’) do
its(‘users’) { should_not include ‘root’ }
end
end

# Check Apache

if package(‘apache2’).installed? || package(‘httpd’).installed?
describe processes(‘apache2’) do
its(‘users’) { should_not include ‘root’ }
end

```
describe processes('httpd') do
  its('users') { should_not include 'root' }
end
```

end
end

control ‘app-09’ do
impact 0.8
title ‘Ensure default web server content is removed’
desc ‘Default web server pages should be removed’
tag ‘application’
tag ‘web’
tag ‘medium’
tag ‘information-disclosure’

default_pages = [
‘/var/www/html/index.nginx-debian.html’,
‘/var/www/html/index.html’,
‘/usr/share/nginx/html/index.html’
]

default_pages.each do |page|
next unless file(page).exist?

```
describe file(page) do
  its('content') { should_not match(/Welcome to nginx/) }
  its('content') { should_not match(/Apache.*Test Page/) }
end
```

end
end

control ‘app-10’ do
impact 0.8
title ‘Ensure SELinux or AppArmor is enabled’
desc ‘Mandatory Access Control should be enabled’
tag ‘application’
tag ‘mac’
tag ‘high’

# Check for SELinux

if command(‘which getenforce’).exit_status == 0
describe command(‘getenforce’) do
its(‘stdout’) { should match(/Enforcing|Permissive/) }
its(‘stdout’) { should_not match(/Disabled/) }
end
end

# Check for AppArmor

if command(‘which apparmor_status’).exit_status == 0
describe command(‘apparmor_status’) do
its(‘stdout’) { should match(/apparmor module is loaded/) }
end
end
end

control ‘app-11’ do
impact 0.7
title ‘Ensure core dumps are restricted’
desc ‘Core dumps can contain sensitive information’
tag ‘application’
tag ‘medium’
tag ‘information-disclosure’

describe file(’/etc/security/limits.conf’) do
its(‘content’) { should match(/^\s**\s+hard\s+core\s+0/) }
end

describe kernel_parameter(‘fs.suid_dumpable’) do
its(‘value’) { should eq 0 }
end
end

control ‘app-12’ do
impact 0.8
title ‘Ensure ASLR is enabled’
desc ‘Address Space Layout Randomization helps prevent buffer overflow attacks’
tag ‘application’
tag ‘high’
tag ‘exploit-mitigation’

describe kernel_parameter(‘kernel.randomize_va_space’) do
its(‘value’) { should eq 2 }
end
end

control ‘app-13’ do
impact 0.7
title ‘Ensure ptrace scope is restricted’
desc ‘Restrict ptrace to prevent process injection attacks’
tag ‘application’
tag ‘medium’
tag ‘exploit-mitigation’

describe kernel_parameter(‘kernel.yama.ptrace_scope’) do
its(‘value’) { should be >= 1 }
end
end

control ‘app-14’ do
impact 0.8
title ‘Ensure container escape vulnerabilities are mitigated’
desc ‘Docker should run containers with security options’
tag ‘application’
tag ‘docker’
tag ‘high’
tag ‘container-security’

only_if { command(‘docker ps -q’).exit_status == 0 }

# Check running containers for security options

container_ids = command(‘docker ps -q’).stdout.split(”\n”)

container_ids.each do |container_id|
next if container_id.empty?

```
# Ensure containers are not running with privileged flag
describe command("docker inspect #{container_id} | grep '\"Privileged\": true'") do
  its('stdout') { should be_empty }
end
```

end
end

control ‘app-15’ do
impact 0.7
title ‘Ensure automatic updates are configured’
desc ‘Security updates should be applied automatically or regularly’
tag ‘application’
tag ‘updates’
tag ‘medium’

# For Debian/Ubuntu

if package(‘unattended-upgrades’).installed?
describe package(‘unattended-upgrades’) do
it { should be_installed }
end

```
describe service('unattended-upgrades') do
  it { should be_enabled }
end
```

end

# For RedHat/CentOS

if package(‘yum-cron’).installed?
describe package(‘yum-cron’) do
it { should be_installed }
end

```
describe service('yum-cron') do
  it { should be_enabled }
end
```

end
end

control ‘app-16’ do
impact 0.8
title ‘Ensure fail2ban is installed and configured’
desc ‘Fail2ban protects against brute force attacks’
tag ‘application’
tag ‘intrusion-prevention’
tag ‘high’
tag ‘brute-force-protection’

describe package(‘fail2ban’) do
it { should be_installed }
end

describe service(‘fail2ban’) do
it { should be_enabled }
it { should be_running }
end

if file(’/etc/fail2ban/jail.local’).exist?
describe file(’/etc/fail2ban/jail.local’) do
its(‘content’) { should match(/[sshd]/) }
end
end
end

control ‘app-17’ do
impact 0.7
title ‘Ensure database services are not exposed externally’
desc ‘Databases should only listen on localhost or private networks’
tag ‘application’
tag ‘database’
tag ‘medium’

database_ports = [3306, 5432, 27017, 6379] # MySQL, PostgreSQL, MongoDB, Redis

database_ports.each do |db_port|
next unless port(db_port).listening?

```
describe port(db_port) do
  its('addresses') { should_not include '0.0.0.0' }
  its('addresses') { should_not include '::' }
end
```

end
end

control ‘app-18’ do
impact 0.8
title ‘Ensure sensitive files have restricted permissions’
desc ‘Configuration files containing credentials should be protected’
tag ‘application’
tag ‘high’
tag ‘credentials’

sensitive_patterns = [
‘/etc/*.conf’,
’/opt/*/config/*.conf’,
’/etc/*/secrets/*’
]

# This is a simplified check - in production you would scan more thoroughly

if file(’/etc/environment’).exist?
describe file(’/etc/environment’) do
it { should_not be_readable.by(‘others’) }
end
end
end

control ‘app-19’ do
impact 0.7
title ‘Ensure application logs are being collected’
desc ‘Application logs should be written for security monitoring’
tag ‘application’
tag ‘logging’
tag ‘medium’

describe service(‘rsyslog’) do
it { should be_running }
it { should be_enabled }
end

describe file(’/var/log’) do
it { should exist }
it { should be_directory }
end
end

control ‘app-20’ do
impact 0.8
title ‘Ensure audit daemon is running’
desc ‘Audit daemon provides detailed logging for security events’
tag ‘application’
tag ‘auditing’
tag ‘high’
tag ‘compliance’

describe service(‘auditd’) do
it { should be_running }
it { should be_enabled }
end

describe file(’/etc/audit/auditd.conf’) do
it { should exist }
its(‘content’) { should_not be_empty }
end
end
