#!/usr/bin/env bash
set -e

function msg(){
    tput setaf 3
    echo "===> "$1
    tput sgr0
}


msg "Executando setup do tomcasapp"

tomcasthome="/opt/duxus/tomcastapp"

if [ ! -d "$tomcasthome" ]; then
    mkdir -p "$tomcasthome"
fi


cd $tomcasthome

msg "Verificando última versão..."

url="http://10.1.4.6/tomcast/download.php"
filename=`wget --server-response --spider "$url" 2>&1 | grep filename | sed "s/^.*filename=\"\([^\"]\+\)\"/\1/g"`

msg "Download da app [$filename]"


wget "$url" -O $filename

msg "Descompactando arquivo"

tar -xjf $filename

rm -f $filename

msg "Instalando dependências via YUM"

#desabilita erro trap
set +e
which ruby > /dev/nul
rubyok=$?
set -e
if [ $rubyok -ne 0 ]; then
    msg "Instalando ruby"
    yum -y install ruby 
else
    msg "Verificando ruby ... ok"
fi

#desabilita erro trap
set +e
which gem > /dev/null
gemok=$?
set -e
if [ $gemok -ne 0 ]; then
    msg "Instalando rubygems"
    yum -y install rubygems
else
    msg "Verificando gem ... ok"
fi

set +e
gtkgem=`gem list | grep gtk2`
jsongem=`gem list | grep json`
set -e

if [ ! "$gtkgem" ]; then
    msg "Instalando GTK 2"  
    yum -y install gcc ruby-devel gtk+ gtk2-devel glib2-devel atk-devel pango-devel gdk-pixbuf2-devel.x86_64 
    gem install gtk2
else
    msg "GTK 2 Instalado: $gtkgem"
fi

if [ ! "$jsongem" ]; then
    msg "Instalando JSON"
    gem install json
else
    msg "JSON Instalado: $jsongem"
fi

msg "Concluindo a instalação"

if [ ! -e /usr/local/bin/tomcastapp ]; then
    ln -s "$tomcasthome/tomcastapp" /usr/local/bin
    ln -s "$tomcasthome/tomcast-notify" /usr/local/bin
fi

msg "Instalação concluída"
