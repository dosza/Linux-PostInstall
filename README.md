<h1 align="center">
	Linux Post Install<br/>
	<a href="https://github.com/DanielOliveiraSouza/Linux-PostInstall/archive/v0.3.0.zip"><img src="https://img.shields.io/badge/Release-v0.3.0-green">
	</a>
</h1>

<p>
	Linux-PostInstall é uma ferramenta de linha de comando que permite a automação da instalação e configuração de programas em uma distribuição Linux baseada em Debian.</br>
	O objetivo desse script é tornar a pós-instalação do Linux mais amigável e rápida

</p>

Distribuições  Oficialmente Suportadas
----

+	Debian 12
+	Ubuntu 22.04
+	Linux Mint 21 **Cinnamon**


Oque a ferramenta instala?
---
+	Softwares de multímidia (VLC,audacity,winff,entre outros)
+	Editores de imagem (Gimp,kolourpaint,entre outros)
+	Bibliotecas e utilitários para melhor funcionamento do sistema (libmtp,gparted,entre outros...))
+	Softwares  uteis (para extrair arquivos rar,7zip,exfat,source,Google Chrome,entre outros)


Como usar?
---
Obs: Exige poderes de ***root***!
```console
user@pc:~$ #Sintaxe: sudo bash posinstall.sh [args]
user@pc:~$ sudo bash postinstall.sh 				#Instala bibliotecas e softwares úteis (incluindo o Google Chrome)
user@pc:~$ sudo bash postinstall.sh 	--i-mtp_spp		#Instala bibliotecas MTP
user@pc:~$ sudo bash postinstall.sh 	--i-sdl_libs		#Instala bibliotecas SDL
user@pc:~$ sudo bash postinstall.sh 	--i-multimedia		#Instala Softwares de multimídia
user@pc:~$ sudo bash postinstall.sh 	--i-virtualbox		#Instala e configura o Virtuabox (versão 6) (desde que aceite a licença)
user@pc:~$ sudo bash postinstall.sh 	--u-4k				#Instala/atualiza somente o 4kvideodownloaderplus
#Instala o JAVA JRE para executar aplicativos java
user@pc:~$ sudo bash postinstall.sh 	--java				
#Instala as JAVA JDK LTS para desenvolver aplicativos com o java
user@pc:~$ sudo bash postinstall.sh 	--jdk
#Executa a instalação interativa
user@pc:~$ sudo bash postinstall.sh 	--interactive

```
<p>
	</pre>
	<strong>Obs: alternativamente no lugar de sudo você pode usar o PKEXEC</strong>
</p>

Softwares Proprietários Instalados
---
+	Google Chrome
+	Rar (implementaçao do algoritmo de descompressão)
+	Fontes True type Microsoft **(obs: desde que aceite os termos de licença)**
+	EXFat (implementação aberta do sistema de arquivos extfat e utilitários)
+	4K Video Downlaoder Plus (software para baixar vídeos do Youtube)
	

Sobre a Configuração de repositórios:
---
Esta ferramenta adiciona alguns repositórios para atualizar softwares
+	Debian:
	+	Sobrescreve o arquivo /etc/apt/sources.list e adiciona as fontes *nonfree*,*contrib*, *backports*

Repositórios comuns adicionados
---

+	Google Chrome
+	Sublime-text


<p>
	<strong>Obs:</strong>  Está em desenvolvimento os modos:
	<ul>
		<li><em>free</em>  (somente software livre)!</li>
		<li><em>stable</em> (somente software estáveis)!</li>
		<li><em>dev</em> (somente modo desenvolvedor)! </li>
	</ul>
</p>