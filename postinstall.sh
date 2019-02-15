#!/bin/bash
# Autor: Daniel Oliveira Souza
# Descrição: Faz a configuração de pós instalação do linux mint (ubuntu ou outro variante da família debian"
# Versão: 0.0.16
#--------------------------------------------------------Variaveis --------------------------------------------------
flag=$#
use_proxy=0
#export DISPLAY=:0.0

if [ "$1" = "--habilita_proxy" ]
then
	export http_proxy="http://internet.cua.ufmt.br:3128"
	export https_proxy="https://internet.cua.ufmt.br:3128"
	apt_opt="-o Acquire::http::Proxy=$http_proxy" 
fi
version="PST-USER-0.0.16"
apt_list="/etc/apt/sources.list"
apt_modifications=""
linux_modications=""
flag_apt='0'
flag_op=''
web_browser=""
flag_web_browser=0
arquitetura=$(arch)
export DEBIAN_FRONTEND="gnome"
program_install=""

#caminho de arquivo


repositorys=(
	'/etc/apt/sources.list.d/google-chrome.list'
	'/etc/apt/sources.list.d/sublime-text.list' 
	'/etc/apt/sources.list.d/geogebra.list'
)
mirrors=(
	'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' 
	'deb https://download.sublimetext.com/ apt/stable/' 
	'deb http://www.geogebra.net/linux/ stable main' 
)

#caminho do arquivo de configuração do APT para libreoffice 5

#variavel que verifica se o usuário tem perfil de administrador
permissao=$(whoami)
arquitetura=x86_64
linux_version=$(cat /etc/issue.net);

#esta funçao gera arquivos .list de repositórios conhecidos em /etc/apt/sources.list.d
searchLineinFile(){
	flag=0
	if [ "$1" != "" ];then
		if [ -e "$1" ];then
			if [ "$2" != "" ];then
				line="NULL"
				#file=$1
				while read line # read a line from
				do
					if [ "$line" = "$2" ];then # if current line is equal $2
						flag=1
						break #break loop 
					fi
				done < "$1"
			fi
		fi
	fi
	return $flag # return value 
}
MakeSourcesListD(){
	if [ ${#mirrors[@]} = ${#repositorys[@]} ]
		then
			for ((i = 0 ; i < ${#repositorys[@]} ; i++))
			do
				echo "### THIS FILE IS AUTOMATICALLY CONFIGURED" > ${repositorys[i]}
				echo "###ou may comment out this entry, but any other modifications may be lost." >> ${repositorys[i]}
				echo ${mirrors[i]} >> ${repositorys[i]}

			done
			wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
			wget -q -O - https://static.geogebra.org/linux/office@geogebra.org.gpg.key | apt-key add -
		else
			echo "|mirrors| != |repositorys|"
		fi
}

#verifica se o usuário tem poderes administrativos	
if [ "$permissao" = "root" ]; then
	
	# decide se arquitetura 
	linux_version=$(cat /etc/issue.net);
	case "$arquitetura" in 
		"x86_64")
		MakeSourcesListD;
		flag_web_browser=1;
		;;
		"amd64")
		MakeSourcesListD;
		flag_web_browser=1;
	
		;;
		*)
			echo "Google Chrome não é suportado em linux 32 bit "
		;;
	esac


		#Descobre se o a distribuição do linux você está usando 
		case "$linux_version" in
	        *"Linux Mint"* ) 
				#executa configurações específicas para o linux mint 
			    linux_modications=" android-tools-adb openjdk-8-jdk icedtea-plugin-8 oxygen-icon-theme-complete  libreoffice-style-breeze libreoffice libreoffice-writer libreoffice-calc libreoffice-impress "
			    if [ $flag_web_browser = 0 ]
			     then 
				    web_browser="chromium-l10n chromium-browser "
			    else
				    web_browser="google-chrome-stable "
			    fi
			    apt-add-repository ppa:libreoffice/ppa -y 
			;;
	        *"LMDE"*)
					#excuta configurações específicas para LInux Mint Debian 
	             linux_modications=" android-tools-adb oxygen-icon-theme-complete "
	             apt_modifications=" -t jessie-backports libreoffice-style-breeze libreoffice libreoffice-writer libreoffice-calc libreoffice-impress openjdk-8-jdk "
			   
	             if [ $flag_web_browser = 0 ] ; then 
				    web_browser="chromium-l10n chromium-browser "
			    else
				    web_browser="google-chrome-stable "
			    fi
	        ;;
			*"Debian"* )
				#COnfigurações específicas para debian
				#gerando o sources.list 

				debian_version=""
				ubuntu_compatible=""
				case "$linux_version" in 
					*"9"*)
					debian_version="stretch"
					ubuntu_compatible="xenial"
					;;
					*"Buster"*)
					debian_version="buster"
					ubuntu_compatible="bionic"
					;;
				esac
				lightdm_greeter_config_path="/etc/lightdm/lightdm-gtk-greeter.conf"
				lightdm_greeter_config=(
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
				sources_list_oficial_str=(
					"#Fonte de aplicativos apt"  
					"deb http://ftp.us.debian.org/debian/ $debian_version main contrib non-free"  
					"deb-src http://ftp.us.debian.org/debian/ $debian_version main contrib non-free"  
					""  
					"deb http://security.debian.org/ $debian_version/updates main contrib non-free"  
					"deb-src http://security.debian.org/ $debian_version/updates main contrib non-free"  
					""  
					"# $debian_version-updates, previously known as 'volatile'"  
					"deb http://ftp.us.debian.org/debian/ $debian_version-updates main contrib non-free"  
					"deb-src http://ftp.us.debian.org/debian/ $debian_version-updates main contrib non-free"  
					""  
					"#Adiciona fontes extras ao debian"  
					"# debian backports"  
					"deb http://ftp.debian.org/debian $debian_version-backports main contrib non-free" 
					"deb-src http://ftp.debian.org/debian $debian_version-backports main contrib non-free" 
					#""  
					#"# firefox backports"  
					#"deb http://mozilla.debian.net/ $debian_version-backports firefox-release"  
					#""  
					#"# firefox backports"  
					#"deb http://mozilla.debian.net/ stretch-backports firefox-release"  
					"#Adiciona suporte ao wine"
					"deb https://dl.winehq.org/wine-builds/debian/ $debian_version main"
				)
				oracle_java_source_list_str=(
					"deb http://ppa.launchpad.net/webupd8team/java/ubuntu $ubuntu_compatible main"  
					"deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu $ubuntu_compatible main"  	
				)
				for((i=0;i<${#sources_list_oficial_str[*]};i++))
				do
					if [ $i = 0 ]; then 
						echo "reescrevendo debian sources.list"
						echo "${sources_list_oficial_str[i]}" > /etc/apt/sources.list
					else
						echo "${sources_list_oficial_str[i]}" >> /etc/apt/sources.list
					fi
				done

				for((i=0;i<${#oracle_java_source_list_str[*]};i++))
				do
					if [ $i = 0 ]; then 
						echo "${oracle_java_source_list_str[i]}" > /etc/apt/sources.list.d/webupd8team-java.list
					else
						echo "${oracle_java_source_list_str[i]}" >> /etc/apt/sources.list.d/webupd8team-java.list
					fi
				done
				#procura no arquivo a linha de configuração
				searchLineinFile $lightdm_greeter_config_path ${lightdm_greeter_config[12]}
				#verifica-se o arquivo não está configurado
				if [ $? = 0 ]; then
					#escreva a configuração no arquivo!
					for ((i=0;i<${#lightdm_greeter_config[*]};i++}))
					do
						echo "${lightdm_greeter_config[i]}" >> $lightdm_greeter_config_path
					done
				else
					echo "lightdm está configurado!"
				fi

				apt-key adv --keyserver keyserver.ubuntu.com:80 --recv-keys EEA14886 
				wget -q -O - https://dl.winehq.org/wine-builds/winehq.key  | apt-key add -


				#
				linux_modifications="onboard openjdk-8-jdk icedtea-8-plugin gnome-packagekit libreoffice-l10n-pt-br myspell-pt-br mysql-community-server  epub-utils	 kinit kio kio-extras kded5"
				apt_modifications="-t stretch-backports   "
				apt_modifications=$apt_modifications"libreoffice libreoffice-style-breeze libreoffice-writer libreoffice-calc libreoffice-impress"
				if [ $flag_web_browser = 0 ] ; then 
					web_browser="chromium-l10n chromium"
				else
					web_browser="google-chrome-stable "
				fi
				 # verifica se o usuáŕio 'meninas' existe 
				 cat /etc/group | grep meninas  | cut -d: -f1 
				if [ $? = 0 ]; then
					adduser meninas sudo
				fi
				# verifica se o usuário 'ester' existe 
				cat /etc/group | grep ester | cut -d: -f1 
				if [ $? = 0 ];then
					adduser ester sudo
				fi
				# desabilite apt-
				flag_apt='1'

				;;
				*"Ubuntu"*)
				linux_modifications=" adb openjdk-8-jdk icedtea-8-plugin libreoffice-style-breeze libreoffice libreoffice-writer libreoffice-calc libreoffice-impress "
				if [ $flag_web_browser = 0 ] ; then 
					web_browser="chromium-l10n chromium-browser "
				else
					web_browser="google-chrome-stable "
				fi
				apt-add-repository ppa:libreoffice/ppa -y 
	        ;;
		esac
		
	games="supertux extremetuxracer gweled gnome-mahjongg "
	mtp_spp="libmtp-common mtp-tools libmtp-dev libmtp-runtime libmtp9 python-pymtp   "
	sdl_libs="libsdl -image-gst libsdl-ttf2.0-dev libsdl-sound1.2 libsdl-gfx1.2-dev libsdl-mixer1.2-dev libsdl-image1.2-dev "
	dev_tools="g++ kate mesa-utils sublime-text android-tools-fastboot android-tools-adb "
	multimedia="vlc kde-l10n-ptbr kolourpaint4 gimp gimp-data-extras krita winff audacity  "
	non_free="exfat-utils  exfat-fuse  rar unrar p7zip-full p7zip-rar ttf-mscorefonts-installer "
	system=" gparted dnsmasq-base bleachbit  synaptic apt-transport-https "
	education="geogebra5 "
	argv=($*)
	echo 'qtArgs'$#
	if [ $# = 0 ]; then
		program_install=$game$mtp_spp$sdl_libs$dev_tools$multimedia$system$education
	else
		program_install=$program_install$non_free$system
		for((i=0;i<$#;i++))
		do
			echo ${argv[i]}
			case  "${argv[i]}" in
				"--i-games")
					program_install=$program_install$games
					;;
				"--i-mtp_spp")
					program_install=$program_install$mtp_spp
					;;
				"--i-sdl_libs")
					program_install=$program_install$sdl_libs
					;;
				"--i-multimedia")
					program_install=$program_install$multimedia
				;;
				"--i-education")
					program_install=$program_install$education
				;;
				"--habilita_proxy") 
				if [ $# =1 ] ; then
					program_install=$game$mtp_spp$sdl_libs$dev_tools$multimedia$system$education
				fi
					;;

	
			esac
		done
		
	fi
	echo "sua string de instalação é:" $program_install
	#program_remove="dragonplayer  "


	#------------------------------------------------------Fim da sessão de variaveis---------------------------------
	# Este comando adiciona o repositório do google chrome no apt
	echo "Este script irá configurar seu computador para o uso"
	echo $version
# Verifica se é possivel  executar script com permissões administrativas


		#fazendo o backup de mbr,,,,,,,,,,,,,,,,,,,,,,
		dd if=/dev/sda of=backup.mbr bs=512 count=1
		
		#Impede a invocação do apt_add_repository mesmo que exista no debian !
		#if [ "$flag_apt" = "0" ]; then
		#comando para adicionar ppa  do java oracle
		#	if [ -e /usr/bin/apt-add-repository ]; then
		#		apt-add-repository ppa:webupd8team/java -y
		#	fi
		#fi                 
		#este comando adiciona a chave do repositório do google chrome ao sistema apt 
		
		#lista os programas e suas versões
		apt-get update
		#apt-get remove iceweasel -y --allow-unauthenticated 
		#baixa e instala as atualizações
		apt-get dist-upgrade  -y --allow-unauthenticated 
		flag_op=$flag_op$?
		#instal os programas listados pela variavel program_install
		apt-get install $program_install -y --allow-unauthenticated 
		flag_op=$flag_op$?
		apt-get install $linux_modifications -y --allow-unauthenticated 
		flag_op=$flag_op$?
		apt-get install $apt_modifications -y --allow-unauthenticated 
		flag_op=$flag_op$?


		apt-get install $web_browser -y --allow-unauthenticated 
		flag_op=$flag_op$?
		#instala as dependencias 
		apt-get install -f -y --allow-unauthenticated 
		flag_op=$flag_op$?
		#remove programas que eu acho desnecessários, listados pela variavel $programa_remove  
		apt-get remove $program_remove -y
		flag_op=$flag_op$?
		#remove dependencias dos programas removidos
		apt-get autoremove -y --allow-unauthenticated 
		#limpa o cache do apt se todas operações de instalação foram concluidas com sucesso
		if [ "$flag_op" = "0000000" ]; then
			echo 'Limpando o cache do APT...'
			apt-get clean 
		fi

				echo "Crie as seguintes contas: no programa usuários e grupos... pai e ester ..." 
		#Adiciona pai ao grupo de usuários que não precisam de senha para se conectar ao computar
		#Altera o proprietário todos os arquivos e diretório dos usuários
		
		# Armazaena uma lista de usuarios cadastrados no computador 
		usuarios=($(cat /etc/group | grep 100 | cut -d: -f1))
		for((i=1 ;i<${#usuarios[@]} ;i++))
		do
			usuario_i=${usuarios[i]}
			# Se existe o diretório do 
			# if [ -e /home/$usuario_i ]
			# 	then
			# 	chown $usuario_i:$usuario_i  -R /home/$usuario_i
			# fi
		done
		if [ -e /home/meninas/usr ]; then
			cp -r /home/meninas/usr /
                else
			if [ -e /home/cassia/usr/ ]; then
				cp /home/cassia/usr /
			fi
        fi
		
	else
		#O comando printf é usado para fazer imprimir mensagem formatada funciona de maneira semelhante ao printf da
		#linguagem C
		printf "Sinto muito, você não tem permissões administrativas para executar este script!\n
		\rTente novamente executando este comando:\nsudo postinstall.sh\n"
		#exit 1
		echo "Pressione qualquer tecla para encerrar..."
		Sleep 10
		exit 1 
	fi
	