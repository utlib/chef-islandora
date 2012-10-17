#
# Cookbook Name:: islandora12
# Recipe:: default
#
# Copyright 2012, UTL
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
#

include_recipe "ark"
apache_module "proxy_http"


#Various packages required for islandora
include_recipe "apt::medibuntu"
include_recipe "php::module_curl"
include_recipe "php::module_soap"
include_recipe "php::module_xsl-xml"
package "imagemagick"
include_recipe "php::module_imagick"
package "lame"
package "tesseract-ocr"
package "libimage-exiftool-perl"
package "ffmpeg"
package "libtheora0"
package "libvorbis0a"
package "libogg0"
package "libavcodec-extra-53"
package "ffmpeg2theora"


### start installing islandora 12.2 here
### get the drupal filter
ark 'drupal_filter' do
  version "3.4.2"
  url "http://#{node['repo_server']}/islandora/drupal_filter.tar.gz"
  creates 'fcrepo-drupalauthfilter-3.4.2.jar'
  path "#{node['tomcat']['webapp_dir']}/fedora/WEB-INF/lib"
  checksum 'd4bf57a152382a6ba784125f789122b89fef7d0a1764a3dca54928df48656db4'
  action :cherry_pick
  notifies :restart, resources(:service => "tomcat")
  owner "#{node['tomcat']['user']}"
  group "#{node['tomcat']['user']}"
  mode 0644
end

### set Drupal auth type in jaas.conf (assumes FESL)
template "#{node['fedora']['root']}/server/config/jaas.conf" do
  source "jaas.conf.erb"
  owner "#{node['tomcat']['user']}"
  group "root"
  mode 0644
  notifies :restart, resources(:service => "tomcat")
end

###template filter-drupal.xml
template "#{node['fedora']['root']}/server/config/filter-drupal.xml" do
  source "filter-drupal.xml.erb"
  owner "#{node['tomcat']['user']}"
  group "root"
  mode 0644
  notifies :restart, resources(:service => "tomcat"), :immediately
end

### Prepare various dependencies prior to installing Islandora
###jquery ui library (required for jquery_ui module)
directory "#{node['drupal']['dir']}/sites/all/libraries" do
  owner "#{node['apache']['user']}"
  group "#{node['apache']['group']}"
  mode "0755"
  recursive true
  action :create
end

## not downloadable via drush
ark 'jquery.ui' do
  version '1.7.3'
  url "http://jquery-ui.googlecode.com/files/jquery-ui-1.7.3.zip"
  path "#{node['drupal']['dir']}/sites/all/libraries"
  checksum  '9c8b2a74bc9936ae92dd65aa763b1437b5eea39383c51c38346ce5cff06ef52c'
  owner "#{node['apache']['user']}"
  group "#{node['apache']['group']}"
  action :put
end

drupal_module "jquery_ui" do
  dir node['drupal']['dir']
end

drupal_module "swftools-6.x-3.0-beta5" do
  dir node['drupal']['dir']
end

drupal_module "SWFObject2" do
  dir node['drupal']['dir']
end

drupal_module "swftools_jw5" do
  dir node['drupal']['dir']
end

drupal_module "imageapi_gd" do
  dir node['drupal']['dir']
end

drupal_module "imageapi_imagemagick" do
  dir node['drupal']['dir']
end

### Put media player in place
ark 'mediaplayer' do
  version '5.10'
  url "http://#{node['repo_server']}/jwplayer/mediaplayer.zip"
  path "#{node['drupal']['dir']}/sites/all/libraries"
  checksum  '9c8b2a74bc9936ae92dd65aa763b1437b5eea39383c51c38346ce5cff06ef52c'
  owner "#{node['apache']['user']}"
  group "#{node['apache']['group']}"
  action :put
end

# create link for mediaplayer4 for Islandora
link "#{node['drupal']['dir']}/sites/all/modules/mediaplayer4" do
  to "#{node['drupal']['dir']}/sites/all/libraries/mediaplayer"
end

### Islandora Image viewer:
ark 'iiv' do
  version "6.x-12.2.0"
  url "http://islandora.ca/sites/islandora.ca/files/12.2.0/iiv-6.x-12.2.0.tar.gz"
  creates 'iiv.war'
  path "#{node['tomcat']['webapp_dir']}/"
  checksum 'd993f952e8b9da4e566cb3d2c328829eb6d6c60fb39eba5c3790b63b74d656a6'
  action :cherry_pick
  notifies :restart, resources(:service => "tomcat")
  owner "#{node['tomcat']['user']}"
  group "#{node['tomcat']['user']}"
  mode 0644
end

### Install the Islandora modules themselves
### to do: get checksums (redo array)
node['islandora']['modules'].each do |island_module, version|
  module_name = island_module.sub( "-6.x", "" ) ### remove '-6.x' from the name of some modules, but required for download
  ark module_name do
    version "#{version}"
    url "http://islandora.ca/sites/islandora.ca/files/#{version}/#{island_module}-#{version}.tar.gz"
    path "#{node['drupal']['dir']}/sites/all/modules"
    prefix_root "#{node['drupal']['dir']}/sites/all/modules"
    prefix_home "#{node['drupal']['dir']}/sites/all/modules"
    owner "#{node['apache']['user']}"
    group "#{node['apache']['group']}"
    action :put
  end
end

###unfortunately we have to wait here for modules to populate database changes to MySQL. This part needs improvement
execute "wait_for_db" do
  command "sleep 10"
  action :run
end

### enable the modules
node['islandora']['module_real_names'].each do |real_name|
  drupal_module "#{real_name}" do
    dir node['drupal']['dir']
    action :enable
  end
end

#node['islandora']['module_real_names'] do |real_name|
#drupal_module "#{node['islandora']['module_real_names']}" do
#  dir node['drupal']['dir']
#  action :enable
#end
#end

## update the database & clear cache
drupal_updatedb do
  dir node['drupal']['dir']
  action :update
end
