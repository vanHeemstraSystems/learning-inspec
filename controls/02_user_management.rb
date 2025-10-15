# User Management Security Controls

# These controls validate proper user account configuration, password policies,

# and access controls to prevent unauthorized access and privilege escalation.

control 'user-01' do
  impact 1.0
  title 'Ensure no accounts have empty passwords'
  desc 'All user accounts must have passwords set to prevent unauthorized access'
  tag 'user'
  tag 'critical'
  tag 'authentication'
  tag 'owasp'

# Parse shadow file for empty passwords (second field is empty)

  describe shadow.where { password.empty? } do
    its('users') { should be_empty }
  end
end

control 'user-02' do
  impact 1.0
  title 'Ensure no non-root accounts have UID 0'
  desc 'Only root should have UID 0 to prevent privilege escalation'
  tag 'user'
  tag 'critical'
  tag 'privilege-escalation'

  describe passwd.where { uid == 0 } do
    its('users') { should eq ['root'] }
    its('count') { should eq 1 }
  end
end

control 'user-03' do
  impact 0.8
  title 'Ensure root login is disabled'
  desc 'Direct root login should be disabled; use sudo instead'
  tag 'user'
  tag 'high'
  tag 'authentication'

  describe user('root') do
    its('shell') { should_not eq '/bin/bash' }
# Root shell should be /sbin/nologin or /usr/sbin/nologin
  end
end

control 'user-04' do
  impact 0.9
  title 'Ensure password expiration is configured'
  desc 'User passwords should expire after a defined period'
  tag 'user'
  tag 'password-policy'
  tag 'high'

  max_age = input('max_password_age')

# Check login.defs for PASS_MAX_DAYS

  describe file('/etc/login.defs') do
    its('content') { should match(/^\s*PASS_MAX_DAYS\s+\d+/) }
  end

# Extract the actual value

  pass_max_days = command("grep '^PASS_MAX_DAYS' /etc/login.defs | awk '{print $2}'").stdout.strip.to_i

  describe "Password maximum age" do
    subject { pass_max_days }
    it { should be <= max_age }
    it { should be > 0 }
  end
end

control 'user-05' do
  impact 0.8
  title 'Ensure password minimum length is configured'
  desc 'Passwords should meet minimum length requirements'
  tag 'user'
  tag 'password-policy'
  tag 'high'

  describe file('/etc/login.defs') do
    its('content') { should match(/^\s*PASS_MIN_LEN\s+\d+/) }
  end

# Minimum password length should be at least 8 characters

  pass_min_len = command("grep '^PASS_MIN_LEN' /etc/login.defs | awk '{print $2}'").stdout.strip.to_i

  describe "Password minimum length" do
    subject { pass_min_len }
    it { should be >= 8 }
  end
end

control 'user-06' do
  impact 0.7
  title 'Ensure all users have valid home directories'
  desc 'User home directories should exist with proper ownership'
  tag 'user'
  tag 'medium'

  passwd.where { uid >= 1000 && uid < 65534 }.entries.each do |user_info|
    next if user_info.home.nil? || user_info.home == '/nonexistent'

    describe file(user_info.home) do
      it { should exist }
      it { should be_directory }
      its('owner') { should eq user_info.user }
    end

  end
end

control 'user-07' do
  impact 0.8
  title 'Ensure user home directories have proper permissions'
  desc 'Home directories should not be world-readable or world-writable'
  tag 'user'
  tag 'high'
  tag 'privacy'

  passwd.where { uid >= 1000 && uid < 65534 }.entries.each do |user_info|
    next if user_info.home.nil? || user_info.home == '/nonexistent'
    next unless directory(user_info.home).exist?

    describe directory(user_info.home) do
      it { should_not be_writable.by('group') }
      it { should_not be_writable.by('others') }
      it { should_not be_executable.by('others') }
    end

  end
end

control 'user-08' do
  impact 0.9
  title 'Ensure users have secure shell configurations'
  desc 'User .ssh directories should have proper permissions'
  tag 'user'
  tag 'ssh'
  tag 'high'

  passwd.where { uid >= 1000 && uid < 65534 }.entries.each do |user_info|
    ssh_dir = "#{user_info.home}/.ssh"
    next unless directory(ssh_dir).exist?

    describe directory(ssh_dir) do
      its('mode') { should cmp '0700' }
      its('owner') { should eq user_info.user }
    end

    # Check authorized_keys if it exists
    auth_keys = "#{ssh_dir}/authorized_keys"
    if file(auth_keys).exist?
      describe file(auth_keys) do
        its('mode') { should cmp '0600' }
        its('owner') { should eq user_info.user }
      end
    end
end
end

control 'user-09' do
  impact 0.8
  title 'Ensure no duplicate usernames exist'
  desc 'Duplicate usernames can cause confusion and security issues'
  tag 'user'
  tag 'high'

  describe passwd.usernames do
    its('length') { should eq passwd.usernames.uniq.length }
  end
end

control 'user-10' do
  impact 0.8
  title 'Ensure no duplicate UIDs exist'
  desc 'Duplicate UIDs can cause file ownership and permission issues'
  tag 'user'
  tag 'high'

  describe passwd.uids do
    its('length') { should eq passwd.uids.uniq.length }
  end
end

control 'user-11' do
  impact 0.7
  title 'Ensure no duplicate group names exist'
  desc 'Duplicate group names can cause permission issues'
  tag 'user'
  tag 'groups'
  tag 'medium'

  describe etc_group.groups do
    its('length') { should eq etc_group.groups.uniq.length }
  end
end

control 'user-12' do
  impact 0.7
  title 'Ensure no duplicate GIDs exist'
  desc 'Duplicate GIDs can cause permission issues'
  tag 'user'
  tag 'groups'
  tag 'medium'

  describe etc_group.gids do
    its('length') { should eq etc_group.gids.uniq.length }
  end
end

control 'user-13' do
  impact 0.6
  title 'Ensure system accounts are non-login'
  desc 'System accounts should have nologin shell to prevent interactive access'
  tag 'user'
  tag 'medium'

# System accounts typically have UID < 1000

  passwd.where { uid < 1000 && uid != 0 }.entries.each do |user_info|
    next if user_info.user == 'sync' # sync has a special shell

    describe user(user_info.user) do
      its('shell') { should be_in ['/sbin/nologin', '/usr/sbin/nologin', '/bin/false'] }
    end

  end
end

control 'user-14' do
  impact 0.9
  title 'Ensure password reuse is limited'
  desc 'Users should not be able to reuse recent passwords'
  tag 'user'
  tag 'password-policy'
  tag 'high'

# Check if PAM is configured to remember passwords

  pam_files = ['/etc/pam.d/common-password', '/etc/pam.d/system-auth']

  pam_files.each do |pam_file|
    next unless file(pam_file).exist?

    describe file(pam_file) do
      its('content') { should match(/pam_unix\.so.*remember=([5-9]|[1-9]\d+)/) }
    end

  end
end

control 'user-15' do
  impact 0.8
  title 'Ensure inactive password lock is configured'
  desc 'User accounts should be locked after a period of inactivity'
  tag 'user'
  tag 'password-policy'
  tag 'high'

# Check for INACTIVE setting in /etc/default/useradd

  describe file('/etc/default/useradd') do
    its('content') { should match(/^\s*INACTIVE=\d+/) }
  end

  inactive_days = command("grep '^INACTIVE' /etc/default/useradd | cut -d= -f2").stdout.strip.to_i

  describe "Inactive password lock period" do
    subject { inactive_days }
    it { should be <= 30 }
    it { should be > 0 }
  end
end
