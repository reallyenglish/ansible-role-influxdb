require "spec_helper"
require "serverspec"

package = "influxdb"
service = "influxd"
config  = "/etc/influxdb/influxd.conf"
user    = "influxd"
group   = "influxd"
ports   = [8083, 8086, 8088]
log_dir = "/var/log/influxdb"
db_dir  = "/var/lib/influxdb"

case os[:family]
when "freebsd"
  config = "/usr/local/etc/influxd.conf"
  db_dir = "/var/db/influxdb"
end

describe package(package) do
  it { should be_installed }
end

describe service(service) do
  it { should be_running }
  it { should be_enabled }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

describe file(config) do
  it { should be_file }
  its(:content) { should match Regexp.escape('dir = "/var/db/influxdb/meta"') }
end

describe file(log_dir) do
  it { should exist }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

describe file(db_dir) do
  it { should exist }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

case os[:family]
when "freebsd"
  describe file("/etc/rc.conf.d/influxd") do
    it { should be_file }
    its(:content) { should match Regexp.escape('influxd_user="influxd"') }
    its(:content) { should match Regexp.escape('influxd_group="influxd"') }
    its(:content) { should match Regexp.escape('influxd_conf="/usr/local/etc/influxd.conf"') }
    its(:content) { should match Regexp.escape('influxdb_flags="-join foo.example.com:8888"') }
  end
end

if 1 == 0
  # XXX serverspec uses 'ps -C procname -o user=' but it is a Linux specific flag
  # TODO create a patch
  # /usr/local/bin/influxd -join foo.example.com:8888 -config=/usr/local/etc/influxd.conf
  describe process("influxd") do
    its(:user) { should eq "influxd" }
    its(:args) { should match Regexp.escape("-join foo.example.com:8888 -config=/usr/local/etc/influxd.conf") }
  end
end
# the work around of above issue
describe command("ps axwwu") do
  its(:stdout) { should match(/^influxd .*/) }
  its(:stdout) { should match Regexp.escape("influxd -join foo.example.com:8888 -config=/usr/local/etc/influxd.conf") }
end
