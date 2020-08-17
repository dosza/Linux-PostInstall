Linux-PostInstall v0.2.1
====

<p>
	Linux-PostInstall é uma ferramenta de linha de comando que permite a automação da instalação e configuração de programas em uma distribuição Linux baseada em Debian.
	Desenvolvido desde 22/10/2015,script com objetivo similar ao <a href="https://github.com/DanielOliveiraSouza/ufmt-cua-lab-tools"> UFMT CUA Lab Tools</a>, tem o  objetivo de tornar mais fácil a utilização do Linux.
</p>

Distribuições  Oficialmente Suportadas
----

<ul>
	<li>Debian/GNU Linux 10</li>
	<li>Ubuntu 18.04 LTS</li>
	<li>Linux Mint 19 <strong>Cinnamon</strong></li>
</ul>		

**Oque a ferramenta faz?**
<ul>
	<li>Configura repositórios</li>
	<li>Instala utilitários</li>
	<li>Realiza pós-configuração</li>
</ul> 

**O que a ferramenta instala?**
<ul>
	<li>Softwares de multímidia (VLC,audacity,winff,entre outros)</li>
	<li>Editores de imagem (Gimp,kolourpaint,entre outros)</li>
	<li>Bibliotecas e utilitários para melhor funcionamento do sistema (libmtp, java (openJRE,gparted,entre outros...))</li>
	<li>Softwares  uteis (para extrair arquivos rar,7zip,exfat,source,Google Chrome,entre outros)</li>
</ul>


**Como usar**
	Obs: Exige poderes de ***root***!
	Sintaxe: sudo bash posinstall.sh [args]
	<pre>
		sudo bash postinstall.sh 				Instala bibliotecas e softwares úteis (incluindo o Google Chrome)
		sudo bash postinstall.sh 	--i-mtp_spp		Instala bibliotecas MTP
		sudo bash postinstall.sh 	--i-sdl_libs		Instala bibliotecas SDL
		sudo bash postinstall.sh 	--i-multimedia		Instala Softwares de multimídia
		sudo bash postinstall.sh 	--i-education		Instala o Geogebra (atualizado)
		sudo bash postinstall.sh 	--i-virtualbox		Instala e configura o Virtuabox (versão 6) (desde que aceite a licença)
	</pre>
	<strong>Obs: alternativamente no lugar de sudo você pode usar o PKEXEC</strong>
</p>

**Softwares Proprietários Instalados**
<ul>
	<li>Google Chrome</li>
	<li>Rar (implementaçao do algoritmo de descompressão)</li>
	<li>Fontes True type Microsoft <strong> (obs: desde que aceite os termos de licença)</strong></li>
	<li>EXFat (implementação aberta do sistema de arquivos extfat e utilitários)
	<li>4K Video Downlaoder (software para baixar vídeos do Youtube)</li>
</ul>

	

**Sobre a Configuração de repositórios:**
Esta ferramenta adiciona alguns repositórios para atualizar softwares
<ul>
	<li>Debian:Sobrescreve o arquivo /etc/apt/sources.list e adiciona as fontes <em>nonfree</em>,<em>contrib</em> e <em>backports</em></li>
	<li>Ubuntu/Mint  adiciona  PPA do Libreoffice (para obter a versão mais recente dele)
</ul>

**Repositórios comuns adicionados**
<ul>
	<li>Google Chrome</li>
	<li>Geogebra (não é instalado por padrão, apenas é repositório configurado)</li>
	<li>Sublime-text</li>
	<li>Virtualbox (não é instalado por padrão, apenas o repositório configurado)</li>
</ul>

<p>
<strong>Obs:</strong>  Está em desenvolvimento os modos:
<ul>
	<li><em>free</em>  (somente software livre)!</li>
	<li><em>stable</em> (somente software estáveis)!</li>
	<li><em>dev</em> (somente modo desenvolvedor)! </li>
</ul>
</p>