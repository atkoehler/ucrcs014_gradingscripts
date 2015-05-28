# UCR CS014 Grading Scripts

If you want the script to stop on errant submissions, change the flag at the top of execute.sh to 1. Otherwise the script will continue running.

To keep the unpacked files once done, comment out the last line in execute.sh script.

To execute simply type ./execute.sh zips/hw1.zip where hw1.zip is the iLearn downloaded zip file containing all the student submissions.

The script will go through the following process and create marking files for each student.
* Unpack the iLearn zip and unzip any student zips or untar tar balls placing the files into the files directory under a directory with the user's username as its name
* Create a marking file for each student in output/student\_results
* Attempt compilation and report results to marking file 
* If compilation was successful with the harness then run and report output and results. 
* If harness compilation failed, but student provided a harness and that compiled then report those execution results. So the only time the student's provided harness (which is optional submission) is executed is when the the student's header does not compile with the solution harness.
