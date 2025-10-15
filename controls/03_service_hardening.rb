# Service Hardening Controls

# These controls validate that services are properly configured for security,

# unnecessary services are disabled, and critical services are running with

# appropriate security settings.

control ‘service-01’ do
impact 0.9
title ‘Ensure SSH service is running’
desc ‘SSH should be running for secure remote access’
tag ‘service’
tag ‘ssh’
tag ‘high’

describe service(‘sshd’) do
it { should be_installed }
it { should be_enabled }
it { should be_running }
end
end

control ‘service-02’ do
impact 1.0
title ‘Ensure SSH Protocol 2 is enforced’
desc ‘SSH Protocol 1 has known vulnerabilities and should not be used’
tag ‘service’
tag ‘ssh’
tag ‘critical’
tag ‘owasp’

describe sshd_config do
its(‘Protocol’) { should cmp ‘2’ }
end
end

control ‘service-03’ do
impact 1.0
title ‘Ensure SSH root login is disabled’
desc ‘Direct root login via SSH should be prohibited’
tag ‘service’
tag ‘ssh’
tag ‘critical’
tag ‘privilege-escalation’

describe sshd_config do
its(‘PermitRootLogin’) { should cmp ‘no’ }
end
end

control ‘service-04’ do
impact 0.9
title ‘Ensure SSH PermitEmptyPasswords is disabled’
desc ‘SSH should not allow authentication with empty passwords’
tag ‘service’
tag ‘ssh’
tag ‘high’
tag ‘authentication’

describe sshd_config do
its(‘PermitEmptyPasswords’) { should cmp ‘no’ }
end
end

control ‘service-05’ do
impact 0.8
title ‘Ensure SSH X11 forwarding is disabled’
desc ‘X11 forwarding should be disabled unless specifically required’
tag ‘service’
tag ‘ssh’
tag ‘high’

describe sshd_config do
its(‘X11Forwarding’) { should cmp ‘no’ }
end
end

control ‘service-06’ do
impact 0.9
title ‘Ensure SSH MaxAuthTries is configured’
desc ‘Limit authentication attempts to prevent brute force attacks’
tag ‘service’
tag ‘ssh’
tag ‘high’
tag ‘brute-force-protection’

describe sshd_config do
its(‘MaxAuthTries’) { should be <= 4 }
end
end

control ‘service-07’ do
impact 0.8
title ‘Ensure SSH HostbasedAuthentication is disabled’
desc ‘Host-based authentication is less secure than key-based authentication’
tag ‘service’
tag ‘ssh’
tag ‘high’

describe sshd_config do
its(‘HostbasedAuthentication’) { should cmp ‘no’ }
end
end

control ‘service-08’ do
impact 0.8
title ‘Ensure SSH is configured to use strong ciphers’
desc ‘Weak ciphers should be disabled to prevent cryptographic attacks’
tag ‘service’
tag ‘ssh’
tag ‘high’
tag ‘cryptography’

# List of weak ciphers that should not be present

weak_ciphers = [‘3des-cbc’, ‘aes128-cbc’, ‘aes192-cbc’, ‘aes256-cbc’, ‘arcfour’, ‘arcfour128’, ‘arcfour256’]

if sshd_config.params[‘Ciphers’]
configured_ciphers = sshd_config.params[‘Ciphers’].first.split(’,’)

```
weak_ciphers.each do |weak_cipher|
  describe "SSH cipher configuration" do
    subject { configured_ciphers }
    it { should_not include weak_cipher }
  end
end
```

end
end

control ‘service-09’ do
impact 0.8
title ‘Ensure SSH is configured to use strong MAC algorithms’
desc ‘Weak MAC algorithms should be disabled’
tag ‘service’
tag ‘ssh’
tag ‘high’
tag ‘cryptography’

# List of weak MAC algorithms

weak_macs = [‘hmac-md5’, ‘hmac-md5-96’, ‘hmac-ripemd160’, ‘hmac-sha1-96’, ‘umac-64@openssh.com’]

if sshd_config.params[‘MACs’]
configured_macs = sshd_config.params[‘MACs’].first.split(’,’)

```
weak_macs.each do |weak_mac|
  describe "SSH MAC configuration" do
    subject { configured_macs }
    it { should_not include weak_mac }
  end
end
```

end
end

control ‘service-10’ do
impact 0.9
title ‘Ensure telnet service is not installed’
desc ‘Telnet is unencrypted and should never be used’
tag ‘service’
tag ‘critical’
tag ‘insecure-protocol’

describe package(‘telnet-server’) do
it { should_not be_installed }
end

describe service(‘telnet’) do
it { should_not be_running }
end
end

control ‘service-11’ do
impact 0.9
title ‘Ensure FTP service is not running’
desc ‘FTP is unencrypted; use SFTP or SCP instead’
tag ‘service’
tag ‘high’
tag ‘insecure-protocol’

%w[vsftpd ftpd].each do |ftp_service|
describe service(ftp_service) do
it { should_not be_running }
end
end
end

control ‘service-12’ do
impact 0.8
title ‘Ensure rsync service is not enabled unless required’
desc ‘Rsync daemon should be disabled if not needed’
tag ‘service’
tag ‘medium’

describe service(‘rsyncd’) do
it { should_not be_enabled }
end
end

control ‘service-13’ do
impact 0.7
title ‘Ensure avahi daemon is not running’
desc ‘Avahi announces services on the network and may leak information’
tag ‘service’
tag ‘medium’
tag ‘information-disclosure’

describe service(‘avahi-daemon’) do
it { should_not be_running }
end
end

control ‘service-14’ do
impact 0.9
title ‘Ensure critical services are running’
desc ‘Services defined as critical should be running and enabled’
tag ‘service’
tag ‘availability’
tag ‘high’

critical_services = input(‘critical_services’)

critical_services.each do |service_name|
describe service(service_name) do
it { should be_running }
it { should be_enabled }
end
end
end

control ‘service-15’ do
impact 0.9
title ‘Ensure prohibited services are not running’
desc ‘Services defined as prohibited should not be running’
tag ‘service’
tag ‘high’

prohibited_services = input(‘prohibited_services’)

prohibited_services.each do |service_name|
describe service(service_name) do
it { should_not be_running }
end
end
end

control ‘service-16’ do
impact 0.8
title ‘Ensure SSH ClientAliveInterval and ClientAliveCountMax are configured’
desc ‘Idle SSH sessions should be terminated after a timeout period’
tag ‘service’
tag ‘ssh’
tag ‘high’
tag ‘session-management’

describe sshd_config do
its(‘ClientAliveInterval’) { should be <= 300 }
its(‘ClientAliveInterval’) { should be > 0 }
end

describe sshd_config do
its(‘ClientAliveCountMax’) { should be <= 3 }
end
end

control ‘service-17’ do
impact 0.8
title ‘Ensure SSH LoginGraceTime is configured’
desc ‘Limit the time allowed for successful authentication’
tag ‘service’
tag ‘ssh’
tag ‘high’
tag ‘dos-protection’

describe sshd_config do
its(‘LoginGraceTime’) { should be <= 60 }
end
end

control ‘service-18’ do
impact 0.7
title ‘Ensure SSH banner is configured’
desc ‘Display a warning banner before authentication’
tag ‘service’
tag ‘ssh’
tag ‘medium’
tag ‘legal-notice’

describe sshd_config do
its(‘Banner’) { should_not cmp ‘none’ }
its(‘Banner’) { should_not be_nil }
end
end

control ‘service-19’ do
impact 0.8
title ‘Ensure firewall service is running’
desc ‘A firewall should be active to control network traffic’
tag ‘service’
tag ‘network’
tag ‘high’

# Check for common firewall services

firewall_services = [‘firewalld’, ‘ufw’, ‘iptables’]

at_least_one_running = firewall_services.any? do |fw|
service(fw).running?
end

describe “Firewall service status” do
subject { at_least_one_running }
it { should be true }
end
end

control ‘service-20’ do
impact 0.7
title ‘Ensure time synchronization is enabled’
desc ‘System time should be synchronized for accurate logging and authentication’
tag ‘service’
tag ‘time’
tag ‘medium’

time_services = [‘chronyd’, ‘ntpd’, ‘systemd-timesyncd’]

at_least_one_running = time_services.any? do |ts|
service(ts).running?
end

describe “Time synchronization service status” do
subject { at_least_one_running }
it { should be true }
end
end
