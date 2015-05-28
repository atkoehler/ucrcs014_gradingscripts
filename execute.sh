#!/bin/bash

FILES="files"
WORKING="working"
OUTPUT="output"
MARKING_KEY="marking"
STOP_ON_ERROR=0
DIVIDER="############################################################"

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
        mv "$filename" $FILES/$new_dir/ &>/dev/null
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


echo "Creating marking files for each student submission."
for d in ${FILES}/*/; do
    # generate a file called username_marking_timestamp.txt
    username=$(basename ${d})

    # grab text file for submission
    textfilepath=$(ls ${d}*.txt)
    
    # get the file name
    file_name=$(basename "$textfilepath")

    # split the file name on the underscore delimiter
    OLDIFS=$IFS
    IFS='_'
    file_array=( $file_name )
    IFS=$OLDIFS
    
    pieces=${#file_array[@]}
    timestamp=${file_array[$pieces-1]}
    timestamp="${timestamp%.*}"
    assignment_name=${file_array[0]}

    marking_file="${username}_${MARKING_KEY}_${timestamp}.txt"
    echo -ne "" > ${OUTPUT}/student_results/${marking_file}

    # append file information to the top of the marking file
    echo ${DIVIDER} >> ${OUTPUT}/student_results/${marking_file}
    echo "# " >> ${OUTPUT}/student_results/${marking_file}
    echo "# Username:   $username" >> ${OUTPUT}/student_results/${marking_file}
    echo "# Timestamp:  $timestamp" >> ${OUTPUT}/student_results/${marking_file}
    echo "# Assignment: $assignment_name" >> ${OUTPUT}/student_results/${marking_file}
    echo "# Files In Submission: " >> ${OUTPUT}/student_results/${marking_file}
    for f in ${d}*; do
        fname=$(basename "${f}")
        echo "#    $fname" >> ${OUTPUT}/student_results/${marking_file}
    done
    echo "# " >> ${OUTPUT}/student_results/${marking_file}
    echo ${DIVIDER} >> ${OUTPUT}/student_results/${marking_file}

    # append contents found in header file
    echo ${DIVIDER} >> ${OUTPUT}/student_results/${marking_file}
    echo "# " >> ${OUTPUT}/student_results/${marking_file}
    echo "# Student .H code: " >> ${OUTPUT}/student_results/${marking_file}
    echo "" >> ${OUTPUT}/student_results/${marking_file}

    # TODO: handle more than one header?
    header_file=$(find ${d} -regex '.*/.*\.\(h\|H\|hpp\|HPP\)$')
    if [ "$header_file" = "" ]
    then
        echo "NO FILE FOUND" >> ${OUTPUT}/student_results/${marking_file}

    else
        cat "${header_file}" >> ${OUTPUT}/student_results/${marking_file}
        echo "" >> ${OUTPUT}/student_results/${marking_file}
    fi
    echo "" >> ${OUTPUT}/student_results/${marking_file}
    echo ${DIVIDER} >> ${OUTPUT}/student_results/${marking_file}


    # append compilation results with harness
    echo ${DIVIDER} >> ${OUTPUT}/student_results/${marking_file}
    echo "# " >> ${OUTPUT}/student_results/${marking_file}
    echo "# Compilation results with harness: " >> ${OUTPUT}/student_results/${marking_file}


    echo "" >> ${OUTPUT}/student_results/${marking_file}
    echo ${DIVIDER} >> ${OUTPUT}/student_results/${marking_file}


    # append compilation results with student provided .cpp
    echo ${DIVIDER} >> ${OUTPUT}/student_results/${marking_file}
    echo "# " >> ${OUTPUT}/student_results/${marking_file}
    echo "# Compilation results with student provided file: " >> ${OUTPUT}/student_results/${marking_file}

    
    echo "" >> ${OUTPUT}/student_results/${marking_file}
    echo ${DIVIDER} >> ${OUTPUT}/student_results/${marking_file}

    # append execution result
done


# clean up by removing unpacked files
rm -rf ${FILES}/*/
