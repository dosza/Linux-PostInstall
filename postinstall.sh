#!/bin/bash -x
# Autor: Daniel Oliveira Souza
# Descrição: Faz a configuração de pós instalação do linux mint (ubuntu ou outro variante da família debian"
# Versão: 0.2.0
#--------------------------------------------------------Variaveis --------------------------------------------------
if [ -e "$PWD/common-shell.sh" ]; then
	source "$PWD/common-shell.sh"
elif [ -e "$(dirname $0)/common-shell.sh" ]; then
	source "$(dirname $0)/common-shell.sh" 
fi


echo "${AZUL}ARGS=$*${NORMAL}"
FLAG=$#
VERSION="Linux Post Install to EndUser v0.2.1"
APT_LIST="/etc/apt/sources.list"
APT_MODIFICATIONS=""
LINUX_MODICATIONS=""
FLAG_APT='0'
FLAG_OP=''
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



NETFLIX_DESKTOP=(
	"[Desktop Entry]"
	"Name=Netflix"
	"Exec=/opt/google/chrome/chrome --app=\"https://netflix.com\""
	"Comment=Asista a Netflix!"
	"Icon=netflix-desktop"
	"Terminal=false"
	"Type=Application"
	"Categories=Network;WebBrowser;"
	"StartupWMClass=netflix.com"
)

#
installVirtualbox(){

	AptInstall $VIRTUALBOX_VERSION 
	local vbox_ext_str=($(dpkg -l ${VIRTUALBOX_VERSION} | grep virtualbox))
	local vbox_ext_pack_version=${vbox_ext_str[2]}
	local vbox_ext_pack_version=${vbox_ext_pack_version%\-*} #expansão remove caractere traço e tudo que vier a frente dele
	local vbox_ext_pack_url="https://download.virtualbox.org/virtualbox/${vbox_ext_pack_version}/Oracle_VM_VirtualBox_Extension_Pack-${vbox_ext_pack_version}.vbox-extpack"	
	Wget "${vbox_ext_pack_url}"

	usuarios=($( grep 100 /etc/group | cut -d: -f1))
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
	Wget "`echo $_4kvideodownload_url`" # | sed 's|https:|http:|g'`"
	dpkg -i $_4kvideodownload_deb
	apt-get -f install -y 
	rm $_4kvideodownload_deb

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
	)

	if [ $# = 3 ]; then
		dist_old_stable_version=$3
		local vbox_deb_src="deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian ${dist_old_stable_version} contrib"
	fi

	local mirrors=(
		'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' 
		'deb https://download.sublimetext.com/ apt/stable/' 
		'deb http://www.geogebra.net/linux/ stable main'
		"$vbox_deb_src"	
	)

	local apt_key_url_repository=(
		"https://download.sublimetext.com/sublimehq-pub.gpg"
		"https://dl-ssl.google.com/linux/linux_signing_key.pub"
		"https://static.geogebra.org/linux/office@geogebra.org.gpg.key"
		"https://www.virtualbox.org/download/oracle_vbox_2016.asc"
		"https://www.virtualbox.org/download/oracle_vbox.asc"
	)

		for ((i = 0 ; i < ${#repositorys[@]} ; i++))
		do
			echo "### THIS FILE IS AUTOMATICALLY CONFIGURED" > ${repositorys[i]}
			echo "###ou may comment out this entry, but any other modifications may be lost." >> ${repositorys[i]}
			echo ${mirrors[i]} >> ${repositorys[i]}
		done

		echo "Adicionando apt keys ..."
		for((i=0;i<${#apt_key_url_repository[@]};i++))
		do
			wget -qO - "${apt_key_url_repository[i]}" | apt-key add -
			if [ $? != 0 ] ; then 
				wget -qO - "${apt_key_url_repository[i]}" | apt-key add -
			fi
		done

}
basicInstall(){
	echo "sua string de instalação é:" $PROGRAM_INSTALL
	echo "Este script irá configurar seu computador para o uso"
	echo $VERSION	
	IsFileBusy apt ${APT_LOCKS[*]}
	#lista os programas e suas versões
	apt-get update
	#baixa e instala as atualizações
	apt-get dist-upgrade  -y --allow-unauthenticated 
	FLAG_OP=$FLAG_OP$?
	#instal os programas listados pela variavel PROGRAM_INSTALL
	apt-get install $PROGRAM_INSTALL -y --allow-unauthenticated 
	FLAG_OP=$FLAG_OP$?
	apt-get install $LINUX_MODIFICATIONS -y --allow-unauthenticated 
	FLAG_OP=$FLAG_OP$?
	apt-get install $APT_MODIFICATIONS -y --allow-unauthenticated 
	FLAG_OP=$FLAG_OP$?


	apt-get install $WEB_BROWSER -y --allow-unauthenticated 
	FLAG_OP=$FLAG_OP$?
	#instala as dependencias 
	apt-get install -f -y --allow-unauthenticated 
	FLAG_OP=$FLAG_OP$?
	#remove programas que eu acho desnecessários, listados pela variavel $programa_remove  
	apt-get remove $program_remove -y
	FLAG_OP=$FLAG_OP$?
	#remove dependencias dos programas removidos
	apt-get autoremove -y --allow-unauthenticated 
	#limpa o cache do apt se todas operações de instalação foram concluidas com sucesso
	if [ "$FLAG_OP" = "0000000" ]; then
		echo 'Limpando o cache do APT...'
		apt-get clean 
	fi
	install4KVideoDownloader
}

#verifica se o usuário tem poderes administrativos	
if [ "$UID" = "0" ]; then
	
	# decide se arquitetura 
	LINUX_VERSION=$(cat /etc/issue.net);
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
	        *"Linux Mint"* )
				MakeSourcesListD "focal" 1
				#executa configurações específicas para o linux mint 
			    LINUX_MODICATIONS=" android-tools-adb openjdk-8-jdk  oxygen-icon-theme-complete  libreoffice-style-breeze libreoffice libreoffice-writer libreoffice-calc libreoffice-impress "

			;;
	        *"LMDE"*)
				
				#excuta configurações específicas para LInux Mint Debian 
	            LINUX_MODICATIONS=" android-tools-adb oxygen-icon-theme-complete "
	            APT_MODIFICATIONS=" -t jessie-backports libreoffice-style-breeze libreoffice libreoffice-writer libreoffice-calc libreoffice-impress openjdk-8-jre "

			    MakeSourcesListD "stretch" 0
	        ;;
            *"Deepin"*)
                case "$LINUX_VERSION" in 
                    *"2019"*)
                        	DEBIAN_VERSION="buster"
						UBUNTU_COMPATIBLE="bionic"
						DEBIAN_OLD_STABLE_VERSION="stretch"
						MakeSourcesListD $DEBIAN_VERSION 0
				APT_MODIFICATIONS="libreoffice libreoffice-style-breeze libreoffice-writer libreoffice-calc libreoffice-impress "
                        
				LINUX_MODIFICATIONS="onboard openjdk-8-jdk  gnome-packagekit libreoffice-l10n-pt-br myspell-pt-br epub-utils	 kinit kio kio-extras kded5"

				searchLineinFile "/etc/sysctl.d/99-sysctl.conf" "kernel.dmesg_restrict=0"
				echo 'kernel.dmesg_restrict=0' | tee -a /etc/sysctl.d/99-sysctl.conf

				apt_source_list_extra=(
						"deb http://security.debian.org/ buster/updates main contrib non-free"
						"deb-src http://security.debian.org/ buster/updates main contrib non-free"
						"deb http://security.debian.org/ stretch/updates main contrib non-free"
						"deb-src http://security.debian.org/ stretch/updates main contrib non-free"
						"deb http://ftp.br.debian.org/debian/ buster-updates main contrib non-free"
				)                  	
                
                WriterFileln "/etc/apt/sources.list.d/debian.list" apt_source_list_extra
                	;;
                esac

            ;;
			*"Debian"* )
				#COnfigurações específicas para debian
				#gerando o sources.list 

				DEBIAN_VERSION=""
				UBUNTU_COMPATIBLE=""
				case "$LINUX_VERSION" in 
					*"9."*)
						echo "Debian/GNU Linux 9 is no longer supported"
						exit 1;
					;;
					*"10"*)
						DEBIAN_VERSION="buster"
						UBUNTU_COMPATIBLE="bionic"
						DEBIAN_OLD_STABLE_VERSION="stretch"
						MakeSourcesListD $DEBIAN_VERSION 0
                          
				LINUX_MODIFICATIONS="onboard openjdk-11-jre  gnome-packagekit libreoffice-l10n-pt-br myspell-pt-br epub-utils	 kinit kio kio-extras kded5"
					;;
				esac
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
					"deb http://ftp.br.debian.org/debian/ $DEBIAN_VERSION main contrib non-free"  
					"deb-src http://ftp.br.debian.org/debian/ $DEBIAN_VERSION main contrib non-free"  
					""  
					"deb http://security.debian.org/ $DEBIAN_VERSION/updates main contrib non-free"  
					"deb-src http://security.debian.org/ $DEBIAN_VERSION/updates main contrib non-free"  
					""  
					"# $DEBIAN_VERSION-updates, previously known as 'volatile'"  
					"deb http://ftp.br.debian.org/debian/ $DEBIAN_VERSION-updates main contrib non-free"  
					"deb-src http://ftp.us.debian.org/debian/ $DEBIAN_VERSION-updates main contrib non-free"  
					""  
					"#Adiciona fontes extras ao debian"  
					"# debian backports"  
					"deb http://ftp.debian.org/debian $DEBIAN_VERSION-backports main contrib non-free" 
					"deb-src http://ftp.debian.org/debian $DEBIAN_VERSION-backports main contrib non-free" 
					"#Adiciona suporte ao wine"
					"deb https://dl.winehq.org/wine-builds/debian/ $DEBIAN_VERSION main"
				)

				for((i=0;i<${#SOURCES_LIST_OFICIAL_STR[*]};i++))
				do
					if [ $i = 0 ]; then 
						echo "reescrevendo debian sources.list"
						echo "${SOURCES_LIST_OFICIAL_STR[i]}" > /etc/apt/sources.list
					else
						echo "${SOURCES_LIST_OFICIAL_STR[i]}" >> /etc/apt/sources.list
					fi
				done


				if [ -e /etc/apt/sources.list.d/webupd8team-java.list ]; then
					rm  /etc/apt/sources.list.d/webupd8team-java.list
				fi
				#procura no arquivo a linha de configuração
				searchLineinFile $LIGHTDM_GREETER_CONFIG_PATH ${LIGHTDM_GREETER_CONFIG[12]}
				
				#verifica-se o arquivo não está configurado
				if [ $? = 0 ]; then
					#escreva a configuração no arquivo!
					for ((i=0;i<${#LIGHTDM_GREETER_CONFIG[*]};i++))
					do
						echo "${LIGHTDM_GREETER_CONFIG[i]}" >> $LIGHTDM_GREETER_CONFIG_PATH
					done
				else
					echo "lightdm está configurado!"
				fi

				apt-key adv --keyserver keyserver.ubuntu.com:80 --recv-keys EEA14886 
				wget -q -O - https://dl.winehq.org/wine-builds/winehq.key  | apt-key add -

				LINUX_MODIFICATIONS="onboard openjdk-11-jre  gnome-packagekit libreoffice-l10n-pt-br myspell-pt-br epub-utils	 kinit kio kio-extras kded5"
				APT_MODIFICATIONS="-t ${DEBIAN_VERSION}-backports   "
				APT_MODIFICATIONS=$APT_MODIFICATIONS"libreoffice libreoffice-style-breeze libreoffice-writer libreoffice-calc libreoffice-impress"

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

