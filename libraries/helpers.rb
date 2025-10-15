# Helper Library for InSpec Profile

# This file contains custom helper methods that can be used across all controls

# to make controls more readable and maintainable.

# Custom helper class for security checks

class SecurityHelpers < Inspec.resource(1)
  name 'security_helpers'

# Check if a system is a Docker container

  def container?
    file('/.dockerenv').exist? || file('/run/.containerenv').exist?
  end

# Check if a system is a virtual machine

  def virtual_machine?
    inspec.command('systemd-detect-virt').stdout.strip != 'none'
  end

# Get the OS family

  def os_family
    inspec.os.family
  end

# Check if running on cloud platform

  def cloud_platform?
    cloud_providers = ['aws', 'azure', 'gcp', 'digitalocean']
    cloud_providers.any? { |provider| system_has_cloud_metadata?(provider) }
  end

# Helper to check for specific cloud provider

  def cloud_provider
    return 'aws' if file('/sys/hypervisor/uuid').exist? &&
                    inspec.command('cat /sys/hypervisor/uuid').stdout.start_with?('ec2')
    return 'azure' if file('/var/lib/waagent').exist?
    return 'gcp' if inspec.command('dmidecode -s system-manufacturer').stdout.include?('Google')
    'unknown'
  end

# Check if SELinux is available

  def selinux_available?
    inspec.command('which getenforce').exit_status == 0
  end

# Check if AppArmor is available

  def apparmor_available?
    inspec.command('which apparmor_status').exit_status == 0
  end

# Get security-critical system users

  def security_critical_users
    ['root', 'daemon', 'syslog', 'messagebus', 'systemd-network', 'systemd-resolve']
  end

# Check if a port should be monitored

  def monitored_port?(port_number)
    critical_ports = [22, 80, 443, 3306, 5432, 6379, 27017, 9200]
    critical_ports.include?(port_number)
  end

# Helper to determine if a service is security-critical

  def critical_service?(service_name)
    critical_services = ['sshd', 'firewalld', 'ufw', 'fail2ban', 'auditd']
    critical_services.include?(service_name)
  end

# Get weak SSL/TLS protocols

  def weak_tls_protocols
    ['SSLv2', 'SSLv3', 'TLSv1', 'TLSv1.1']
  end

# Get weak SSH ciphers

  def weak_ssh_ciphers
    ['3des-cbc', 'aes128-cbc', 'aes192-cbc', 'aes256-cbc',
    'arcfour', 'arcfour128', 'arcfour256', 'blowfish-cbc',
    'cast128-cbc', 'rijndael-cbc@lysator.liu.se']
  end

# Get weak SSH MACs

  def weak_ssh_macs
    ['hmac-md5', 'hmac-md5-96', 'hmac-ripemd160',
    'hmac-sha1-96', 'umac-64@openssh.com',
    'hmac-md5-etm@openssh.com', 'hmac-md5-96-etm@openssh.com']
  end

# Check if file contains sensitive data patterns

  def contains_sensitive_data?(file_path)
    return false unless inspec.file(file_path).exist?

    content = inspec.file(file_path).content
    sensitive_patterns = [
      /password\s*=\s*.+/i,
      /api[_-]?key\s*=\s*.+/i,
      /secret\s*=\s*.+/i,
      /token\s*=\s*.+/i,
      /-----BEGIN PRIVATE KEY-----/,
      /-----BEGIN RSA PRIVATE KEY-----/
    ]

    sensitive_patterns.any? { |pattern| content.match?(pattern) }
  end

# Get list of privileged system directories

  def privileged_directories
    ['/root', '/etc', '/boot', '/usr/bin', '/usr/sbin', '/bin', '/sbin']
  end

# Check if user is a system account

  def system_account?(uid)
    uid < 1000
  end

# Get recommended file modes for different file types

  def recommended_mode(file_type)
    modes = {
    'password_file' => '0644',
    'shadow_file' => '0600',
    'ssh_private_key' => '0600',
    'ssh_public_key' => '0644',
    'sudoers' => '0440',
    'cron' => '0644',
    'log_file' => '0640',
    'config_file' => '0644',
    'script' => '0755'
    }
    modes[file_type] || '0644'
  end

  private

  def system_has_cloud_metadata?(provider)
    case provider
    when 'aws'
      inspec.http('http://169.254.169.254/latest/meta-data/', max_redirects: 0).status == 200
    when 'azure'
      inspec.file('/var/lib/waagent').exist?
    when 'gcp'
      inspec.http('http://metadata.google.internal/computeMetadata/v1/',
                  headers: {'Metadata-Flavor' => 'Google'}).status == 200
    else
      false
    end
  rescue
    false
  end
end

# Custom matcher for more expressive tests

class SecurityMatchers

  # Check if permissions are more restrictive than specified

  def self.more_restrictive_than?(actual_mode, required_mode)
    actual_octal = actual_mode.to_s(8).to_i
    required_octal = required_mode.to_s(8).to_i
    actual_octal <= required_octal
  end

  # Check if a user has excessive privileges

  def self.excessive_privileges?(uid, gid)
    uid == 0 && gid != 0 # Root UID but non-root GID might indicate misconfiguration
  end

  # Validate password complexity

  def self.strong_password_policy?(min_length, require_special)
    min_length >= 12 && require_special
  end
end
