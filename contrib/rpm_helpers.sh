### Extract src.rpm into current directory
### TODO: invent better name
function unsrcrpm() {
	rpm2cpio "${1}" | cpio -imdv
}


