- **mtpfs, gvfs-mtp and jmtpfs**:       for enabling media Transfer Protocol 
- **gvfs,gvfs-mtp, gvfs-gphoto2, thunar-walman, tumbler, udisks2, android-udev**:     all the thunar packages 
- **nautilus** - file system check

	- create a manual mirrorlist with global CDN mirrors that typically have good global presence
		## Create a new mirrorlist with global CDNs 
		sudo bash -c 'cat > /etc/pacman.d/mirrorlist << EOL 
		## Global CDN Mirrors 
		Server = https://geo.mirror.pkgbuild.com/\$repo/os/\$arch 
		Server = https://mirror.rackspace.com/archlinux/\$repo/os/\$arch 
		Server = https://mirror.leaseweb.net/archlinux/\$repo/os/\$arch 
		## Try some specific mirrors that are generally reliable 
		Server = https://mirror.osbeck.com/archlinux/\$repo/os/\$arch 
		Server = https://archlinux.mailtunnel.eu/\$repo/os/\$arch 
		Server = https://mirrors.kernel.org/archlinux/\$repo/os/\$arch EOL'
	- installing the chaotic aur keyring 
		## Add the keyring package 
		**sudo pacman -U https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst** 
		## Initialize the keyring 
		**sudo pacman-key --populate chaotic**
	- to remove cache packages : 
		**sudo pacman -Sc**
		**sudo rm -rf /var/cache/pacman/pkg/***
		**sudo mkdir -p /var/cache/pacman/pkg**
		**sudo chmod 755 /var/cache/pacman/pkg**
		**sudo pacman -Syy**
	- forcefully remove :
		**sudo rm -f path/to/folder/file**
	- update database to fast locate files:
		**sudo updatedb**
	- entering yes to every question asked 
		**sudo pacman -Syu --noconfirm**
	- to change the 

# programming:
	**jupyter kernelspec (list,remove kernel_name)**: jupyter related
	**python -m ipykernel install --user --name=.venv --display-name"kernel_name"**:  to add new jupyter kernel