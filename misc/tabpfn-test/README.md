To Hui:

Would something like this work for you?

I successfully ran the default example of TabPFN with the execute_command_line
in Fortran. By default it waits for the execution of the external command and
I think that is what is needed with this. 

I encapsulated the TabPFN stuff inside bash script to make it simpler to handle.

"extra_info" is just there to remind that you could send parameters from fortran to
modify the execution of the bash script and the python scripts.

This bash script creates a log file and append the runs output to it

Following are the used files and their output...

main.f90:
´´´
program test_exec
  integer :: i

  call execute_command_line ("bash start.sh extra_info", exitstat=i)
  print *, "Exit status of 'bash start.sh' was ", i

  !call execute_command_line ("reindex_files.exe", wait=.false.)
  !print *, "Now reindexing files in the background"

end program test_exec
´´´

start.sh:
´´´
#! /bin/env bash

# Setting pipefail to stop the script when this script or python fails.
# Exits with error that the fortran sees the errors.
set -euo pipefail

# Necessary paths and filenames
MAIN_PATH=/home/varjonen/repositories/tabpfn-test
PYTHON_ENV_PATH=/home/varjonen/python-env-yleinen
LOG_NAME=tabpfn.log
PYTHON_SCRIPT=test-classify.py

# TabPFN related env variables
# Remember to "pip3 install TabPFN" for the environment.
TABPFN_MODEL_CACHE_DIR=/home/varjonen/Downloads/tabpfnmodels/

# Create an account to huggingface.co
# Remember to accept terms in https://huggingface.co/Prior-Labs/tabpfn_2_5
# Create the token for the reading in https://huggingface.co/settings/tokens
# Only needs "Read access to contents of all public gated repos you can access"
# in the repositories category
HF_TOKEN=hf_addyourown

# Export env things
export TABPFN_MODEL_CACHE_DIR=$TABPFN_MODEL_CACHE_DIR
export HF_TOKEN=$HF_TOKEN

# Activate env
source $PYTHON_ENV_PATH/bin/activate

# Append time when script started to the log file
echo "### ### $(date) ### ###" >> $MAIN_PATH/$LOG_NAME
# Note about extra info given from the fortran...
# ... this could be easily used to change the behaviour of the python script if needed
echo " Given parameter... $1" >> $MAIN_PATH/$LOG_NAME

# Print scripts output to stdout and also append it to the log file
$PYTHON_ENV_PATH/bin/python3 $MAIN_PATH/$PYTHON_SCRIPT -o 2>&1 | tee -a $MAIN_PATH/$LOG_NAME

# deactivate env
deactivate
´´´

example-tabpfn.log:
´´´
### ### ma 19.1.2026 14.17.02 +0200 ### ###
 Given parameter... extra_info
/home/varjonen/python-env-yleinen/lib/python3.12/site-packages/tabpfn/validation.py:56: UserWarning: Running on CPU with more than 200 samples may be slow.
Consider using a GPU or the tabpfn-client API: https://github.com/PriorLabs/tabpfn-client
  _validate_num_samples_for_cpu(
ROC AUC: 0.9978173087416785
Accuracy 0.9824561403508771
[W119 14:17:28.985425620 AllocatorConfig.cpp:28] Warning: PYTORCH_CUDA_ALLOC_CONF is deprecated, use PYTORCH_ALLOC_CONF instead (function operator())
´´´

