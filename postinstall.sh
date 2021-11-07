#!/bin/bash -x
# Autor: Daniel Oliveira Souza
# Descrição: Faz a configuração de pós instalação do linux mint (ubuntu ou outro variante da família debian"
# Versão: 0.2.3
#--------------------------------------------------------Variaveis --------------------------------------------------
if [ -e "$PWD/common-shell.sh" ]; then
	source "$PWD/common-shell.sh"
elif [ -e "$(dirname $0)/common-shell.sh" ]; then
	source "$(dirname $0)/common-shell.sh" 
fi


POSTINSTALL_VERSION='0.2.3'
FLAG=$#
VERSION="Linux Post Install to EndUser v${POSTINSTALL_VERSION}"
APT_LIST="/etc/apt/sources.list"
APT_MODIFICATIONS=""
LINUX_MODIFICATIONS=""
WEB_BROWSER="google-chrome-stable"
FLAG_WEB_BROWSER=0
ARQUITETURA=$(arch)
PROGRAM_INSTALL=""
LINUX_VERSION=$(cat /etc/issue.net);
VIRTUALBOX_VERSION='virtualbox-6.1'
GAMES="supertux extremetuxracer gweled gnome-mahjongg "
MTP_SPP="libmtp-common mtp-tools libmtp-dev libmtp-runtime libmtp9 "
SDL_LIBS="libsdl-ttf2.0-dev libsdl-sound1.2 libsdl-gfx1.2-dev libsdl-mixer1.2-dev libsdl-image1.2-dev "
DEV_TOOLS="g++ mesa-utils sublime-text android-tools-fastboot android-tools-adb "
MULTIMEDIA="vlc language-pack-kde-pt kolourpaint4 gimp gimp-data-extras krita winff audacity  "
NON_FREE="exfat-utils  exfat-fuse  rar unrar p7zip-full p7zip-rar ttf-mscorefonts-installer "
SYSTEM=" gparted dnsmasq-base bleachbit  apt-transport-https "
EDUCATION="geogebra5 "
ARGV=($*)
#
installVirtualbox(){

	AptInstall $VIRTUALBOX_VERSION 
	local vbox_ext_str=($(dpkg -l ${VIRTUALBOX_VERSION} | grep virtualbox))
	local vbox_ext_pack_version=${vbox_ext_str[2]}
	local vbox_ext_pack_version=${vbox_ext_pack_version%\-*} #expansão remove caractere traço e tudo que vier a frente dele
	local vbox_ext_pack_url="https://download.virtualbox.org/virtualbox/${vbox_ext_pack_version}/Oracle_VM_VirtualBox_Extension_Pack-${vbox_ext_pack_version}.vbox-extpack"	
	Wget "${vbox_ext_pack_url}"

	usuarios=($( grep 100 /etc/group | cut -d: -f1))
	unset usuarios[0];
	for i in ${!usuarios[*]}; do
		adduser ${usuarios[i]} vboxusers #adiciona o usuário ao grupo vboxusers
	done
	
	
	if [ -e "Oracle_VM_VirtualBox_Extension_Pack-${vbox_ext_pack_version}.vbox-extpack" ]; then
		echo "y" | VBoxManage extpack install --replace "Oracle_VM_VirtualBox_Extension_Pack-${vbox_ext_pack_version}.vbox-extpack"
		rm "Oracle_VM_VirtualBox_Extension_Pack-${vbox_ext_pack_version}.vbox-extpack"
	else 
		echo "Não foi possível obter o virtualbox :(  Tente mais tarde!"
		exit 1
	fi
}

#Esta função simplifica o download do 4kvideodownlaoder
install4KVideoDownloader(){
	local product_videodownloader='https://www.4kdownload.com/pt-br/products/product-videodownloader'
	local _4kvideodownload_url=$( wget -qO-  $product_videodownloader | grep amd64.deb | sed '/^\s*ubuntu:/d;s/\s*\"downloadUrl\"\s://g;s/^\s"//g;s/?source=website",$//g')
	local _4kvideodownload_deb=$(echo $_4kvideodownload_url | awk -F'/' '{print $NF}') # filtra a string para remover a parte da url. \/ escape para /
	local current_version_4k_videodownloader="$(getDebPackVersion 4kvideodownloader)"
	if [ $? != 0 ] || [ $? = 0 ] && ( ! echo $_4kvideodownload_deb | grep "$current_version_4k_videodownloader") ; then 
		echo "$_4kvideodownload_deb" | grep "$current_version_4k_videodownloader"
		Wget "`echo $_4kvideodownload_url`" # | sed 's|https:|http:|g'`"
		dpkg -i $_4kvideodownload_deb
		apt-get -f install -y 
		rm $_4kvideodownload_deb
	fi

}

MakeSourcesListD(){
	local dist_version=$1
	local flag_debian=$2
	local vbox_deb_src="deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian ${dist_version} contrib"
	local repositorys=(
		'/etc/apt/sources.list.d/google-chrome.list'
		'/etc/apt/sources.list.d/sublime-text.list' 
		'/etc/apt/sources.list.d/geogebra.list'
		'/etc/apt/sources.list.d/virtualbox.list'
		'/etc/apt/sources.list.d/teams.list'
	)

	local mirrors=(
		'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' 
		'deb https://download.sublimetext.com/ apt/stable/' 
		'deb http://www.geogebra.net/linux/ stable main'
		"$vbox_deb_src"	
		"deb [arch=amd64] https://packages.microsoft.com/repos/ms-teams stable main"
	)

	local apt_key_url_repository=(
		"https://download.sublimetext.com/sublimehq-pub.gpg"
		"https://dl-ssl.google.com/linux/linux_signing_key.pub"
		"https://static.geogebra.org/linux/office@geogebra.org.gpg.key"
		"https://www.virtualbox.org/download/oracle_vbox_2016.asc"
		"https://www.virtualbox.org/download/oracle_vbox.asc"
		"https://packages.microsoft.com/keys/microsoft.asc"
	)
	ConfigureSourcesList apt_key_url_repository mirrors repositorys
}

basicInstall(){
	echo "sua string de instalação é:" $PROGRAM_INSTALL
	echo "Este script irá configurar seu computador para o uso"
	AptDistUpgrade
	AptInstall $PROGRAM_INSTALL; 
	AptInstall $LINUX_MODIFICATIONS;
	
	[ "$APT_MODIFICATIONS" != "" ] && 
		AptInstall $APT_MODIFICATIONS;
	AptInstall $WEB_BROWSER;
	AptRemove $program_remove
	install4KVideoDownloader
	AptInstall -f
}

#verifica se o usuário tem poderes administrativos	
if [ "$UID" = "0" ]; then
	
	# decide se arquitetura 
	LINUX_VERSION=$(cat /etc/issue.net);
	LINUX_RELEASE="`cat /etc/issue.net | sed 's/[a-Z]*[[:blank:]]*//g'`"

	case "$ARQUITETURA" in 
		"amd64" | "x86_64" )
			FLAG_WEB_BROWSER=1;
			;;
		*)
			echo "Linux 32 bit is not longer supported"
			exit 1;
		;;
	esac


		#Descobre se o a distribuição do linux você está usando 
		case "$LINUX_VERSION" in
	        *"Linux Mint"*  | *"Ubuntu"* | *"Zorin"*)
				MakeSourcesListD "focal" 1
				#executa configurações específicas para o linux mint 
			    LINUX_MODIFICATIONS=" android-tools-adb openjdk-8-jre  oxygen-icon-theme libreoffice-style-breeze libreoffice libreoffice-writer libreoffice-calc libreoffice-impress "
            ;;

			*"Debian"* )
				#COnfigurações específicas para debian
				#gerando o sources.list 

				DEBIAN_VERSION=""
				UBUNTU_COMPATIBLE=""
				case "$LINUX_RELEASE" in 
					*"10"*)
						DEBIAN_VERSION="buster"
						UBUNTU_COMPATIBLE="bionic"
						MakeSourcesListD $DEBIAN_VERSION 0
					;;
					*"11"*)
						DEBIAN_VERSION="bullseye"
						UBUNTU_COMPATIBLE="focal"
						MakeSourcesListD $DEBIAN_VERSION 0
					;;
				esac
				LINUX_MODIFICATIONS="onboard openjdk-11-jre  gnome-packagekit libreoffice-l10n-pt-br myspell-pt-br epub-utils	 kinit kio kio-extras kded5"
				LIGHTDM_GREETER_CONFIG_PATH="/etc/lightdm/lightdm-gtk-greeter.conf"
				LIGHTDM_GREETER_CONFIG=(
					"[greeter]"
					"#background="
					"#user-background="
					"#theme-name="
					"#icon-theme-name="
					"#font-name="
					"#xft-antialias="
					"#xft-dpi="
					"#xft-hintstyle="
					"#xft-rgba="
					"#indicators="
					"#clock-format="
					"keyboard=onboard"
					"#reader="
					"#position="
					"#screensaver-timeout="
				)
				SOURCES_LIST_OFICIAL_STR=(
					"#Fonte de aplicativos apt"  
					"deb http://ftp.br.debian.org/debian/ ${DEBIAN_VERSION} main contrib non-free"  
					"deb-src http://ftp.br.debian.org/debian/ $DEBIAN_VERSION main contrib non-free"  
					""  
					"deb http://security.debian.org/ ${DEBIAN_VERSION}/updates main contrib non-free"  
					"deb-src http://security.debian.org/ ${DEBIAN_VERSION}/updates main contrib non-free"  
					""  
					"# $DEBIAN_VERSION-updates, previously known as 'volatile'"  
					"deb http://ftp.br.debian.org/debian/ ${DEBIAN_VERSION}-updates main contrib non-free"  
					"deb-src http://ftp.us.debian.org/debian/ ${DEBIAN_VERSION}-updates main contrib non-free"  
					""  
					"#Adiciona fontes extras ao debian"  
					"# debian backports"  
					"deb http://ftp.debian.org/debian ${DEBIAN_VERSION}-backports main contrib non-free" 
					"deb-src http://ftp.debian.org/debian ${DEBIAN_VERSION}-backports main contrib non-free" 
					"#Adiciona suporte ao wine"
					"deb https://dl.winehq.org/wine-builds/debian/ ${DEBIAN_VERSION} main"
				)

				echo "Reescrevendo /etc/apt/sources.list ..."
				WriterFileln /etc/apt/sources.list SOURCES_LIST_OFICIAL_STR

				[ -e /etc/apt/sources.list.d/webupd8team-java.list ] &&
					rm  /etc/apt/sources.list.d/webupd8team-java.list
			
				#procura no arquivo a linha de configuração
				searchLineinFile $LIGHTDM_GREETER_CONFIG_PATH ${LIGHTDM_GREETER_CONFIG[12]}
				
				#verifica-se o arquivo não está configurado
				if [ $? = 0 ]; then
					#escreva a configuração no arquivo!
					AppendFileln $LIGHTDM_GREETER_CONFIG_PATH LIGHTDM_GREETER_CONFIG
				else
					echo "lightdm está configurado!"
				fi

				apt-key adv --keyserver keyserver.ubuntu.com:80 --recv-keys EEA14886 
				wget -q -O - https://dl.winehq.org/wine-builds/winehq.key  | apt-key add -

				LINUX_MODIFICATIONS="onboard openjdk-11-jre  gnome-packagekit libreoffice-l10n-pt-br myspell-pt-br epub-utils	 kinit kio kio-extras kded5"
				APT_MODIFICATIONS="-t ${DEBIAN_VERSION}-backports   "
				APT_MODIFICATIONS=$APT_MODIFICATIONS"libreoffice libreoffice-style-breeze libreoffice-writer libreoffice-calc libreoffice-impress"

				searchLineinFile "/etc/sysctl.d/99-sysctl.conf" "kernel.dmesg_restrict=0"
				echo 'kernel.dmesg_restrict=0' | tee -a /etc/sysctl.d/99-sysctl.conf

				;;
				*"Ubuntu"*)
					LINUX_MODIFICATIONS=" adb openjdk-8-jre  libreoffice-style-breeze libreoffice libreoffice-writer libreoffice-calc libreoffice-impress "

	        ;;
		esac




	#Altera o proprietário todos os arquivos e diretório dos usuários
	
	# Armazaena uma lista de usuarios cadastrados no computador 
	#usuarios=($(cat /etc/group | grep 100 | cut -d: -f1))
	#for((i=1 ;i<${#usuarios[@]} ;i++))
	#do
		#usuario_i=${usuarios[i]}
		# Se existe o diretório do 
		# if [ -e /home/$usuario_i ]
		# 	then
		# 	chown $usuario_i:$usuario_i  -R /home/$usuario_i
		# fi
	#done

	getCurrentDebianFrontend
	if [ $# = 0 ]; then
		PROGRAM_INSTALL=${MTP_SPP}${SDL_LIBS}${MULTIMEDIA}${SYSTEM}
	else
		PROGRAM_INSTALL=$PROGRAM_INSTALL$NON_FREE$SYSTEM
		for((i=0;i<$#;i++))
		do
			echo ${ARGV[i]}
			case  "${ARGV[i]}" in
				"--i-games")
					PROGRAM_INSTALL=$PROGRAM_INSTALL$GAMES
					;;
				"--i-mtp_spp")
					PROGRAM_INSTALL=$PROGRAM_INSTALL$MTP_SPP
					;;
				"--i-sdl_libs")
					PROGRAM_INSTALL=$PROGRAM_INSTALL$SDL_LIBS
					;;
				"--i-multimedia")
					PROGRAM_INSTALL=$PROGRAM_INSTALL$MULTIMEDIA
				;;
				"--i-education")
					PROGRAM_INSTALL=$PROGRAM_INSTALL$EDUCATION
				;;
				"--i-virtualbox")
					installVirtualbox
					exit 0;
				;;
				"--i-dev")
					PROGRAM_INSTALL=$PROGRAM_INSTALL${DEV_TOOLS}
				;;
			esac
		done
	fi
		basicInstall
	else
		#O comando printf é usado para fazer imprimir mensagem formatada funciona de maneira semelhante ao printf da
		#linguagem C
		printf "Sinto muito, você não tem permissões administrativas para executar este script!\n
		\rTente novamente executando este comando:\nsudo postinstall.sh\n"
		#exit 1
		echo "Pressione qualquer tecla para encerrar..."
		sleep 10
		exit 1 
	fi

