#! /bin/env bash

# Setting pipefail to stop the script when this script or python fails.
# Exits with error that the fortran script sees.
set -euo pipefail

# Necessary paths and filenames
MAIN_PATH=/home/varjonen/repositories/tabpfn-test
PYTHON_ENV_PATH=/home/varjonen/python-env-yleinen
LOG_NAME=tabpfn.log
PYTHON_SCRIPT=test-classify.py

# TabPFN related env variables
# Remember to "pip3 install TabPFN" for the environment.
TABPFN_MODEL_CACHE_DIR=/home/varjonen/Downloads/tabpfnmodels/

# Create an account in huggingface.co
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
