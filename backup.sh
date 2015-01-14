set -e

PKG_OK=$(dpkg-query -W --showformat='${Status}\n' zbackup|grep "install ok installed")
export RBENV_ROOT=/home/ubuntu/.rbenv
export PATH=$RBENV_ROOT/bin:$PATH

eval "$(rbenv init -)"

if [ "" == "$PKG_OK" ]; then
  echo "No zbackup. Setting up zbackup."
  sudo apt-get update
  sudo apt-get --force-yes --yes install zbackup
fi

BACKUPDIR="/mnt/backup"

if [ ! -d "$BACKUPDIR" ]; then
	echo "Backup directory doesn't exist"
	exit 1
fi	

if [ ! -w "$BACKUPDIR" ]; then
	echo "Directory not writeable"
	exit 1
fi	

cd /var/www/faims
rake modules:archive

if [ ! -z "$1" ]; then
	targetPath="$1"
else
	targetPath="."	
fi


for oldBak in $(find $1 -name "*.tar.bz2")
do
	moduleName=$(echo "$oldBak" | gawk 'match($0, /-[A-Za-z]{3,3}-(.*.tar.bz2$)/, a) {print a[1]}')
	find $1 -name "*$moduleName" | sort -gr | tail --lines=+2 | xargs rm -f
done	

for tarball in $(find /var/www/faims/modules -name "*.tar.bz2")
do
	if [ -z "$2" ]; then
		maxDate=$(tar -jtvf $tarball | awk '\
	BEGIN {FS=" "; \
		   maxDate="1970-01-01"; } \
	/[0-9-]{10,10}/	{if ($4 > maxDate) {maxDate = $4} } \
	END {print maxDate} \
	')
	else
		maxDate=$2
	fi
	

	tarballName=$(echo $tarball | awk '\
	              BEGIN {FS="/"} \
	              {print $8}' )

	tarFullName=$(date --date="$maxDate" "+FAIMS2ModuleBackup-%Y%m%d-D%j-%a-$tarballName")
	
	echo "rsync -az $tarball $targetPath/$tarFullName" | bash
	echo "Backed up $tarballName from $maxDate."	

done	