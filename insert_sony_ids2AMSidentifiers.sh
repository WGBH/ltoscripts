```bash
#!/bin/bash

# read tsv (named csv) files to generate SQL to insert ASSET-LEVEL IDENTIFIER data on AMS.AMERICANARCHIVE.ORG
# Copyright 2015, WGBH Educational Foundation, Media Library & Archives Department, by Kevin Carter



# mysql> describe identifiers;
# +-------------------+--------------+------+-----+---------+----------------+
# | Field             | Type         | Null | Key | Default | Extra          |
# +-------------------+--------------+------+-----+---------+----------------+
# | id                | int(11)      | NO   | PRI | NULL    | auto_increment |
# | assets_id         | int(11)      | NO   | PRI | NULL    |                |
# | identifier        | varchar(255) | NO   | MUL | NULL    |                |
# | identifier_source | varchar(255) | NO   |     | NULL    |                |
# | identifier_ref    | varchar(255) | YES  |     | NULL    |                |
# +-------------------+--------------+------+-----+---------+----------------+

usage() {
echo `basename $0`' /path/to/some/specific-formatted-file.tsv | tee /path/to/ams-specific.sql';
echo;
echo 'read the script for assumptions it makes about the format of the tab-separated values and the SQL output';
}

if [ "$#" -ne 1 ];
then usage;
exit 1;
fi;


OLDIFS=$IFS;
IFS=$(echo -en '\n\b');
tab=`printf %s a | tr a '\t'`;


echo "SET @xguids = '';";
echo "SET @indexids = '';";

# NOTE THE USE OF `grep -v '_' to avoid processing currently-missing items affected by Zend/Google library bugwork

for dataString in `grep '^20' $1  | cut -f2,3 | cut -f3- -d - | grep -v '_' | sed -e "s#\..*$tab#$tab#g" -e "s#_.*$tab#$tab#g"`;
do 
	
	aaguid='cpb-aacip/'$(echo "$dataString" | cut -f1);
	sonyid=$(echo "$dataString" | cut -f2);
# 	echo 'dataString is   '"$dataString";
# 	echo 'sonyid is   '$sonyid;
	echo "SET @aaguid = '$aaguid';";
	echo "SET @assetid = (select assets_id from identifiers where identifier=@aaguid limit 1);";
	echo "SET @xguids = (SELECT IF(@assetid,@xguids,CONCAT(@xguids,',',@aaguid)));";
	echo "SET @indexids = (SELECT IF(@assetid,CONCAT(@indexids,',',@assetid),@indexids));";
	echo "INSERT INTO identifiers (assets_id,identifier,identifier_source) VALUES (@assetid,'$sonyid','Sony Ci');";
	echo;echo '#';echo;

done

nowString=`date +%Y%m%d_%H%M%S`;
echo '# the following requires that the mysql tmp directory exists, has correct permissions and is declared in /etc/my.cnf'
echo "SELECT @xguids INTO OUTFILE '/var/lib/mysql/tmp/sonyci_failures_$nowString.txt';";
echo "SELECT @indexids INTO OUTFILE '/var/lib/mysql/tmp/sonyci_assetids_$nowString.txt';";

IFS=$OLDIFS;

```
