#!/bin/bash
# Autor: Daniel Oliveira Souza
# Descrição: Faz a configuração de pós instalação do linux mint (ubuntu ou outro variante da família debian"
# Versão: 0.3.0
#--------------------------------------------------------Variaveis --------------------------------------------------
source /etc/os-release

if [ -e "$PWD/common-shell.sh" ]; then
	MODULES_PATH=$PWD
elif [ -e "$(dirname $0)/common-shell.sh" ]; then
	MODULES_PATH="$(dirname $0)"
fi

source "$MODULES_PATH/common-shell.sh"
declare  -r DEBIAN_SUPPORT_FIRMWARE_REPO=12

JAVA_LTS_VERSION=(21 17 11)
POSTINSTALL_VERSION='0.3.0'
APT_LIST="/etc/apt/sources.list"
APT_MODIFICATIONS=""
LINUX_MODIFICATIONS=""
WEB_BROWSER="google-chrome-stable"
FLAG_WEB_BROWSER=0
PROCESSOR_ARCH=$(arch)
PROGRAM_INSTALL=""
ORACLE_REPO_VIRTUALBOX_VERSION=(7.0 6.1)
GAMES="gweled gnome-mahjongg "
MTP_SPP="libmtp-common mtp-tools libmtp-dev libmtp-runtime libmtp9 "
SDL_LIBS="libsdl-ttf2.0-dev libsdl-sound1.2 libsdl-gfx1.2-dev libsdl-mixer1.2-dev libsdl-image1.2-dev "
DEV_TOOLS="g++ mesa-utils "
ANDROID_DEV_TOOLS="android-tools-fastboot android-tools-adb"

declare -A TEXT_EDITOR=(
	['sublime']="sublime-text"
	['kate']="kate"
)

MULTIMEDIA="vlc language-pack-kde-pt kolourpaint gimp gimp-data-extras winff "
NON_FREE="rar unrar p7zip-full p7zip-rar ttf-mscorefonts-installer "
SYSTEM=" gparted dnsmasq-base bleachbit  apt-transport-https "

ARGV=($@)

UNSUPPORTED_JAVA_PPA=/etc/apt/sources.list.d/webupd8team-java.list
VIRTUALBOX_VERSION=virtualbox
PROGRAM_REMOVE=('4kvideodownloader')

LIGHT_BLUE=$'\e[1;36m'
ITALIC=$'\e[1;3m'
TEXT_STYLE="${LIGHT_BLUE}${ITALIC}"

#still compatible older installations
#set virtualbox from Oracle repo, if is installed
getCurrentVirtualBoxInstalled(){
	local oracle_deb_pack
	arrayMap ORACLE_REPO_VIRTUALBOX_VERSION version '
		oracle_deb_pack="virtualbox-${version}"
		if CheckPackageDebIsInstalled $oracle_deb_pack ; then 
			VIRTUALBOX_VERSION="$oracle_deb_pack"
			return
		fi'
}
installVirtualbox(){

	getCurrentVirtualBoxInstalled
	AptInstall $VIRTUALBOX_VERSION 

	local vbox_ext_str=($(dpkg -l ${VIRTUALBOX_VERSION} | grep virtualbox))
	local vbox_ext_pack_version=${vbox_ext_str[2]%%\-*}
	local vbox_ext_pack_url="https://download.virtualbox.org/virtualbox/${vbox_ext_pack_version}/Oracle_VM_VirtualBox_Extension_Pack-${vbox_ext_pack_version}.vbox-extpack"	
	local vbox_ext_pack_file=$(basename "$vbox_ext_pack_url")
	
	Wget "${vbox_ext_pack_url}"

	usuarios=($( grep 100 /etc/group | cut -d: -f1))
	unset usuarios[0];
	
	arrayMap usuarios usuario '
		adduser $usuario vboxusers'
	
	if [ -e "${vbox_ext_pack_file}" ]; then
		echo "y" | VBoxManage extpack install --replace "${vbox_ext_pack_file}"
		rm "${vbox_ext_pack_file}"
	else 
		echo "Não foi possível obter o virtualbox :(  Tente mais tarde!"
		exit 1
	fi
}


#função que retorna o status de instalação do 4kvideodownloader
get4kVideoDownloaderStatus(){
	local _4kvideo_status=0
	if [ "$current_version_4k_videodownloader" = "" ] || ( [ "$current_version_4k_videodownloader" != "" ] && 
	! echo $_4kvideodownload_deb | grep $current_version_4k_videodownloader >/dev/null ) ; then 
		_4kvideo_status=1
	fi

	return $_4kvideo_status

}

parse4KUrlVersion(){
	OLDIFS=$IFS 
	IFS='.'
	local _version="${_4kvideodownload_version}"
	local _version_stream=($_version)
	local version_stream_size=${#_version_stream[@]}
	let version_stream_size--
	unset _version_stream[$version_stream_size]
	_4kvideodownload_version="$(
		echo "${_version_stream[@]}" |
		sed 's/ /./g'
	)"	
	IFS=$OLDIFS
}
#função para baixar e instalar o 4kvideodownloader
install4KVideoDownloader(){
	local product_videodownloader='https://www.4kdownload.com/pt-br/products/product-videodownloader'
	local _4kvideodownload_url=$( 
		wget -qO-  $product_videodownloader |
		grep '"fullVersion":'|
		grep "ubuntu_x64" |
		awk -F':' ' { print $2 }'
	)

	local _4kvideodownload_version=$(
		echo "$_4kvideodownload_url" | 
		awk -F'_' ' { print $2 }'		
	)

	_4kvideodownload_url=$(
		echo $_4kvideodownload_url |
		sed 's/"//g'|
		awk -F'_' '{ print $1 }'
	)

	parse4KUrlVersion

	local _4kvideodownload_url="https://dl.4kdownload.com/app/4k${_4kvideodownload_url}_${_4kvideodownload_version}-1_amd64.deb"
	local _4kvideodownload_deb=$(
		echo $_4kvideodownload_url |
		awk -F'/' '{print $NF}'
	)

	local current_version_4k_videodownloader="$(
		getDebPackVersion 4kvideodownloaderplus | 
		sed 's/\-/\./g'
	)"
	
	if ! get4kVideoDownloaderStatus; then 
		Wget "$_4kvideodownload_url"
		dpkg -i $_4kvideodownload_deb
		apt-get -f install -y 
		rm $_4kvideodownload_deb
	fi
	
}

MakeSourcesListD(){
	
	local repositories=(
		'/etc/apt/sources.list.d/google-chrome.list'
		'/etc/apt/sources.list.d/sublime-text.list'  
	)

	local mirrors=(
		'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' 
		'deb https://download.sublimetext.com/ apt/stable/' 
	)

	local apt_key_url_repository=(
		"https://download.sublimetext.com/sublimehq-pub.gpg"
		"https://dl-ssl.google.com/linux/linux_signing_key.pub"
	)

	ConfigureSourcesList apt_key_url_repository mirrors repositories
}


FilterProgramToRemove(){
	local list_packages_to_remove=()
	arrayFilter PROGRAM_REMOVE program list_packages_to_remove '{
		getDebPackVersion "$program" &>/dev/null
	}'

	PROGRAM_REMOVE=("${list_packages_to_remove[@]}")
}

RunAptModifications(){
	[ "$APT_MODIFICATIONS" != "" ] && AptInstall $APT_MODIFICATIONS;
}

basicInstall(){
	applyConfigByDistroLinux
	getCurrentDebianFrontend
	AptDistUpgrade
	AptInstall $COMMON_SHELL_MIN_DEPS $PROGRAM_INSTALL $LINUX_MODIFICATIONS $WEB_BROWSER -f
	RunAptModifications	
	FilterProgramToRemove
	AptRemove "$PROGRAM_REMOVE"
}

DebianExtraActions(){
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

	searchLineinFile $LIGHTDM_GREETER_CONFIG_PATH ${LIGHTDM_GREETER_CONFIG[12]}
	
	#verifica-se o arquivo não está configurado
	if [ $? = 0 ]; then 
		AppendFileln $LIGHTDM_GREETER_CONFIG_PATH LIGHTDM_GREETER_CONFIG
	fi

	searchLineinFile "/etc/sysctl.d/99-sysctl.conf" "kernel.dmesg_restrict=0"
	
	if [ $? = 0 ]; then 
		echo 'kernel.dmesg_restrict=0' | tee -a /etc/sysctl.d/99-sysctl.conf
	fi

	[ -e $UNSUPPORTED_JAVA_PPA ] && rm $UNSUPPORTED_JAVA_PPA
}


setMajorJavaLtsSupported(){
	[ "$1" =  "" ] && return

	local java_type="$1"
	local java_deb
	
	for java_version in "${JAVA_LTS_VERSION[@]}";do
		
		java_deb="openjdk-${java_version}-${java_type}"
		if getDebPackVersion  "$java_deb" &>/dev/null; then
			echo "Selecionando: ${TEXT_STYLE}Java ${java_type^^} $java_version LTS${NORMAL}"
			LINUX_MODIFICATIONS+=" $java_deb"
			return
		fi
	done
}


configureDebianNonFreeFirmwareRepository(){
	local debian_id="${DEBIAN_VERSION//\.*/}"
	local non_free_pattern='(non\-free\-firmware)'
	
	[ $debian_id -lt $DEBIAN_SUPPORT_FIRMWARE_REPO ] && return 

	arrayMap SOURCES_LIST_OFICIAL_STR line index '{
		[[ "$line" =~ $non_free_pattern ]] && continue
		SOURCES_LIST_OFICIAL_STR[$index]="$line non-free-firmware"
	}'
	
}


isYes(){
	read answer
	[ "${answer,,}" = "s" ] || [ "${answer,,}" = "y" ]
}

markSoftwareClassItem(){
	echo -en " ${TEXT_STYLE}$class${NORMAL} ${ITALIC}s/n?${NORMAL} "
	! isYes && return 
	mark_to_install+=("$install_code")
}

runMenu(){
	
	local answer
	local mark_to_install=()
	
	local -A dev_tools_list=(
		['JDK LTS']="--jdk"
		['Ferramentas do Android']='--i-android-dev-tools'
		['Sublime Text']='--i-text=sublime'
		['Kate Text Editor']='--i-text=kate'
		['Suporte SDL']="--i-sdl_libs"
	)

	local -A install_list=(
		['Jogos básicos']="--i-games"
		['Java LTS']="--java"
		['Suporte MTP']="--i-mtp_spp"
		['Multimidia']="--i-multimedia"
		['Virtualbox']='--i-virtualbox'
		['Softwares proprietários e codecs proprietários']='--i-non-free'
		['4K Video Downloader plus']="--u-4k"
	)

	echo "Selecione o grupo de ${TEXT_STYLE}Ferramentas${NORMAL} que deseja instalar"
	arrayMap install_list install_code class 'markSoftwareClassItem'

	echo  -en " ${TEXT_STYLE}Ferramentas de desenvolvedor${NORMAL} ${ITALIC}s/n?${NORMAL} " 
	if isYes; then
		mark_to_install+=("--i-dev")
		arrayMap dev_tools_list install_code class '{
			echo -en "\t"
			markSoftwareClassItem
		}'
	fi


	setSoftwaresToInstall mark_to_install


}

usage(){

	echo "Uso: sudo ./postinstall.sh ${LIGHT_BLUE}--[option]${NORMAL} ou --i-text=${LIGHT_BLUE}[text-option]${NORMAL}
		--help,h 		exibe esta ajuda
		--i-mtp_spp		Instala bibliotecas MTP (Protocolo de transferencia de arquivos Android)
		--i-sdl_libs		Instala bibliotecas SDL (desenvolvedor)
		--i-multimedia		Instala Softwares de multimídia (VLC Player, Winff,Gimp,...)
		--i-games		Instala o jogo gweled Gnome-mahjongg
		--i-dev			Instala compilador C++ e mesa-utils
		--i-non-free		Instala softwares e codecs proprietários
		--i-virtualbox		Instala e configura o Virtuabox
		--i-text=sublime 	Instala o Sublime Text (desenvolvedor)
		--i-text=kate 		Instala o editor Kate (desenvolvedor)
		--i-android-dev-tools	Instala Android Fast Boot e Android ADB
		--u-4k			Instala/atualiza somente o 4kvideodownloaderplus
		--java			Instala Java LTS
		--jdk			Instala JDK LTS (desenvolvedor)
		--interactive		Executa instalação em modo interativo

	"
}
setSoftwaresToInstall(){
	! isVariabelDeclared $1 && return
	
	newPtr softwares_ref=$1

	echo ""

	for option in "${softwares_ref[@]}";do

		case "$option" in
			"--help"| '-h')
				usage
				exit
			;;
			"--i-games")
				PROGRAM_INSTALL+=$GAMES
			;;
			"--i-mtp_spp")
				PROGRAM_INSTALL+=$MTP_SPP
			;;
			"--i-sdl_libs")
				PROGRAM_INSTALL+=$SDL_LIBS
			;;
			"--i-multimedia")
				PROGRAM_INSTALL+=$MULTIMEDIA
			;;
			"--i-virtualbox")
				installVirtualbox
			;;
			"--i-dev")
				PROGRAM_INSTALL+=${DEV_TOOLS}
			;;
			"--i-non-free")
				PROGRAM_INSTALL+=$NON_FREE
			;;
			"--u-4k")
				install4KVideoDownloader
				if [ ${#softwares_ref[@]} = 1 ]; then
					exit
				fi
			;;
			"--java")
				setMajorJavaLtsSupported "jre"
			;;

			"--i-text="*)
				text_key="${option}"
				text_key="${text_key//--i-text=/}"
				text_editor="${TEXT_EDITOR[$text_key]}"
				echo "Selecionando editor: ${TEXT_STYLE}$text_editor${NORMAL}"
				DEV_TOOLS+=" $text_editor"
			;;

			"--i-android-dev-tools")
				echo "Selecionando: ${TEXT_STYLE}Android Dev tools${NORMAL}"
				DEV_TOOLS+=" $ANDROID_DEV_TOOLS"
			;;

			"--jdk")
				setMajorJavaLtsSupported "jdk"
			;;
			*)
				echo "Error: option invalid!"
				usage
				exit 1
			;;
		esac
	done
}

setActionsByLinuxArch(){
	case "$PROCESSOR_ARCH" in 
		"amd64" | "x86_64" )
			FLAG_WEB_BROWSER=1;
			;;
		*)
			echo "Linux 32 bit is not longer supported"
			exit 1;
		;;
	esac
}

configureDebian(){
	
	DEBIAN_VERSION="${VERSION_CODENAME}"
	LINUX_MODIFICATIONS="onboard gnome-packagekit libreoffice-l10n-pt-br myspell-pt-br epub-utils kinit kio kio-extras kded5"
	APT_EXTRA_KEYS=(https://dl.winehq.org/wine-builds/winehq.key)
	APT_MODIFICATIONS="-t ${DEBIAN_VERSION}-backports "
	APT_MODIFICATIONS+="libreoffice libreoffice-style-breeze libreoffice-writer libreoffice-calc libreoffice-impress"

	SOURCES_LIST_OFICIAL_STR=(
		"#Fonte de aplicativos apt"  
		"deb http://ftp.br.debian.org/debian/ ${DEBIAN_VERSION} main contrib non-free"  
		"deb-src http://ftp.br.debian.org/debian/ $DEBIAN_VERSION main contrib non-free"  
		""  
		"deb http://ftp.br.debian.org/debian-security/ ${DEBIAN_VERSION}-security main contrib non-free"  
		"deb-src http://ftp.br.debian.org/debian-security/ ${DEBIAN_VERSION}-security main contrib non-free"  
		""  
		"# $DEBIAN_VERSION-updates, previously known as 'volatile'"  
		"deb http://ftp.br.debian.org/debian/ ${DEBIAN_VERSION}-updates main contrib non-free"  
		"deb-src http://ftp.br.debian.org/debian/ ${DEBIAN_VERSION}-updates main contrib non-free"  
		""  
		"#Adiciona fontes extras ao debian"  
		"# debian backports"  
		"deb http://ftp.debian.org/debian ${DEBIAN_VERSION}-backports main contrib non-free" 
		"deb-src http://ftp.debian.org/debian ${DEBIAN_VERSION}-backports main contrib non-free" 
	)

	configureDebianNonFreeFirmwareRepository
	getAptKeys APT_EXTRA_KEYS
	WriterFileln $APT_LIST SOURCES_LIST_OFICIAL_STR
	MakeSourcesListD $DEBIAN_VERSION 0
	DebianExtraActions
}

applyConfigByDistroLinux(){
	LINUX_VERSION="$NAME"

	setActionsByLinuxArch
	case "$LINUX_VERSION" in
        *"Linux Mint"*  | *"Ubuntu"* | *"Zorin"*)
			MakeSourcesListD
			LINUX_MODIFICATIONS=" oxygen-icon-theme libreoffice-style-breeze libreoffice libreoffice-writer libreoffice-calc libreoffice-impress "
        ;;

		*"Debian"* )
			configureDebian
		;;
	esac
}
isItToRunInInteractiveMode(){
	local interactive_regex='(\-\-interactive)'
	[[ $possibleInteractive = 0 ]] && [[ "${ARGV[*]}" =~ $interactive_regex ]]
}

setBasicProgramInstall(){
	if [ ${#ARGV[@]} = 0 ]; then 
		PROGRAM_INSTALL=${MTP_SPP}${SDL_LIBS}${MULTIMEDIA}${SYSTEM}
		return
	fi
	PROGRAM_INSTALL+=$SYSTEM
	possibleInteractive=0
}

setModeSoftwaresSelection(){
	local possibleInteractive=1

	setBasicProgramInstall
	if isItToRunInInteractiveMode; then 
		ARGV=("${ARGV[@]//--interactive/}")
		runMenu
	else
		setSoftwaresToInstall "ARGV"
	fi
}

main(){
	local hello_message="$(<$MODULES_PATH/.hello-message.txt)"
	local help_regex='(\-\-help|\-h)'
	echo "${LIGHT_BLUE}$hello_message${ITALIC}v${POSTINSTALL_VERSION}${NORMAL}"
	echo "Este script irá configurar seu Linux para uso"
	
	if [ "$UID" = "0" ]; then
		setModeSoftwaresSelection
		basicInstall
	else

		if [[ "${ARGV[*]}" =~ $help_regex ]];then
			usage
			return
		fi
		printf "Sinto muito, você não tem permissões administrativas para executar este script!\n
		\rTente novamente executando este comando:\nsudo postinstall.sh\n"
		sleep 1
		printf "%s" "Pressione qualquer tecla para encerrar ... "
		read -n 1 exit_key
		exit 1 
	fi
}

main


