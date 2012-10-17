#
# Cookbook Name:: islandora
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

## install pieces for Islandora
# 1. GSearch

package "lame"
#package "tesseract-ocr"
package "libimage-exiftool-perl"
package "imagemagick"
package "ffmpeg"
package "libavcodec-extra-53"
package "ffmpeg2theora"
package "autoconf"
package "automake"
package "libtool"
package "libpng12-dev"
package "libjpeg62-dev"
package "libtiff4-dev"
package "zlib1g-dev"

  node.normal[:islandora][:gsearch_installed] = true
  node.save


#if node[:islandora][:gsearch_installed] == false
#  script "install_gsearch" do
#    interpreter "bash"
#   user "root"
#   cwd "#{Chef::Config[:file_cache_path]}"
#   code <<-EOH
#    wget http://iweb.dl.sourceforge.net/project/fedora-commons/services/3.1/genericsearch-2.2.zip
#    unzip genericsearch-2.2.zip
#    cp -f genericsearch-2.2/fedoragsearch.war #{node[:tomcat][:webapp_dir]}/
#    service tomcat6 restart
#    sleep 3
#    mv -f #{node[:tomcat][:webapp_dir]}/fedoragsearch/WEB-INF/classes/configDemoOnSolr #{node[:tomcat][:webapp_dir]}/fedoragsearch/WEB-INF/classes/config
#    EOH
#  end
#  node.normal[:islandora][:gsearch_installed] = true
#  node.save
#end

##Then a bunch of manual gsearch configuration that could be scripted:
# See https://wiki.duraspace.org/pages/viewpage.action?pageId=30212884

# must get djakota here
# and make its link:
# ln -s /opt/adore-djatoka-1.1
link "/opt/adore-djatoka" do
  to "/opt/adore-djatoka-1.1"
end





