#
# Cookbook Name:: railo334
# Recipe:: express
#
# Copyright 2012, Nathan Mische
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Download Railo Express (http://www.getrailo.org/index.cfm/download/)
remote_file "#{Chef::Config['file_cache_path']}/railo-3.3.4.003-railo-express-with-jre-linux.tar.gz" do
  source "http://www.getrailo.org/railo/remote/download/3.3.4.003/railix/linux/railo-3.3.4.003-railo-express-with-jre-linux.tar.gz"
  action :create_if_missing
  mode "0744"
  owner "root"
  group "root"
end

# Extract the installer
execute "untar_installer" do
  command "tar -xvzf #{Chef::Config['file_cache_path']}/railo-3.3.4.003-railo-express-with-jre-linux.tar.gz"
  creates "#{Chef::Config['file_cache_path']}/railo-3.3.4.003-railo-express-with-jre-linux"
  action :run
  user "root"
  cwd "#{Chef::Config['file_cache_path']}"
end

# Move the installation
execute "install" do
  command "mv #{Chef::Config['file_cache_path']}/railo-3.3.4.003-railo-express-with-jre-linux #{node['railo334']['install_path']}"
  creates "#{node['railo334']['install_path']}"
  action :run
  user "root"
  cwd "#{Chef::Config['file_cache_path']}"
end

# Update the init script
template "#{node['railo334']['install_path']}/bin/jetty.sh" do
  source "jetty.sh.erb"
  mode "0777"
  owner "root"
  group "root"
end

# Link the init script
link "/etc/init.d/jetty" do
  to "#{node['railo334']['install_path']}/bin/jetty.sh"
end

# Set up Jetty as a service
service "jetty" do
  start_command "/etc/init.d/jetty start"
  stop_command "/etc/init.d/jetty stop"
  restart_command "/etc/init.d/jetty restart"
  supports :status => false, :restart => true, :reload => false
  action [ :enable, :start ]
end

# Create the webroot if it doesn't exist
directory "#{node['railo334']['install_path']}#{node['railo334']['webroot']}" do
  owner "vagrant"
  group "vagrant"
  mode "0755"
  action :create
  not_if { File.directory?("#{node['railo334']['install_path']}#{node['railo334']['webroot']}") }
end

# Point Railo to custom webroot 
template "#{node['railo334']['install_path']}/contexts/railo.xml" do
  source "railo.xml.erb"
  mode "0777"
  owner "root"
  group "root"
  notifies :restart, "service[jetty]", :delayed
end
