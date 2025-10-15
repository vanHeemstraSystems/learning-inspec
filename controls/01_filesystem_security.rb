# Filesystem Security Controls

# These controls validate proper file permissions, ownership, and configuration

# of critical system files to prevent unauthorized access and tampering.

control 'filesystem-01' do
  impact 1.0
  title 'Ensure /etc/passwd permissions are configured'
  desc 'The /etc/passwd file contains user account information and should be protected'
  tag 'filesystem'
  tag 'critical'
  tag 'cis-benchmark'

  describe file('/etc/passwd') do
    it { should exist }
    it { should be_file }
    it { should be_readable.by('owner') }
    it { should be_readable.by('group') }
    it { should be_readable.by('others') }
    it { should_not be_writable.by('group') }
    it { should_not be_writable.by('others') }
    it { should_not be_executable }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end
end

control 'filesystem-02' do
  impact 1.0
  title 'Ensure /etc/shadow permissions are configured'
  desc 'The /etc/shadow file stores encrypted passwords and must be highly protected'
  tag 'filesystem'
  tag 'critical'
  tag 'cis-benchmark'

  describe file('/etc/shadow') do
    it { should exist }
    it { should be_file }
    it { should_not be_readable.by('group') }
    it { should_not be_readable.by('others') }
    it { should_not be_writable.by('group') }
    it { should_not be_writable.by('others') }
    it { should_not be_executable }
    its('mode') { should cmp '0600' }
    its('owner') { should eq 'root' }
  end
end

control 'filesystem-03' do
  impact 0.8
  title 'Ensure /etc/group permissions are configured'
  desc 'The /etc/group file contains group information and should be protected'
  tag 'filesystem'
  tag 'high'

  describe file('/etc/group') do
    it { should exist }
    it { should be_file }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end
end

control 'filesystem-04' do
  impact 0.9
  title 'Ensure SSH private host keys have proper permissions'
  desc 'SSH host keys should be readable only by root to prevent unauthorized access'
  tag 'filesystem'
  tag 'ssh'
  tag 'critical'

# Find all SSH private host keys

  command('find /etc/ssh -name "ssh_host_*_key" -type f').stdout.split("\n").each do |keyfile|
    next if keyfile.empty?

    describe file(keyfile) do
      it { should exist }
      it { should be_file }
      it { should_not be_readable.by('group') }
      it { should_not be_readable.by('others') }
      its('mode') { should cmp '0600' }
      its('owner') { should eq 'root' }
    end

  end
end

control 'filesystem-05' do
  impact 0.7
  title 'Ensure SSH public host keys have proper permissions'
  desc 'SSH public host keys should be readable but not writable by non-root'
  tag 'filesystem'
  tag 'ssh'

  command('find /etc/ssh -name "ssh_host_*_key.pub" -type f').stdout.split("\n").each do |keyfile|
    next if keyfile.empty?

    describe file(keyfile) do
      it { should exist }
      it { should be_file }
      it { should_not be_writable.by('group') }
      it { should_not be_writable.by('others') }
      its('mode') { should cmp '0644' }
      its('owner') { should eq 'root' }
    end

  end
end

control 'filesystem-06' do
  impact 0.8
  title 'Ensure no world-writable files exist in system directories'
  desc 'World-writable files in system directories can be exploited for privilege escalation'
  tag 'filesystem'
  tag 'high'
  tag 'owasp'

  system_dirs = ['/etc', '/usr/bin', '/usr/sbin', '/bin', '/sbin']

  system_dirs.each do |dir|
    next unless directory(dir).exist?

    describe command("find #{dir} -xdev -type f -perm -0002 2>/dev/null | head -n 1") do
      its('stdout') { should be_empty }
    end

  end
end

control 'filesystem-07' do
  impact 0.6
  title 'Ensure /tmp has proper mount options'
  desc '/tmp should be mounted with noexec, nodev, and nosuid options'
  tag 'filesystem'
  tag 'medium'

  only_if { file('/tmp').mounted? }

  describe mount('/tmp') do
    it { should be_mounted }
    its('options') { should include 'noexec' }
    its('options') { should include 'nodev' }
    its('options') { should include 'nosuid' }
  end
end

control 'filesystem-08' do
  impact 0.9
  title 'Ensure sudoers file has proper permissions'
  desc 'The sudoers file controls sudo privileges and must be strictly protected'
  tag 'filesystem'
  tag 'critical'
  tag 'privilege-escalation'

  describe file('/etc/sudoers') do
    it { should exist }
    it { should be_file }
    its('mode') { should cmp '0440' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end

# Check sudoers.d directory if it exists

  if directory('/etc/sudoers.d').exist?
    describe directory('/etc/sudoers.d') do
      its('mode') { should cmp '0750' }
      its('owner') { should eq 'root' }
    end  
  end
end

control 'filesystem-09' do
  impact 0.7
  title 'Ensure cron daemon configuration has proper permissions'
  desc 'Cron configuration should be protected to prevent unauthorized job scheduling'
  tag 'filesystem'
  tag 'cron'
  tag 'high'

  ['/etc/crontab', '/etc/cron.d', '/etc/cron.daily', '/etc/cron.hourly',
  '/etc/cron.monthly', '/etc/cron.weekly'].each do |cron_path|
    next unless file(cron_path).exist?

    describe file(cron_path) do
      its('owner') { should eq 'root' }
      its('group') { should eq 'root' }
      it { should_not be_writable.by('group') }
      it { should_not be_writable.by('others') }
    end

  end
end

control 'filesystem-10' do
  impact 0.8
  title 'Ensure log files have proper permissions'
  desc 'Log files should be protected from unauthorized modification and deletion'
  tag 'filesystem'
  tag 'logging'
  tag 'high'

# Check common log directories

  ['/var/log/messages', '/var/log/syslog', '/var/log/auth.log',
  '/var/log/secure'].each do |logfile|
    next unless file(logfile).exist?

    describe file(logfile) do
      it { should_not be_writable.by('group') }
      it { should_not be_writable.by('others') }
      it { should_not be_readable.by('others') }
      its('owner') { should be_in ['root', 'syslog'] }
    end
  end  
end