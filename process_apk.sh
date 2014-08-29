#!/bin/bash

##############################################################################################
# This script analyzes an arbitrary amount of apks by using various tools including          #
# calculating the apk hashes, decompilation into smali files using apktool, decomplilation   #
# into the sources files using dex2jar and JD-core and using yasca to report on the source   #
# files.                                                                                     #
#                                                                                            #
# Instructions:                                                                              #
#  1) Place the desired apks into the place_apks_here folder.                                #
#     Apk names must be have the following structure: clientname_{version#}.apk              #  
#     E.g. - WeChat_5.0.1.apk                                                                #
#  3) Run process_apk.sh. Depending on the size and the amount of apks, this may take a      #
#     while.                                                                                 #
#                                                                                            #
# Dependencies:                                                                              #
# - dex2jar-0.0.9.15                                                                         #
# - jd-core-java (wrapper for JD to allow command line decompilation)                        #
# - yasca-core-2.21                                                                          #
##############################################################################################

#deobfuscation="$1"

cwd=$(pwd)
count=0
time_start=`date +%s`


#Check if apks exist at all.
if ls $cwd/place_apks_here/*.apk &> /dev/null; 
then

	for f in $cwd/place_apks_here/*.apk; do
		
		#Use for a tally of number of apks analyzed.
		count=$((count+1))
		
		#Get filename and clientname
		filename=$(basename "$f")
		filename="${filename%.*}"
		clientname=`echo "$filename" | cut -d'-' -f1`
		
		echo Current working file: "$filename"
		
	
		#Make the appropriate directories
		mkdir -p $cwd/analyzed_apks2/"$clientname"/"$filename"

		echo Calculating hashes for: "$filename"
		
		echo -n "MD5: " >> "$filename".info.txt
		md5sum $cwd/place_apks_here/"$filename".apk >> "$filename".info.txt
		
		echo -n "SHA1: " >> "$filename".info.txt
		sha1sum $cwd/place_apks_here/"$filename".apk >> "$filename".info.txt
		
		echo -n "SHA256: " >> "$filename".info.txt
		sha256sum $cwd/place_apks_here/"$filename".apk >> "$filename".info.txt
		
		echo -n "SHA512: " >> "$filename".info.txt
		sha512sum $cwd/place_apks_here/"$filename".apk >> "$filename".info.txt
		
		mv "$filename".info.txt $cwd/analyzed_apks2/"$clientname"/"$filename"
		
		
		#Unzip apk
		echo Unzip "$filename".apk
		unzip -u $cwd/place_apks_here/$filename.apk -d $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-unzipped
	
		#Use apktool to get the smali files

		echo Extract smali files from "$filename"
		apktool d -m $cwd/place_apks_here/"$filename".apk
		mv $cwd/"$filename"/ $cwd/analyzed_apks2/"$clientname"/"$filename"/
		mv $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename" $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-smali
		
			
		#Convert classes.dex to jar file with java bytecode, then convert to java source code

		echo Convert classes.dex to jar file
		$cwd/dex2jar-0.0.9.15/d2j-dex2jar.sh $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-unzipped/classes.dex

		read
		
		echo Extract the source from the classes
		java -jar $cwd/jd-core-java/build/libs/jd-core-java-1.2.jar $cwd/classes-dex2jar.jar $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-source
		#java -jar $cwd/procyon-decompiler.jar -jar $cwd/classes-dex2jar.jar -o $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-source
		#rm $cwd/classes-dex2jar.jar
		read

		# Run the deobfuscation commands with dex2jar
		# echo Convert classes.dex to jar file
		# $cwd/dex2jar-0.0.9.15/d2j-dex2jar.sh $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-unzipped/classes.dex
		
		$cwd/dex2jar-0.0.9.15/d2j-init-deobf.sh -f -o init.txt classes-dex2jar.jar
		$cwd/dex2jar-0.0.9.15/d2j-jar-remap.sh -f -c init.txt -o classes-dex2jar-deobf.jar classes-dex2jar.jar
	

		mkdir -p $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-deobfuscation_conversion_file
		mv init.txt $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-deobfuscation_conversion_file
		#java -jar $cwd/jd-core-java/build/libs/jd-core-java-1.2.jar $cwd/classes-dex2jar-deobf.jar $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-deobf-source
		java -jar $cwd/procyon-decompiler.jar -jar $cwd/classes-dex2jar-deobf.jar -o $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-deobf-source
		rm $cwd/classes-dex2jar.jar	
		rm $cwd/classes-dex2jar-deobf.jar


		#LINE contains another dex file which contains npush classes. Extract those too.
		if [ $clientname == "LINE" ]
		then
			
			mkdir -p $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-npush_classes
			unzip $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-unzipped/assets/npush_classes.zip -d $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-npush_classes
			
			echo Convert classes.dex to jar file
			/home/jt/process_apk/dex2jar-0.0.9.15/d2j-dex2jar.sh $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-npush_classes/classes.dex
			mv $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-unzipped/assets/classes-dex2jar.jar /home/jt/process_apk/


			java -jar $cwd/jd-core-java/build/libs/jd-core-java-1.2.jar $cwd/classes-dex2jar.jar $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-npush_classes
			rm $cwd/classes-dex2jar.jar

		fi

		if [ $clientname == "lianwo" ]
		then
			
			mkdir -p $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-npush_classes
			unzip $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-unzipped/assets/npush_classes.zip -d $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-npush_classes
			
			echo Convert classes.dex to jar file
			/home/jt/process_apk/dex2jar-0.0.9.15/d2j-dex2jar.sh $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-npush_classes/classes.dex
			mv $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-unzipped/assets/classes-dex2jar.jar /home/jt/process_apk/


			java -jar $cwd/jd-core-java/build/libs/jd-core-java-1.2.jar $cwd/classes-dex2jar.jar $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-npush_classes
			rm $cwd/classes-dex2jar.jar

		fi
	
		
		#Start using yasca
		if [ ! -d $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-yasca ]
		then
			
			echo Yasca analysis for $filename
			cd $cwd/yasca-core-2.21

			#Pickup necessary plugins
			export SA_HOME=$cwd/yasca-core-2.21/plugins/static-tools/

			./yasca $cwd/analyzed_apks2/"$clientname"/"$filename"
			mv /home/jt/Desktop/Yasca/ $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-yasca
			cd ..
		fi
		
		mv $cwd/place_apks_here/"$filename".apk $cwd/analyzed_apks2/"$clientname"/"$filename"
		rm -rf $cwd/analyzed_apks2/"$clientname"/"$filename"/"$filename"-unzipped
	
	done
	echo ""
	time_end=`date +%s`
	time_exec=`expr $(( $time_end - $time_start ))`
	echo "Process Complete. $count apk(s) processed in $time_exec seconds."


else
    echo "There are no apks in the directory."
fi
