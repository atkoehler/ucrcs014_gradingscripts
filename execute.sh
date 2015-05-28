#!/bin/bash

SOLUTION="solution"
FILES="files"
WORKING="working"
OUTPUT="output"
MARKING_KEY="marking"
EXE_NAME="student_executable"
STOP_ON_ERROR=0
DIVIDER="############################################################"
FILE_KBYTES=2048

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
echo "Copying student files into files directory."
for filename in ${WORKING}/*
do
    new_dir=$(ls -1 "$filename" | grep '[^_][A-Za-z]*[^_][0-9]\{3\}' -o)
    mkdir ${FILES}/${new_dir} &>/dev/null  
    
    if [[ "$filename" =~ \.tar$  ]];
    then
        tar -xvf "$filename" -C $FILES/$new_dir/ &>/dev/null
    elif [[ "$filename" =~ \.zip$  ]];
    then
        unzip "$filename" -d $FILES/$new_dir/ &>/dev/null
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
    echo "   Working on $username"

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
    # find .h/.H/.hpp/.HPP files that are not hidden files
    header_file=$(find ${d} \( ! -regex '.*/\..*' \) -regex '.*/.*\.\(h\|H\|hpp\|HPP\)$')

    # if no header, output nothing found otherwise continue with tests
    if [ "$header_file" = "" ]
    then
        echo "NO FILE FOUND" >> ${OUTPUT}/student_results/${marking_file}
        echo "" >> ${OUTPUT}/student_results/${marking_file}
        echo ${DIVIDER} >> ${OUTPUT}/student_results/${marking_file}
    else
        cat "${header_file}" >> ${OUTPUT}/student_results/${marking_file}
        echo "" >> ${OUTPUT}/student_results/${marking_file}
        echo "" >> ${OUTPUT}/student_results/${marking_file}
        echo ${DIVIDER} >> ${OUTPUT}/student_results/${marking_file}




        # append compilation results with harness
        echo ${DIVIDER} >> ${OUTPUT}/student_results/${marking_file}
        echo "# " >> ${OUTPUT}/student_results/${marking_file}
        echo "# Compilation results with harness: " >> ${OUTPUT}/student_results/${marking_file}

        # make working directory 
        mkdir ${WORKING}
        
        # copy header file to working directory
        cp "$header_file" "${WORKING}/assn.h"

        # copy solution harness into working
        cp ${SOLUTION}/* ${WORKING}/

        # compile harness and output the results 
        g++ -std=c++11 ${WORKING}/main.cpp -o "${WORKING}/${EXE_NAME}_harness_${timestamp}.out" &>> ${OUTPUT}/student_results/${marking_file}

        compile_success_harness=$(ls "${WORKING}/${EXE_NAME}_harness_${timestamp}.out" 2>/dev/null)
        if [ "$compile_success_harness" = "" ]
        then
            # remove working directory and its contents
            rm -rf ${WORKING}

            # output divider to end harness compilation
            echo "" >> ${OUTPUT}/student_results/${marking_file}
            echo ${DIVIDER} >> ${OUTPUT}/student_results/${marking_file}



            # append compilation results with student provided .cpp
            echo ${DIVIDER} >> ${OUTPUT}/student_results/${marking_file}
            echo "# " >> ${OUTPUT}/student_results/${marking_file}
            echo "# Compilation results with student provided file: " >> ${OUTPUT}/student_results/${marking_file}


            # copy student provided C++ harness into working
            studentCPP_file=$(find ${d} \( ! -regex '.*/\..*' \) -regex '.*/.*\.\(cc\|cpp\)$')

            # if no student C++ file found
            if [ "$studentCPP_file" = "" ]
            then
                echo "NO STUDENT C++ FILE FOUND" >> ${OUTPUT}/student_results/${marking_file}
                echo "" >> ${OUTPUT}/student_results/${marking_file}
                echo ${DIVIDER} >> ${OUTPUT}/student_results/${marking_file}
            else
                # remake the working directory
                mkdir ${WORKING}
            
                header_file_base=$(basename "$header_file")
                # extract true file name from mangled iLearn file name
                OLDIFS=$IFS
                IFS='_'
                header_name_array=( $header_file_base )
                IFS=$OLDIFS

                header_pieces=${#header_name_array[@]}
                true_name=${header_name_array[$header_pieces-1]}
    
                # copy header and student C++ file to working directory
                cp "$header_file" "${WORKING}/${true_name}"
                cp "$studentCPP_file" "${WORKING}/main.cpp"
                # compile harness and output the results 
                g++ -std=c++11 ${WORKING}/main.cpp -o "${WORKING}/${EXE_NAME}_student_${timestamp}.out" &>> ${OUTPUT}/student_results/${marking_file}
                
                compile_success_student=$(ls "${WORKING}/${EXE_NAME}_student_${timestamp}.out" 2>/dev/null)

                # if student version didn't compile then we are done
                if [ "$compile_success_student" = "" ]
                then 
                    # remove working directory and its contents
                    rm -rf ${WORKING}

                    # output divider to end student compilation
                    echo "" >> ${OUTPUT}/student_results/${marking_file}
                    echo ${DIVIDER} >> ${OUTPUT}/student_results/${marking_file}
                    continue
                fi

                # execute student version and output the results
                echo ${DIVIDER} >> ${OUTPUT}/student_results/${marking_file}
                echo "# " >> ${OUTPUT}/student_results/${marking_file}
                echo "# Execution output of student program (solution harness did not compile):" >> ${OUTPUT}/student_results/${marking_file}
                echo "" >> ${OUTPUT}/student_results/${marking_file}
                python run_file.py ${WORKING}/${EXE_NAME}_student_${timestamp}.out tmpfile.txt >> tmpfile2.txt
                cat tmpfile.txt | head -c $FILE_KBYTES >> ${OUTPUT}/student_results/${marking_file} >> ${OUTPUT}/student_results/${marking_file}
                cat tmpfile2.txt | head -c $FILE_KBYTES >> ${OUTPUT}/student_results/${marking_file} >> ${OUTPUT}/student_results/${marking_file}

                rm tmpfile.txt
                rm tmpfile2.txt
                echo "" >> ${OUTPUT}/student_results/${marking_file}
                echo ${DIVIDER} >> ${OUTPUT}/student_results/${marking_file}
           
                # remove working directory and its contents
                rm -rf ${WORKING}
            fi
        else
            # append execution result
            # execute harness version and output the results
            echo ${DIVIDER} >> ${OUTPUT}/student_results/${marking_file}
            echo "# " >> ${OUTPUT}/student_results/${marking_file}
            echo "# Execution output of harness program:" >> ${OUTPUT}/student_results/${marking_file}
            echo "" >> ${OUTPUT}/student_results/${marking_file}
            python run_file.py ${WORKING}/${EXE_NAME}_harness_${timestamp}.out tmpfile.txt >> tmpfile2.txt
            cat tmpfile.txt | head -c $FILE_KBYTES >> ${OUTPUT}/student_results/${marking_file} >> ${OUTPUT}/student_results/${marking_file}
            cat tmpfile2.txt | head -c $FILE_KBYTES >> ${OUTPUT}/student_results/${marking_file} >> ${OUTPUT}/student_results/${marking_file}

            rm tmpfile.txt
            rm tmpfile2.txt
            echo "" >> ${OUTPUT}/student_results/${marking_file}
            echo ${DIVIDER} >> ${OUTPUT}/student_results/${marking_file}
            # remove working directory and its contents
            rm -rf ${WORKING}
        fi
    fi
done


# clean up by removing unpacked files
rm -rf ${FILES}/*/
