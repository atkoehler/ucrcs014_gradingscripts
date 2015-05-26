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
shopt -s nullglob
example_file=$(ls -1 ${WORKING}/* | head -n 1)

# get the file name
file_name=$(basename "$example_file")

# split the file name on the underscore delimiter
OLDIFS=$IFS
IFS='_'
file_array=( $file_name )
IFS=$OLDIFS

first_remove="${file_array[0]}_"
second_remove="${file_array[2]}_"

rename "$first_remove" "" ${WORKING}/*
rename "$second_remove" "" ${WORKING}/*

echo "Copying student files into files directory."
# copy the student files into specific directories
for f in ${WORKING}/*.txt; do
    # get the file name
    file_name=$(basename "$f")

    # split the file name on the underscore delimiter
    OLDIFS=$IFS
    IFS='_'
    file_array=( $file_name )
    IFS=$OLDIFS

    username="${file_array[0]}"
    mkdir ${FILES}/${username}
    cp ${WORKING}/${username}* ${FILES}/${username}
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
fi


echo "creating marking files"


rm -rf ${FILES}/*/
