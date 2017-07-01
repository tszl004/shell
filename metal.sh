#! /bin/bash
metal=("audjpy audusd chfjpy eurcad eurchf eurgbp eurjpy eurusd gbpchf gbpjpy gbpusd nzdjpy nzdusd usdcad usdchf usdjpy xagusd xauusd")
metalDir="/datadisk/src/jenkins/metal"
for forex in $metal
do
forex=$(echo $forex | tr '[a-z]' '[A-Z]')
    if [ ! -f "$metalDir/$forex.zip" ] ;then
        echo "$forex.zip doesn't exists."
    fi
    echo $forex
    wget -N -P $metalDir  http://www.forextester.com/data/files/$forex.zip
    echo $?
    if [ ! $? ];then
        echo "$forex download false";
    else
        unzip -o $metalDir/$forex.zip -d $metalDir/
    fi
done

for file in $metalDir/*.txt
do
    fileName=${file##*/}
    baseName=${fileName%.*}
    lowName=$(echo $baseName | tr '[A-Z]' '[a-z]')
    total=`wc -l $file | egrep -o "[0-9]+"`
    echo $lowName
    echo "Total:$total."
    date "+%Y_%m_%d %H:%M:%S"
    /usr/local/php/bin/php /datadisk/src/jenkins/php/script/run.php Metal saveBySQLFile file=$file++sqlDir=$metalDir/sql
    date "+%Y_%m_%d %H:%M:%S"
    mysql -umetal -pmetal metal < $metalDir/sql/$lowName.sql
    rm $metalDir/sql/$lowName.sql
    date "+%Y_%m_%d %H:%M:%S"

done
