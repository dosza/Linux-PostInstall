#!/bin/bash
# Autor: Daniel Oliveira Souza
# Descrição: Faz a configuração de pós instalação do linux mint (ubuntu ou outro variante da família debian"
# Versão: 0.4.2
#--------------------------------------------------------Variaveis --------------------------------------------------
source /etc/os-release

if [ -e "$PWD/ext-bash" ]; then
	MODULES_PATH=$PWD
elif [ -e "$(dirname $0)/ext-bash" ]; then
	MODULES_PATH="$(dirname $0)"
fi

source "$MODULES_PATH/ext-bash/extended-bash.sh"
declare  -r DEBIAN_SUPPORT_FIRMWARE_REPO=12

JAVA_LTS_VERSION=(21 17 11)
POSTINSTALL_VERSION='0.4.2'
APT_LIST_LEGACY="/etc/apt/sources.list"
APT_LIST="/etc/apt/sources.list.d/debian.sources"
APT_MODIFICATIONS=""
LINUX_MODIFICATIONS=""
WEB_BROWSER="google-chrome-stable"
FLAG_WEB_BROWSER=0
PROCESSOR_ARCH=$(arch)
PROGRAM_INSTALL=""
ORACLE_REPO_VIRTUALBOX_VERSION=(7.0 6.1)
MTP_SPP="libmtp-common mtp-tools libmtp-dev libmtp-runtime libmtp9 "
SDL_LIBS="libsdl-ttf2.0-dev libsdl-sound1.2 libsdl-gfx1.2-dev libsdl-mixer1.2-dev libsdl-image1.2-dev "
DEV_TOOLS=""
ANDROID_DEV_TOOLS="android-tools-fastboot android-tools-adb"

declare -A TEXT_EDITOR=(
	['sublime']="sublime-text"
	['vscode']='code'
)

MULTIMEDIA="vlc language-pack-kde-pt kolourpaint gimp gimp-data-extras winff "
NON_FREE="rar unrar p7zip-full p7zip-rar ttf-mscorefonts-installer "
SYSTEM=" gparted dnsmasq-base bleachbit  apt-transport-https "

ARGV=($@)

VIRTUALBOX_VERSION=virtualbox
PROGRAM_REMOVE=('4kvideodownloader')

LIGHT_BLUE=$'\e[1;36m'
ITALIC=$'\e[1;3m'
TEXT_STYLE="${LIGHT_BLUE}${ITALIC}"


checkReadFileStatus(){
	
	[ ! -e "$1" ] && return $BASH_FALSE

	local permissions=$( stat -c  '%a' "$1 ")
	local read_permissions=644

	[ "$permissions" = "$read_permissions" ]

}
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
	local tmpfile=$(mktemp)
	local uagent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Safari/537.36"
	local product_videodownloader='https://www.4kdownload.com/pt-br/products/videodownloader-8'
	wget  --user-agent="$uagent" -qO-  $product_videodownloader   > $tmpfile

	echo tmpfile=$tmpfile


	sed "s|>|>\n|g" -i  $tmpfile 
	_4kvideodownload_url="$( 
		grep "https://dl\.4k" $tmpfile |
		grep "\.deb" -m1 |   
		sed 's/source=website//g;s/[>\?]//g' |
		awk -F'"url":' '{ print $2 }' | 
		awk -F',' ' { print $1 }' | 
		sed 's/["]//g'

	)"



	echo try getting $_4kvideodownload_url
	local _4kvideodownload_version=$(
		echo "$_4kvideodownload_url" | 
		awk -F'_' ' { print $2 }'		
	)

	parse4KUrlVersion

	local _4kvideodownload_deb=$(
		echo $_4kvideodownload_url |
		awk -F'/' '{print $NF}'
	)

	local current_version_4k_videodownloader="$(
		getDebPackVersion 4kvideodownloaderplus | 
		sed 's/\-/\./g'
	)"
	
	if ! get4kVideoDownloaderStatus; then 
		wget --user-agent="$uagent" "$_4kvideodownload_url"
		dpkg -i $_4kvideodownload_deb
		apt-get -f install -y 
		rm $_4kvideodownload_deb
	fi
	
	rm $tmpfile
}



MakeDeb822Str(){

	local types="Types"
	local suites="Suites"
	local uris="URIs"
	local components="Components"
	local arch="Architectures"
	local signed_by="Signed-by"
	local x_repo_name="X-Repolib-Name"
	
	case $# in 

		4)
			echo "${types}: $1\n${uris}: $2\n${suites}: $3\n${signed_by}: $4"
		;;

		5)
			echo "${types}: $1\n${uris}: $2\n${suites}: $3\n${components}: $4\n${signed_by}: $5"
		;;
		
		6)
			echo "${types}: $1\n${uris}: $2\n${suites}: $3\n${components}: $4\n${arch}: $5\n${signed_by}: $6"
		;;

		7)
			echo "${x_repo_name}: $7\n${types}: $1\n${uris}: $2\n${suites}: $3\n${components}: $4\n${arch}: $5\n${signed_by}: $6"
		;;

	*)
		echo "invalid argument" >&2
		exit 1
	;;
	esac
}

MakeSourcesListD(){

	local apt_key_url_repository=(
		
		"https://dl-ssl.google.com/linux/linux_signing_key.pub"
		"https://download.sublimetext.com/sublimehq-pub.gpg"
		'https://packages.microsoft.com/keys/microsoft.asc'
	)

	local repository_list_path=(
		'/etc/apt/sources.list.d/google-chrome.sources'
		'/etc/apt/sources.list.d/sublime-text.sources'
		"/etc/apt/sources.list.d/vscode.sources"
	)

	local setup_scripts=(
		"https://deb.nodesource.com/setup_lts.x"
	)


	OLDIFS="$IFS"

	IFS=$(printf "%b" "\n")

	local mirrors=(
		
		"$(MakeDeb822Str \
			"deb"  \
			"https://dl.google.com/linux/chrome-stable/deb/"\
			"stable" \
			"main"  \
			"amd64" \
			"/usr/share/keyrings/google-chrome.gpg" \
			"Google Chrome" \
		)"

		"$(
			MakeDeb822Str \
				"deb" \
				"https://download.sublimetext.com/" \
				"apt/stable/" \
				"/etc/apt/keyrings/sublimehq-pub.gpg"
		)"

		"$(
			MakeDeb822Str \
				"deb" \
				"https://packages.microsoft.com/repos/code" \
				"stable"  \
				"main" \
				"amd64" \
				"/usr/share/keyrings/microsoft.gpg"
		)"
	)

	ConfigureSourcesList apt_key_url_repository repository_list_path mirrors
	ConfigureSourcesListByScript setup_scripts
	
	arrayMap repository_list_path repo_path '{
		chmod 644 $repo_path
	}'

	IFS="$OLDIFS"
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

AptDistUpgrade(){
	local apt_opts=(-y --allow-unauthenticated)
	local apt_opts_err=(--fix-missing)
	
	waitAptDpkg
	apt-get update
	waitAptDpkg
	
	if ! apt-get dist-upgrade ${apt_opts[*]}; then 
		waitAptDpkg
		apt-get dist-upgrade ${apt_opts[*]} ${apt_opts_err[*]}
		WARM_ERROR_NETWORK_AND_EXIT
	fi

}

AptRemove(){
	apt-get remove $*
}

isDevToolsEnabled(){
	[ "$dev_mode" = "1" ] || [ "$DEV_TOOLS" != "" ]
}
getListToInstall(){
	PROGRAM_INSTALL="$COMMON_SHELL_MIN_DEPS $PROGRAM_INSTALL $LINUX_MODIFICATIONS $WEB_BROWSER"
	if isDevToolsEnabled; then 
		echo "Modo ${TEXT_STYLE} desenvolvedor${DEFAULT} ativado"
		PROGRAM_INSTALL+=" $DEV_TOOLS"
	fi
}

basicInstall(){
	getListToInstall
	applyConfigByDistroLinux
	getCurrentDebianFrontend
	AptDistUpgrade
	AptInstall $PROGRAM_INSTALL -f
	RunAptModifications	
	FilterProgramToRemove
	AptRemove ${PROGRAM_REMOVE[*]}
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

}


setMajorJavaLtsSupported(){
	[ "$1" =  "" ] && return

	local java_type="$1"
	local java_deb
	
	for java_version in "${JAVA_LTS_VERSION[@]}";do
		
		java_deb="openjdk-${java_version}-${java_type}"
		if apt show  "$java_deb" &>/dev/null; then
			echo "Selecionando: ${TEXT_STYLE}Java ${java_type^^} $java_version LTS${DEFAULT}"
			LINUX_MODIFICATIONS+=" $java_deb"
			return
		fi
	done
}


isYes(){
	read answer
	[ "${answer,,}" = "s" ] || [ "${answer,,}" = "y" ]
}

markSoftwareClassItem(){
	echo -en " ${TEXT_STYLE}$class${DEFAULT} ${ITALIC}s/n?${DEFAULT} "
	! isYes && return 
	mark_to_install+=("$install_code")
}

runMenu(){
	
	local answer
	local mark_to_install=()
	
	local -A dev_tools_list=(
		['JDK LTS']="--i-jdk"
		['Ferramentas do Android']='--i-android-dev-tools'
		['Sublime Text']='--i-text=sublime'
		['Visual Studio Code']='--i-text=vscode'
		['bibliotecas SDL']="--i-sdl-libs"
		['Nodejs LTS']="--i-nodejs-lts"
		['GCC']='--i-gcc'
		['Clang LLVM Compiler']='--i-clang'
	)

	local -A install_list=(
		['Java LTS']="--i-java"
		['Suporte MTP']="--i-mtp-spp"
		['Multimidia']="--i-multimedia"
		['Virtualbox']='--i-virtualbox'
		['Softwares proprietários e fontes Microsoft TrueType']='--i-non-free'
		['4K Video Downloader plus']="--u-4k"
	)

	echo "Selecione o grupo de ${TEXT_STYLE}Ferramentas${DEFAULT} que deseja instalar"
	echo ""

	arrayMap install_list install_code class 'markSoftwareClassItem'

	echo  -en " ${TEXT_STYLE}Ferramentas de desenvolvedor${DEFAULT} ${ITALIC}s/n?${DEFAULT} " 
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

	echo "Uso: sudo ./postinstall.sh ${LIGHT_BLUE}--[option]${DEFAULT} ou --i-text=${LIGHT_BLUE}[text-option]${DEFAULT}
		--help,-h 		exibe esta ajuda
		
		--interactive		Executa instalação em modo interativo

		--i-mtp-spp		Instala bibliotecas MTP (Protocolo de transferencia de arquivos Android)
		--i-multimedia		Instala Softwares de multimídia (VLC Player, Winff,Gimp,...)
		--i-java		Instala Java LTS
		--i-non-free		Instala softwares e codecs proprietários (rar,fontes: arial,times new,...)
		--i-virtualbox		Instala e configura o Virtuabox
		--u-4k			Instala/atualiza somente o 4kvideodownloaderplus		
				
				${TEXT_STYLE}Ferramentas de desenvolvedor${DEFAULT}:

		--i-dev			Modo desenvolvedor
		--i-sdl-libs		Instala bibliotecas SDL
		--i-text=sublime 	Instala o Sublime Text 
		--i-text=vscode 	Instala Visual Studio Code 
		--i-android-dev-tools	Instala Android Fast Boot e Android ADB
		--i-nodejs-lts		Instala o NodeJS LTS
		--i-jdk			Instala JDK LTS
		--i-gcc		Instala compilador GCC
		--i-clang	Instala Compilador LLVM Clang


	"
}
setSoftwaresToInstall(){
	! isVariableDeclared $1 && return
	
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
			"--i-mtp-spp")
				PROGRAM_INSTALL+=$MTP_SPP
			;;
			"--i-sdl-libs")
				PROGRAM_INSTALL+=$SDL_LIBS
			;;
			"--i-multimedia")
				PROGRAM_INSTALL+=$MULTIMEDIA
			;;
			"--i-virtualbox")
				installVirtualbox
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

			"--i-dev")
				dev_mode=1
			;;
			"--i-java")
				setMajorJavaLtsSupported "jre"
			;;


			"--i-text="*)
				
				text_key="${option}"
				text_key="${text_key//--i-text=/}"
				text_editor="${TEXT_EDITOR[$text_key]}"
				
				[ "$text_editor" = "" ] && continue
				
				DEV_TOOLS+=" $text_editor"

				echo "Selecionando editor: ${TEXT_STYLE}${text_key^}${DEFAULT}"
			;;

			"--i-android-dev-tools")
				echo "Selecionando: ${TEXT_STYLE}Android Dev tools${DEFAULT}"
				DEV_TOOLS+=" $ANDROID_DEV_TOOLS"
			;;

			"--i-jdk")
				dev_mode=1
				setMajorJavaLtsSupported "jdk"
			;;
			"--i-nodejs-lts")
				DEV_TOOLS+=" nodejs"
			;;
			
			"--i-gcc")
				DEV_TOOLS+=" gcc"
			;;

			"--i-clang")
				DEV_TOOLS+=" clang"
			;;

			*)
				echo "Invalid option: ${RED}$option${DEFAULT}!"
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
		'# /etc/apt/sources.list.d/debian.sources'
		'# Debian Stable'
		''
		"Types: deb deb-src"
		"URIs: https://deb.debian.org/debian"
		Suites: ${DEBIAN_VERSION} ${DEBIAN_VERSION}-updates  ${DEBIAN_VERSION}-backports
		"Components: main contrib non-free non-free-firmware"
		"Enabled: yes"
		"Signed-by: /usr/share/keyrings/debian-archive-keyring.gpg"
		""
		"Types: deb deb-src"
		"URIs: https://security.debian.org/debian-security"
		"Suites: ${DEBIAN_VERSION}-security"
		"Components: main contrib non-free non-free-firmware"
		"Enabled: yes"
		"Signed-by: /usr/share/keyrings/debian-archive-keyring.gpg"
	)

	if [ -e APT_LIST_LEGACY ]; then
		apt modernize-sources
	fi


	getAptKeys APT_EXTRA_KEYS
	WriterFileln $APT_LIST SOURCES_LIST_OFICIAL_STR && chmod 644 $APT_LIST
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
	local dev_mode=0
	echo "${LIGHT_BLUE}$hello_message${ITALIC}v${POSTINSTALL_VERSION}${DEFAULT}"
	echo "Este script irá configurar seu Linux para uso"
	
	if [ "$UID" = "0" ]; then
		sudo apt-get update
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


