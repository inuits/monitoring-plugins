#!/bin/sh
#
# Usage:
# Requires showmount command from nfs-utils or nfs-common.
# Checks the given host for NFS shares and tries to mount them.
# If all shares are mountable then the exit code is 0
# Exit code 1 means the system doesn't support NFS 
# Exit code 2 means the showmount command is not found
# Exit code 3 means one share couldn't be mounted
# Exit code 4 means there are no shares found

host=''
localdir='/tmp/nfs_test'
exit_code=0

usage() {
echo "
usage: $0 <option>
-l local directory (default = /tmp/check_nfs)
-h host (required)
"
exit -1
}

remove_error_file(){
	if test -f /tmp/error_nfs; then
		rm -rf /tmp/error_nfs
	fi
}

while getopts 'l:h:' OPTION ;do
	case $OPTION in

		h) host=$OPTARG;;
		l) localdir=$OPTARG;;
		*) usage;;
	esac
done

if [[ -z $localdir ]] || [[ -z $host ]]; then
	usage
fi



if [[ -z $(ls /lib/modules/$(uname -r)/kernel/fs | grep nfs) ]]; then
	echo "NFS not supported by system"
	echo "Install nfs-utils and then try again"
	exit 1
else
	echo "NFS supported"
fi

which showmount &>/dev/null || echo "Cannot find showmount command. Exiting..." || exit 2

mkdir -p $localdir

mount_points=( $(showmount -e $host | grep / | sed s,'*',,g) )

if [[ -z $mount_points ]]; then
	echo "No mounts detected. Exiting..."
	exit 4
fi

set +e
for mount_p in $mount_points; do
	mkdir -p $localdir/$mount_p
	nfs_command="mount -t nfs $host:$mount_p $localdir$mount_p"
	echo "Testing nfs mount $mount_p"
	sh -c "$nfs_command" 2>/tmp/error_nfs 1>/dev/null
	if [ $? -ne 0 ]; then
		echo "Failed to mount NFS share $mount_p: $(cat /tmp/error_nfs)"
		remove_error_file
		exit_code=3
	else
		echo "Succes mounting NFS share $mount_p"
	fi
	umount $localdir/$mount_p
done

echo "Cleaning up..."
remove_error_file
rm -rf $localdir
exit $exit_code
