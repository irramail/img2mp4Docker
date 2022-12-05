#!/bin/bash
MP4COUNTER=0
while :;
do
keym4a=$(redis-cli keys "m4a")
for key in $keym4a
do
if  [[ "$key" == "m4a" ]]
then
  redis-cli get m4a | sed "s/|/\n/g" | sed "s/^.*,//" >  linesM4a.b64
  for  i in `cat linesM4a.b64`; do echo $i | base64 -d > m4a/hi.mp3; done
  redis-cli del m4a
  redis-cli set stext ""
fi
done

keytext=$(redis-cli keys "text")
for key in $keytext
do
if  [[ "$key" == "text" ]]
then
  COUNTER=0
  BTEXT=`redis-cli get text`
  rm -f TEXT_*
  redis-cli get text | sed "s/|/\n/g" | sed "s/ /_/g" >  lines.txt
  sed -i "s/^---.*$//g" lines.txt
  sed -i "s/\[\[.*\]\]//" lines.txt
  sed -i "/^$/d" lines.txt
  for  i in `cat lines.txt`; do let COUNTER=$COUNTER+1; echo $i | sed "s/_/ /g" > TEXT_"$COUNTER"; done
  redis-cli set btext "$BTEXT"
  redis-cli del text
fi
done

keybgcount=$(redis-cli keys "bgcounter")
for key in $keybgcount
do
if [[ "$key" == "bgcounter" ]]
then
color=`redis-cli get color`
rm -f canvas.jpg
convert -background "$color"ff -fill white -gravity center -geometry +0+0 -size 1920x1080  caption:" " ~/blank1920x1080.jpg +swap -gravity south -composite ~/canvas.jpg

redis-cli set svg ""

count=`redis-cli get bgcounter`
for i in `seq 1 $count`
do
redis-cli append svg `base64 canvas.jpg | tr -d '\n'`
if [ "$i" -ne "$count" ]
then
redis-cli append svg "|"
fi
done

redis-cli del bgcounter
fi
done

keysvg=$(redis-cli keys "svg")
for key in $keysvg
do
if  [[ "$key" == "svg" ]]
then
  ypercent=`redis-cli get ypercent`
  color=`redis-cli get color`
  ZERO="0"
  COUNTER=0
  redis-cli get svg | sed "s/|/\n/g" | sed "s/^.*,//" >  lines.b64
  wc -l lines.b64
  #for  i in `cat lines.b64`; do let COUNTER=$COUNTER+1; test $COUNTER -gt 9 && ZERO=''; echo $i | base64 -d > f_"$ZERO$COUNTER".jpg; done
  for  i in `cat lines.b64`;
  do
    let COUNTER=$COUNTER+1; test $COUNTER -gt 9 && ZERO=''; echo $i | base64 -d > tmp_f_"$ZERO$COUNTER".jpg;
    #rotate
    isexifrotate=""
    isexifrotate=`identify -format '%[orientation]' tmp_f_"$ZERO$COUNTER".jpg`
    echo isexif
    echo $isexifrotate
    echo isexifend
    if [ "$isexifrotate" == "RightTop" ] 
    then
	convert  ~/tmp_f_"$ZERO$COUNTER".jpg -rotate 90 ~/rotate_tmp_f_"$ZERO$COUNTER".jpg
	 mv -f ~/rotate_tmp_f_"$ZERO$COUNTER".jpg ~/tmp_f_"$ZERO$COUNTER".jpg
    fi
    if [ "$isexifrotate" == "LeftBottom" ] 
    then
	convert  ~/tmp_f_"$ZERO$COUNTER".jpg -rotate 270 ~/rotate_tmp_f_"$ZERO$COUNTER".jpg 
	mv -f ~/rotate_tmp_f_"$ZERO$COUNTER".jpg ~/tmp_f_"$ZERO$COUNTER".jpg
    fi
#BottomRight
    if [ "$isexifrotate" == "BottomRight" ]
    then
        convert  ~/tmp_f_"$ZERO$COUNTER".jpg -rotate 180 ~/rotate_tmp_f_"$ZERO$COUNTER".jpg
        mv -f ~/rotate_tmp_f_"$ZERO$COUNTER".jpg ~/tmp_f_"$ZERO$COUNTER".jpg
    fi

    TEXT=""
    if [ -f TEXT_"$COUNTER" ]
    then
	TEXT=`cat TEXT_"$COUNTER"`
	LENGTH=0;
	FIRST_SIGN="|"
	LENGTH=`echo $TEXT | sed "s/ //g" | wc -c`
	test "$LENGTH" -gt "1" && FIRST_SIGN=`echo $TEXT | head -c 1`
	test "$FIRST_SIGN" == "~" && LENGTH=0
	echo $LENGTH
    #test -f TEXT_"$COUNTER" && convert -background '#00000080' -fill white -pointsize 200 label:"$TEXT" miff:-  | composite -gravity south -geometry +0+400 - ~/tmp_f_"$ZERO$COUNTER".jpg ~/f_"$ZERO$COUNTER".jpg || mv ~/tmp_f_"$ZERO$COUNTER".jpg ~/f_"$ZERO$COUNTER".jpg
    if [ "$LENGTH" -gt "1" ]
    then
    echo more
    width=`identify -format %w ~/tmp_f_"$ZERO$COUNTER".jpg`; height=`identify -format %h ~/tmp_f_"$ZERO$COUNTER".jpg`; convert -background '#0008' -fill white -font Roboto-Condensed-Regular -gravity center -geometry +0+$[height*ypercent/100-height/20] -size $[width-width/10]x$[height/10]  caption:"$TEXT" ~/tmp_f_"$ZERO$COUNTER".jpg +swap -gravity south -composite ~/f_"$ZERO$COUNTER".jpg
	else
		mv ~/tmp_f_"$ZERO$COUNTER".jpg ~/f_"$ZERO$COUNTER".jpg
    fi
	else
		mv ~/tmp_f_"$ZERO$COUNTER".jpg ~/f_"$ZERO$COUNTER".jpg
    fi
    #sleep 1

    let width2=`identify -format %w ~/f_"$ZERO$COUNTER".jpg`
    let height2=`identify -format %h ~/f_"$ZERO$COUNTER".jpg`

    if [ "$COUNTER" -gt "1" ]
    then
      #let width2=`identify -format %w ~/f_"$ZERO$COUNTER".jpg`
      #let height2=`identify -format %h ~/f_"$ZERO$COUNTER".jpg`
      ls *.jpg
      let widthFirst=`identify -format %w ~/f_cropWH_01.jpg`
      let heightFirst=`identify -format %h ~/f_cropWH_01.jpg`
      test $height2 -gt $heightFirst && height2=$heightFirst
      test $width2 -gt $widthFirst && width2=$widthFirst
      #convert ~/f_"$ZERO$COUNTER".jpg -resize 1280x1280\> -size 1280x1280 xc:blue +swap -gravity center  -composite ~/ff_"$ZERO$COUNTER".jpg
      #color=`redis-cli get color`
      convert  ~/f_"$ZERO$COUNTER".jpg -resize "$width2"x"$height2>" -gravity center -background "$color"ff -extent "$widthFirst"x"$heightFirst" ~/ff_"$ZERO$COUNTER".jpg
      mv -f ~/ff_"$ZERO$COUNTER".jpg ~/f_"$ZERO$COUNTER".jpg
    fi

    echo ~/f_"$ZERO$COUNTER".jpg
    identify ~/f_"$ZERO$COUNTER".jpg
    echo $width2 $height2,  firstwidth: $widthFirst, firstheight: $heightFirst
    echo bla bla bla

    identify ~/f_"$ZERO$COUNTER".jpg
    #test $[height2 % 2] -eq 1 && convert ~/f_"$ZERO$COUNTER".jpg -crop ${width2}x$[height2-1]+0+0 ~/f_cropH_"$ZERO$COUNTER".jpg || mv ~/f_"$ZERO$COUNTER".jpg  ~/f_cropH_"$ZERO$COUNTER".jpg
    test $[heightFirst % 2] -eq 1 && convert ~/f_"$ZERO$COUNTER".jpg -crop ${widthFirst}x$[heightFirst-1]+0+0 ~/f_cropH_"$ZERO$COUNTER".jpg || mv ~/f_"$ZERO$COUNTER".jpg  ~/f_cropH_"$ZERO$COUNTER".jpg

    identify ~/f_cropH_"$ZERO$COUNTER".jpg
    test $[wsdthFirst % 2] -eq 1 && convert ~/f_cropH_"$ZERO$COUNTER".jpg -crop $[widthFirst-1]x${heightFirst}+0+0 ~/f_cropWH_"$ZERO$COUNTER".jpg || mv ~/f_cropH_"$ZERO$COUNTER".jpg ~/f_cropWH_"$ZERO$COUNTER".jpg

    identify ~/f_cropWH_"$ZERO$COUNTER".jpg

  done
  redis-cli del svg
  width1=`identify -format %w ~/f_cropWH_01.jpg`; height1=`identify -format %h ~/f_cropWH_01.jpg`;
  cp -f ~/f_cropWH_01.jpg ~/res_aaaaaaaaa.jpg
  filenameMp4=OUTPUT_"$RANDOM"_"$MP4COUNTER".mp4

  rm -f ~/m4a/hi.mp4
  ffmpeg -loglevel quiet -y -i ~/m4a/hi.mp3 ~/m4a/hi.mp4
  timeOnSec=`redis-cli get sec`
  ffmpeg -y -r ${timeOnSec} -f image2 -s ${width1}x${height1} -i f_cropWH_%02d.jpg -i ~/m4a/hi.mp4 -vcodec libx264 -b 4M  -acodec copy ~/mp4Downloads/"$filenameMp4"
  #-loglevel quiet
  redis-cli append mp4AllFilenames ",$filenameMp4"
  redis-cli append mp4NewFilenames ",$filenameMp4"
  rm *.jpg
  let MP4COUNTER=$MP4COUNTER+1
fi
done
for i in $(redis-cli get mp4DelFilenames); do   cd mp4Downloads && rm -f $i ; cd ; done
toDel=$(redis-cli get mp4DelFilenames)
test -n "$toDel" &&  redis-cli del mp4DelFilenames
sleep 1;
done
