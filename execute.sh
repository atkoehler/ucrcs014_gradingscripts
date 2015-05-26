#!/bin/bash

FILES="files"
WORKING="working"
OUTPUT="output"
STOP_ON_ERROR=1

if [ "$1" == "--help" ]
then
    echo "Specify the path to the zip file when executing."
    echo "   ./execute ~/zips/assn1.zip"
    exit 1
fi

if [ "$#" = 0 ]
then
    echo "Specify the path to the zip file when executing."
    echo "   ./execute ~/zips/assn1.zip"
    exit 1
fi


mkdir ${WORKING}

# Unpack, rename, and relocate files
zipLoc=$1
echo "Unpacking zipped submissions to ${WORKING}/unpacked."
unzip "${zipLoc}" -d ${WORKING} &>/dev/null


echo "Renaming and moving student files into student specific directories."
# loop over all the .txt files in the working directory
# shopt -s nullglob
# example_file=$(ls -1 ${WORKING}/* | head -n 1)

# # get the file name
# file_name=$(basename "$example_file")

# # split the file name on the underscore delimiter
# OLDIFS=$IFS
# IFS='_'
# file_array=( $file_name )
# IFS=$OLDIFS

# first_remove="${file_array[0]}_"
# second_remove="${file_array[2]}_"



# rename "${first_remove}" "" ${WORKING}/*
# rename "${second_remove}" "" ${WORKING}/*
# echo $first_remove
# echo $second_remove
# exit 1

echo "Copying student files into files directory."
for filename in ${WORKING}/*
do
    new_dir=$(ls -1 "$filename" | grep '[^_][A-Za-z]*[^_][0-9]\{3\}' -o)
    mkdir ${FILES}/${new_dir} &>/dev/null  
    
    if [[ "$filename" =~ \.tar$  ]];
    then
        tar -xvf "$filename" -C $FILES/$new_dir/ &>/dev/null
    elif [[ "$filename" =~ \.tar.gz$  ]];
    then
        tar -zxvf "$filename" -C $FILES/$new_dir/ &>/dev/null
    elif [[ "$filename" =~ \.tgz$  ]];
    then
        tar -zxvf "$filename" -C $FILES/$new_dir/ &>/dev/null    
    elif [[ "$filename" =~ \.h|.H$  ]];
    then
        mv "$filename" $FILES/$new_dir/assn.hpp &>/dev/null
    else
        mv "$filename" $FILES/$new_dir/ &>/dev/null
    fi
done



rm -rf ${WORKING}


echo "Determining errrant submissions (only a text file in submission)."
echo -ne "" > ${OUTPUT}/errant_submissions.txt
for d in ${FILES}/*/; do
    #grab potential errant submissions
    num_files=$(ls -1 ${d} | wc -l)
    if [ "$num_files" = 1 ]
    then
        username=$(basename ${d})
        echo "   Found errant submission: $username"
        echo "$username" >> ${OUTPUT}/errant_submissions.txt
    fi
done


num_errs=$(cat ${OUTPUT}/errant_submissions.txt | wc -l)
if [ "$num_errs" -ne 0 ]
then
    echo "Errors found."
    if [ "$STOP_ON_ERROR" = 1 ]
    then
        exit 1
    fi
else
    rm ${OUTPUT}/errant_submissions.txt
fi


echo "Creating marking files."


rm -rf ${FILES}/*/
