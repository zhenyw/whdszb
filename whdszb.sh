#!/bin/bash

help()
{
    echo "$0 -m month [-d day] [-y year]"
    echo ""
    echo "Get Wenhui reading weekly. At least need to specify month to"
    echo "get all issues in that month for current year. Or specify day"
    echo "and year to get specific issues."
    exit 0
}

while getopts m:d:y:h options
do
    case $options in
	m) month=$OPTARG;;
	d) day=$OPTARG;;
	y) year=$OPTARG;;
	h) help;;
    esac
done

[ -z $month ] && help

month=$(printf "%02d" $month)

if [ -z $year ]
then
    year=$(date +%Y)
fi

if [ -z $day ]
then
    MONTHLY=1
    TARGET_DIR=$year-$month
else
    MONTHLY=0
    day=$(printf "%02d" $day)
    TARGET_DIR=$year-$month-$day
fi

echo "check $year $month $day"

# $1 : year
# $2 : month
# $3 : day
# $4 : page index
get_one_pdf()
{
    wget -q "http://wenhui.news365.com.cn/resfiles/$1-$2/$3/wh${1:2:2}$2$3$4.pdf"
    if [ $? -eq 0 ]
    then
	echo "got wh${1:2:2}$2$3$4.pdf"
	return 0
    else
	echo "error to get wh${1:2:2}$2$3$4.pdf"
	return 1
    fi
}

# $1 : year
# $2 : month
# $3 : day
# return:
# 1 : no valid issue found
# 2 : may not be correct reading weekly issue
# 0 : possibly found issue
get_one_day()
{
    NOTFULL=0

    get_one_pdf $1 $2 $3 "09"

    if [ $? -ne 0 ]
    then
	return 1
    else
	for i in {10..16}
	do
	    get_one_pdf $1 $2 $3 "$i"
	    if [ $? -ne 0 ]
	    then
		NOTFULL=1
		break
	    fi
	done
    fi

    if [ $NOTFULL -eq 1 ]
    then
	echo "wh-$1-$2-$3.pdf may not be reading weekly!"
	pdftk `ls *` output wh-$1-$2-$3.pdf

	if [ $? -eq 0 ]
	then
	    rm -rf wh${1:2:2}*
	fi
        return 2
    else
	echo "whdszb-$1-$2-$3.pdf generated"
	pdftk `ls *` output whdszb-$1-$2-$3.pdf
	
	if [ $? -eq 0 ]
	then
	    rm -rf wh${1:2:2}*.pdf
	fi
    fi

    return 0
}

if [ $MONTHLY -eq 0 ]
then
    TARGET_DIR=$year-$month-$day
    mkdir -p $TARGET_DIR
    cd $TARGET_DIR
    get_one_day $year $month $day
    if [ $? -eq 1 ]
    then
	cd ..
	rm -rf $TARGET_DIR
	echo "no valid issue found"
	exit 1
    fi
else
    TARGET_DIR=$year-$month
    mkdir -p $TARGET_DIR
    cd $TARGET_DIR
    
    for i in {01..31}
    do
	mkdir $i
	cd $i
	get_one_day $year $month $i
	ret=$?
	cd ..
	if [ $ret -eq 1 ]
	then
	    rm -rf $i
	fi
    done
fi
