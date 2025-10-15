# Network Security Controls

# These controls validate network configurations, firewall rules, and

# network-level security settings to prevent unauthorized network access

# and protect against network-based attacks.

control ‘network-01’ do
impact 0.9
title ‘Ensure IP forwarding is disabled’
desc ‘IP forwarding should be disabled unless the system acts as a router’
tag ‘network’
tag ‘high’
tag ‘network-configuration’

describe kernel_parameter(‘net.ipv4.ip_forward’) do
its(‘value’) { should eq 0 }
end
end

control ‘network-02’ do
impact 0.8
title ‘Ensure packet redirect sending is disabled’
desc ‘ICMP redirects should be disabled to prevent routing table manipulation’
tag ‘network’
tag ‘high’
tag ‘network-configuration’

describe kernel_parameter(‘net.ipv4.conf.all.send_redirects’) do
its(‘value’) { should eq 0 }
end

describe kernel_parameter(‘net.ipv4.conf.default.send_redirects’) do
its(‘value’) { should eq 0 }
end
end

control ‘network-03’ do
impact 0.8
title ‘Ensure source routed packets are not accepted’
desc ‘Source routing can be used to bypass security measures’
tag ‘network’
tag ‘high’
tag ‘network-configuration’

describe kernel_parameter(‘net.ipv4.conf.all.accept_source_route’) do
its(‘value’) { should eq 0 }
end

describe kernel_parameter(‘net.ipv4.conf.default.accept_source_route’) do
its(‘value’) { should eq 0 }
end
end

control ‘network-04’ do
impact 0.8
title ‘Ensure ICMP redirects are not accepted’
desc ‘ICMP redirects can be used for man-in-the-middle attacks’
tag ‘network’
tag ‘high’
tag ‘network-configuration’

describe kernel_parameter(‘net.ipv4.conf.all.accept_redirects’) do
its(‘value’) { should eq 0 }
end

describe kernel_parameter(‘net.ipv4.conf.default.accept_redirects’) do
its(‘value’) { should eq 0 }
end
end

control ‘network-05’ do
impact 0.8
title ‘Ensure secure ICMP redirects are not accepted’
desc ‘Even secure ICMP redirects should be disabled’
tag ‘network’
tag ‘high’
tag ‘network-configuration’

describe kernel_parameter(‘net.ipv4.conf.all.secure_redirects’) do
its(‘value’) { should eq 0 }
end

describe kernel_parameter(‘net.ipv4.conf.default.secure_redirects’) do
its(‘value’) { should eq 0 }
end
end

control ‘network-06’ do
impact 0.8
title ‘Ensure suspicious packets are logged’
desc ‘Suspicious packets should be logged for security monitoring’
tag ‘network’
tag ‘high’
tag ‘logging’

describe kernel_parameter(‘net.ipv4.conf.all.log_martians’) do
its(‘value’) { should eq 1 }
end

describe kernel_parameter(‘net.ipv4.conf.default.log_martians’) do
its(‘value’) { should eq 1 }
end
end

control ‘network-07’ do
impact 0.8
title ‘Ensure broadcast ICMP requests are ignored’
desc ‘Broadcast ICMP can be used for Smurf attacks’
tag ‘network’
tag ‘high’
tag ‘dos-protection’

describe kernel_parameter(‘net.ipv4.icmp_echo_ignore_broadcasts’) do
its(‘value’) { should eq 1 }
end
end

control ‘network-08’ do
impact 0.7
title ‘Ensure bogus ICMP responses are ignored’
desc ‘Bogus ICMP error responses should be ignored’
tag ‘network’
tag ‘medium’
tag ‘network-configuration’

describe kernel_parameter(‘net.ipv4.icmp_ignore_bogus_error_responses’) do
its(‘value’) { should eq 1 }
end
end

control ‘network-09’ do
impact 0.8
title ‘Ensure Reverse Path Filtering is enabled’
desc ‘RPF helps prevent IP spoofing attacks’
tag ‘network’
tag ‘high’
tag ‘spoofing-protection’

describe kernel_parameter(‘net.ipv4.conf.all.rp_filter’) do
its(‘value’) { should eq 1 }
end

describe kernel_parameter(‘net.ipv4.conf.default.rp_filter’) do
its(‘value’) { should eq 1 }
end
end

control ‘network-10’ do
impact 0.8
title ‘Ensure TCP SYN Cookies are enabled’
desc ‘SYN Cookies protect against SYN flood attacks’
tag ‘network’
tag ‘high’
tag ‘dos-protection’

describe kernel_parameter(‘net.ipv4.tcp_syncookies’) do
its(‘value’) { should eq 1 }
end
end

control ‘network-11’ do
impact 0.9
title ‘Ensure IPv6 router advertisements are not accepted’
desc ‘IPv6 RA can be used for man-in-the-middle attacks’
tag ‘network’
tag ‘ipv6’
tag ‘high’

only_if { kernel_parameter(‘net.ipv6.conf.all.disable_ipv6’).value != 1 }

describe kernel_parameter(‘net.ipv6.conf.all.accept_ra’) do
its(‘value’) { should eq 0 }
end

describe kernel_parameter(‘net.ipv6.conf.default.accept_ra’) do
its(‘value’) { should eq 0 }
end
end

control ‘network-12’ do
impact 0.8
title ‘Ensure IPv6 redirects are not accepted’
desc ‘IPv6 redirects should be disabled’
tag ‘network’
tag ‘ipv6’
tag ‘high’

only_if { kernel_parameter(‘net.ipv6.conf.all.disable_ipv6’).value != 1 }

describe kernel_parameter(‘net.ipv6.conf.all.accept_redirects’) do
its(‘value’) { should eq 0 }
end

describe kernel_parameter(‘net.ipv6.conf.default.accept_redirects’) do
its(‘value’) { should eq 0 }
end
end

control ‘network-13’ do
impact 0.9
title ‘Ensure only approved ports are listening’
desc ‘Only necessary ports should be open to reduce attack surface’
tag ‘network’
tag ‘ports’
tag ‘high’
tag ‘attack-surface’

allowed_ports = input(‘allowed_open_ports’)

# Get all listening TCP ports

open_ports = port.where { protocol == ‘tcp’ && address =~ /0.0.0.0|::/ }.ports

open_ports.each do |open_port|
describe “Port #{open_port}” do
subject { open_port }
it { should be_in allowed_ports }
end
end
end

control ‘network-14’ do
impact 0.9
title ‘Ensure SSH is listening on approved port’
desc ‘SSH should be listening on the configured port’
tag ‘network’
tag ‘ssh’
tag ‘high’

ssh_port = input(‘allowed_ssh_port’)

describe port(ssh_port) do
it { should be_listening }
its(‘protocols’) { should include ‘tcp’ }
end
end

control ‘network-15’ do
impact 0.8
title ‘Ensure wireless interfaces are disabled’
desc ‘Wireless interfaces should be disabled on servers’
tag ‘network’
tag ‘wireless’
tag ‘high’

# Check if wireless interfaces exist

wireless_interfaces = command(“ip link show | grep -E ‘^[0-9]+: (wlan|wlp)’ | cut -d: -f2 | tr -d ’ ’”).stdout.split(”\n”)

wireless_interfaces.each do |iface|
next if iface.empty?

```
describe command("ip link show #{iface}") do
  its('stdout') { should match(/state DOWN/) }
end
```

end
end

control ‘network-16’ do
impact 0.7
title ‘Ensure firewall default deny policy is set’
desc ‘Default firewall policy should be to deny all traffic’
tag ‘network’
tag ‘firewall’
tag ‘medium’

# Check iptables default policies

if command(‘which iptables’).exit_status == 0
describe command(‘iptables -L INPUT | grep “policy”’) do
its(‘stdout’) { should match(/policy (DROP|REJECT)/) }
end

```
describe command('iptables -L OUTPUT | grep "policy"') do
  its('stdout') { should match(/policy (DROP|REJECT)/) }
end

describe command('iptables -L FORWARD | grep "policy"') do
  its('stdout') { should match(/policy (DROP|REJECT)/) }
end
```

end
end

control ‘network-17’ do
impact 0.8
title ‘Ensure loopback traffic is configured’
desc ‘Loopback interface should accept all traffic’
tag ‘network’
tag ‘firewall’
tag ‘high’

if command(‘which iptables’).exit_status == 0
describe command(‘iptables -L INPUT -v | grep lo | grep ACCEPT’) do
its(‘exit_status’) { should eq 0 }
end
end
end

control ‘network-18’ do
impact 0.6
title ‘Ensure hosts.allow and hosts.deny are configured’
desc ‘TCP wrappers provide additional access control’
tag ‘network’
tag ‘access-control’
tag ‘medium’

describe file(’/etc/hosts.allow’) do
it { should exist }
its(‘content’) { should_not be_empty }
end

describe file(’/etc/hosts.deny’) do
it { should exist }
end
end

control ‘network-19’ do
impact 0.7
title ‘Ensure uncommon network protocols are disabled’
desc ‘Disable protocols that are not commonly used’
tag ‘network’
tag ‘protocols’
tag ‘medium’

uncommon_protocols = [‘dccp’, ‘sctp’, ‘rds’, ‘tipc’]

uncommon_protocols.each do |protocol|
describe kernel_module(protocol) do
it { should_not be_loaded }
end
end
end

control ‘network-20’ do
impact 0.8
title ‘Ensure network interface promiscuous mode is disabled’
desc ‘Promiscuous mode allows packet sniffing and should be disabled’
tag ‘network’
tag ‘high’
tag ‘packet-sniffing’

# Get all network interfaces

interfaces = command(“ip link show | grep -E ‘^[0-9]+:’ | cut -d: -f2 | tr -d ’ ’”).stdout.split(”\n”)

interfaces.each do |iface|
next if iface.empty? || iface == ‘lo’

```
describe command("ip link show #{iface}") do
  its('stdout') { should_not match(/PROMISC/) }
end
```

end
end
