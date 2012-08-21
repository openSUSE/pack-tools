#flash-player updater
#Daniel Lovasko (dlovasko@suse.com)
#based on code by Dirk Muller

source ./updater_commons.sh

function flashplugin
{
	#file
	f=$2

	#arch
	a=$1

	#try to avoid multiple same downloads
	if [[ ! -e "../install_flash_player_11_linux.$a.tar.gz" ]]
	then
		#locate download url
		download_url=$(curl -s 'http://get.adobe.com/flashplayer/completion/?installer=Flash_Player_11_for_other_Linux_(.tar.gz)_32-bit' | egrep  -o 'http:\/\/fpdownload.macromedia.com\/get\/flashplayer\/pdc\/11.*\/install_flash_player_11_linux.'$a'.tar.gz')
		echo "Trying download $download_url.";
		wget -q -P .. $download_url
	fi
	
	#local md5sum
	tar xf $f libflashplayer.so
	actual_md5=$(md5sum libflashplayer.so | cut -d' ' -f1)
	rm -f libflashplayer.so 

	#downloaded md5sum
	tar xf "../install_flash_player_11_linux.$a.tar.gz" libflashplayer.so
	downloaded_md5=$(md5sum libflashplayer.so | cut -d' ' -f1)

	#if new version
	if [[ $downloaded_md5 != $actual_md5 ]]
	then
		version=$(strings  libflashplayer.so | grep "LNX 11," |cut -d' ' -f2 | sed -e 's#,#.#g')
		rm $f

		#copy and repack with bz2 algorithm
		cp "../install_flash_player_11_linux.$a.tar.gz" .
		bznew install_flash_player_11_linux.$a.tar.gz
		mv install_flash_player_11_linux.$a.tar.bz2 install_flash_player_${version}_linux.$a.tar.bz2

		echo $version
	else
		echo "false"
	fi
}

function flashplayer
{
	#file
	f=$2

	#arch
	a=$1

	#try to avoid multiple same downloads
	if [[ ! -e "../flashplayer_11_sa.$a.tar.gz" ]]
	then
		wget -q -P .. http://fpdownload.macromedia.com/pub/flashplayer/updaters/11/flashplayer_11_sa.$a.tar.gz
	fi
	
	#local md5sum
	echo "reading $f"
	tar xf $f flashplayer
	actual_md5=$(md5sum flashplayer | cut -d' ' -f1)
	rm -f flashplayer

	#downloaded md5sum
	tar xf "../flashplayer_11_sa.$a.tar.gz" flashplayer
	downloaded_md5=$(md5sum flashplayer | cut -d' ' -f1)

	#if new version
	if [[ $downloaded_md5 != $actual_md5 ]]
	then
		version=$(strings flashplayer | grep "LNX 11," |cut -d' ' -f2 | sed -e 's#,#.#g')
        rm $f

		#copy and repack with bz2 algorithm
		cp "../flashplayer_11_sa.$a.tar.gz" .
		bznew flashplayer_11_sa.$a.tar.gz
		mv flashplayer_11_sa.$a.tar.bz2 flashplayer_${version}_sa.$a.tar.bz2

		echo $version
	else
		echo "false"
	fi
}

##main

#flag potential files & select corresponding function name
declare -A pairs
add_pair install_flash_player_11*_linux.i386.tar.bz2 'flashplugin i386'
add_pair install_flash_player_11*_linux.x86_64.tar.bz2 'flashplugin x86_64'
add_pair flashplayer_*_sa.i386.tar.bz2 'flashplayer i386'
add_pair flashplayer_*_sa.x86_64.tar.bz2 'flashplayer x86_64'

#get all maintained versions of flash-player
pck getpac -v flash-player

#try to upgrade every maintained version
cd flash-player

#update
do_update