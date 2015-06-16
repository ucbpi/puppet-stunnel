require 'spec_helper'

describe( 'stunnel::tun', :type => :define ) do
 context "with a basic tunnel" do
   let(:facts) {{ 'osfamily' => 'RedHat' }}
   let(:title) { 'my-tunnel' }
   let(:params) {{
     'accept' => '1234',
     'connect' => '2345',
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
 end

 context "with non-defaults" do
   let(:facts) {{ 'osfamily' => 'RedHat' }}
   let(:title) { 'httpd' }
   let(:params) {{
     'accept' => '987',
     'connect' => 'localhost:789',
     'cert' => '/etc/pki/tls/cert/my-public.crt',
     :cafile => '/etc/pki/tls/certs/ca-bundle.crt',
     'options' => 'NO_SSLv2',
     'install_service' => 'true',
     :output => '/var/log/stunnel/httpd-stunnel.log',
     :debug => '1',
     :service_opts => { 'TIMEOUTbusy' => '600' },
     :global_opts => { 'compression' => 'deflate' },
     :timeoutidle => '4000',
   }}
   it do
     should contain_service('stunnel-httpd').with({
       'enable' => true,
       'require' => 'File[/etc/init.d/stunnel-httpd]',
       'subscribe' => 'File[/etc/stunnel/conf.d/httpd.conf]',
     })

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

 context "with multipule socket options" do
   let(:facts) {{ 'osfamily' => 'RedHat' }}
   let(:title) { 'httpd' }
   let(:params) {{
     'accept' => '987',
     'connect' => 'localhost:789',
     'cert' => '/etc/pki/tls/cert/my-public.crt',
     'options' => 'NO_SSLv2',
     'install_service' => 'true',
     :output => '/var/log/stunnel/httpd-stunnel.log',
     :debug => '1',
     :service_opts => { 'TIMEOUTbusy' => '600' },
     :global_opts => { 'compression' => 'deflate',
                       'socket' => ['l:SO_TIMEOUT=1','r:SO_TIMEOUT=2'],
                     },
     :timeoutidle => '4000',
   }}
   it "should contain multipule socket lines" do
       should contain_file('/etc/stunnel/conf.d/httpd.conf') \
           .with_content(/socket\ =\ l:SO_TIMEOUT=1\s+socket\ =\ r:SO_TIMEOUT=2/m)
   end
 end

 context "with multiple back-end servers" do
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

 context "with client=true and no cert" do
   let(:facts) {{ 'osfamily' => 'RedHat' }}
   let(:title) { 'httpd' }
   let(:params) {{
     'accept' => '987',
     'client' => true,
     'connect' => 'localhost:789',
   }}
   it { should contain_file('/etc/stunnel/conf.d/httpd.conf').with_content(/\s+client=yes$/) }
   it { should contain_file('/etc/stunnel/conf.d/httpd.conf').without_content(/^\s+cert = /) }
 end
end
