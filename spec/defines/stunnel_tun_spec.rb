require 'spec_helper'

describe( 'stunnel::tun', :type => :define ) do
 context 'with a basic tunnel' do
   let(:facts) {{ 'osfamily' => 'RedHat' }}
   let(:title) { 'my-tunnel' }
   let(:params) {{
     :accept => '1234',
     :connect => '2345',
   }}
   it do
     lines = [
       /accept=1234/,
       /connect=2345/,
       /pid\ =\ \/var\/run\/stunnel-my-tunnel.pid/,
       /output\ =\ \/var\/log\/stunnel\/my-tunnel\.log/,
       /debug\ =\ 5/,
       /TIMEOUTidle\ =\ 43200/,
       /# CAfile = \/path\/to\/cafile\.crt/,
     ]
     lines.each do |l|
       should contain_file('/etc/stunnel/conf.d/my-tunnel.conf').with_content(l)
     end
   end

   it 'should contain a sysv init script' do
     should contain_file('/etc/init.d/stunnel-my-tunnel').with_ensure('present')
   end

   it 'should contain a service which requires the init script' do
     should contain_service('stunnel-my-tunnel').with({
       :enable => true,
       :require => 'File[/etc/init.d/stunnel-my-tunnel]',
       :subscribe => 'File[/etc/stunnel/conf.d/my-tunnel.conf]',
     })
   end
 end

 context 'with non-defaults' do
   let(:facts) {{ 'osfamily' => 'RedHat' }}
   let(:title) { 'httpd' }
   let(:params) {{
     :accept => '987',
     :connect => 'localhost:789',
     :cert => '/etc/pki/tls/cert/my-public.crt',
     :cafile => '/etc/pki/tls/certs/ca-bundle.crt',
     :options => 'NO_SSLv2',
     :install_service => 'true',
     :output => '/var/log/stunnel/httpd-stunnel.log',
     :debug => '1',
     :service_opts => { 'TIMEOUTbusy' => '600' },
     :global_opts => { 'compression' => 'deflate' },
     :timeoutidle => '4000',
   }}
   it do
     lines = [
       /accept=987/,
       /connect=localhost:789/,
       /pid\ =\ \/var\/run\/stunnel-httpd.pid/,
       /cert\ =\ \/etc\/pki\/tls\/cert\/my-public.crt/,
       /options\ =\ NO_SSLv2/,
       /output\ =\ \/var\/log\/stunnel\/httpd-stunnel\.log/,
       /debug\ =\ 1/,
       /compression\ =\ deflate/,
       /TIMEOUTbusy\ =\ 600/,
       /TIMEOUTidle\ =\ 4000/,
       /CAfile\ = \/etc\/pki\/tls\/certs\/ca-bundle\.crt/,
     ]
     lines.each do |l|
       should contain_file('/etc/stunnel/conf.d/httpd.conf').with_content(l)
     end
   end
 end

 context 'with multipule socket options' do
   let(:facts) {{ 'osfamily' => 'RedHat' }}
   let(:title) { 'httpd' }
   let(:params) {{
     :accept => '987',
     :connect => 'localhost:789',
     :cert => '/etc/pki/tls/cert/my-public.crt',
     :options => 'NO_SSLv2',
     :install_service => 'true',
     :output => '/var/log/stunnel/httpd-stunnel.log',
     :debug => '1',
     :service_opts => { 'TIMEOUTbusy' => '600' },
     :global_opts => { 'compression' => 'deflate',
                       'socket' => ['l:SO_TIMEOUT=1','r:SO_TIMEOUT=2'],
                     },
     :timeoutidle => '4000',
   }}
   it 'should contain multipule socket lines' do
       should contain_file('/etc/stunnel/conf.d/httpd.conf') \
           .with_content(/socket\ =\ l:SO_TIMEOUT=1\s+socket\ =\ r:SO_TIMEOUT=2/m)
   end
 end

 context 'with multiple back-end servers' do
   ['rr', 'prio'].each do |failover|
     describe "and failover set to \"#{failover}\"" do
       let(:facts) {{ 'osfamily' => 'RedHat' }}
       let(:title) { 'httpd' }
       let(:params) {{
         :accept => '443',
         :connect => ['server1:80', 'server2:80'],
         :failover => failover,
       }}

       it do
         lines = [
           /accept=443/,
           /connect=server1:80/,
           /connect=server2:80/,
         ]
         failover == 'rr' ? lines << /failover=rr/ : lines << /failover=prio/
         lines.each do |l|
           should contain_file('/etc/stunnel/conf.d/httpd.conf').with_content(l)
         end
       end
     end
   end
 end

 context 'with an array of options' do
   let(:facts) {{ 'osfamily' => 'RedHat' }}
   let(:title) { 'httpd' }
   let(:params) {{
     :accept => '987',
     :connect => 'localhost:789',
     :cert => '/etc/pki/tls/cert/my-public.crt',
     :options => ['NO_SSLv2','NO_SSLv3'],
     :install_service => 'true',
     :output => '/var/log/stunnel/httpd-stunnel.log',
     :debug => '1',
     :service_opts => { 'TIMEOUTbusy' => '600' },
     :global_opts => { 'compression' => 'deflate',
                       'socket' => ['l:SO_TIMEOUT=1','r:SO_TIMEOUT=2'],
                     },
     :timeoutidle => '4000',
   }}
   it 'should contain multiple options lines' do
       should contain_file('/etc/stunnel/conf.d/httpd.conf') \
           .with_content(/options = NO_SSLv2$\s+options = NO_SSLv3$/m)
   end
 end

 context 'with ensure = absent' do
   let(:facts) {{ 'osfamily' => 'RedHat' }}
   let(:title) { 'mytunnel' }
   let(:params) {{
     :accept          => '987',
     :connect         => 'localhost:789',
     :ensure          => 'absent',
     :install_service => true,
     :service_ensure  => 'running',
   }}
   it { should contain_file('/etc/stunnel/conf.d/mytunnel.conf').with_ensure('absent') }
   it { should contain_file('/etc/init.d/stunnel-mytunnel').with_ensure('absent') }
   it do
     should contain_service('stunnel-mytunnel').with( {
       :ensure => 'stopped',
       :enable => 'false',
     } )
  end
     it { should contain_service('stunnel-mytunnel').that_comes_before('File[/etc/init.d/stunnel-mytunnel]') }
 end

 context 'with service_init_system = systemd' do
   let(:facts) {{ 'osfamily' => 'RedHat' }}
   let(:title) { 'mytunnel' }
   let(:params) {{
     :accept => '1234',
     :connect => '2345',
     :install_service => 'true',
     :service_init_system => 'systemd',
   }}

   it 'should contain a systemd service unit config' do
     should contain_file('/etc/systemd/system/stunnel-mytunnel.service').with_ensure('present')
   end

   it 'should contain a service which requires the service unit config' do
     should contain_service('stunnel-mytunnel').with({
       :enable => true,
       :require => 'File[/etc/systemd/system/stunnel-mytunnel.service]',
       :subscribe => 'File[/etc/stunnel/conf.d/mytunnel.conf]',
     })
   end
 end

 context ''
end
