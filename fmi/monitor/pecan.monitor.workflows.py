import xml.etree.ElementTree as ET
import os

# Where are the workflows
path = "/data/workflows/"

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def open_xml(path):
  with open(path) as f:
    t = ET.parse(f)
  r = t.getroot()
  return r

def pecan_handle_xml(file_path, file):
  print(f"  - {bcolors.OKGREEN}{file}{bcolors.ENDC}")

  root = open_xml(file_path)
  info = root.find('info')

  # META DATE
  creation_date = info.find('date').text
  print(f"    - creation: {creation_date}")      

  # RUN
  run = root.find('run')
  site = run.find('site')
  if site != None:
    site_id = site.find('id')
    site_id_text = site_id.text
    site_name = site.find('name')
    site_name_text = ""
    if site_name != None:
      site_name_text = f", {site_name.text}"
    print(f"    - site: {site_id_text} {site_name_text}")
    start_date = run.find('start.date')
    end_date = run.find('end.date') 
    print(f"    - run: {start_date.text} - {end_date.text}")

  # MODEL
  model = root.find('model')
  if model == None:
    print(f"    - {bcolors.WARNING}No model section{bcolor.ENDC}")
  else:
    model_type = model.find('type')
    model_type_text = ""
    if model_type != None:
      model_type_text = f", {model_type.text}"
    model_id = model.find('id')
    model_id_text = ""
    if model_id != None:
      model_id_text = f"{model_id.text}"
    model_revision = model.find('revision')
    model_revision_text = ""
    if model_revision != None:
      model_revision_text = f", {model_revision.text}"
    print(f"    - model: {model_id_text}{model_type_text}{model_revision_text}")

def handle_outrun_folder(file_path, file):
  print(f"  - {bcolors.OKGREEN}{file}{bcolors.ENDC} folder")

  out_files = os.listdir(file_path)
  f_count = 0
  for f in out_files:
    f_count = f_count + 1
  print(f"    - #: {f_count}")
  if file == "run" and f_count > 0:
    run_file_path = os.path.join(file_path, "runs.txt")
    if os.path.isfile(run_file_path):
      with open(run_file_path) as f:
        lines = f.readlines()
        print(f"    - runs.txt line #: {len(lines)}")

wfs = sorted(os.listdir(path))

for wf in wfs:
  #'PEcAn_15000008406'

  wf_number = wf.split('_')[1]
  wf_number_short = int(wf_number[3:])
  print(f"{bcolors.HEADER}Workflow:: {wf_number_short}{bcolors.ENDC}")
  wf_path = os.path.join(path, wf)
  files = sorted(os.listdir(wf_path))
  no_known_files = True

  #######################################
  # PECAN.XML
  file = "pecan.xml"
  file_path = os.path.join(wf_path, file)
  if os.path.isfile(file_path):
    no_known_files = False
    pecan_handle_xml(file_path, file)

  #######################################
  # PECAN.CONFIGS.XML
  file = "pecan.CONFIGS.xml"
  file_path = os.path.join(wf_path, file)
  if os.path.isfile(file_path):
    no_known_files = False
    pecan_handle_xml(file_path, file)

  #######################################
  # PECAN.POSTCONFIGS.XML
  file = "pecan.postCONFIGS.xml"
  file_path = os.path.join(wf_path, file)
  if os.path.isfile(file_path):
    no_known_files = False
    pecan_handle_xml(file_path, file)

  #######################################
  # PECAN.CHECKED.XML
  file = "pecan.CHECKED.xml"
  file_path = os.path.join(wf_path, file)
  if os.path.isfile(file_path):
    no_known_files = False
    pecan_handle_xml(file_path, file)

  #######################################
  # PECAN.TRAIT.XML
  file = "pecan.TRAIT.xml"
  file_path = os.path.join(wf_path, file)
  if os.path.isfile(file_path):
    no_known_files = False
    pecan_handle_xml(file_path, file)

  #######################################
  # WORKFLOW.R
  file = "workflow.R"
  file_path = os.path.join(wf_path, file)
  if os.path.isfile(file_path):
    no_known_files = False
    print(f"  - {bcolors.OKGREEN}workflow.R{bcolors.ENDC}")

  #######################################
  # WORKFLOW.ROUT
  file = "workflow.Rout"
  file_path = os.path.join(wf_path, file)
  if os.path.isfile(file_path):
    no_known_files = False
    print(f"    - {bcolors.OKGREEN}{file}{bcolors.ENDC}")
    with open(file_path) as f:
      for line in f.readlines():
        if "Error" in line:
          print(f"      - {bcolors.WARNING}Workflow WARNING{bcolors.ENDC}")
          print(f'        "{line.replace('\n', '')}"')

  #######################################
  # OUT FOLDER
  file = "out"
  file_path = os.path.join(wf_path, file)
  if os.path.isfile(file_path):
    handle_outrun_folder(file_path, file)

  #######################################
  # RUN FOLDER
  file = "run"
  file_path = os.path.join(wf_path, file)
  if os.path.isfile(file_path):
    handle_outrun_folder(file_path, file)

  #######################################
  # ENSEMBLE FILES

  ensemble_count = ensemble_analysis_count = ensemble_output_count = \
  ensemble_samples_count = ensemble_ts_count = ensemble_ts_analysis_count = 0

  for file in files:
    file_path = os.path.join(wf_path, file)

    # ensemble files 
    if "ensemble.analysis" in file[:len("ensemble.analysis")]:
      ensemble_analysis_count = ensemble_analysis_count + 1
      ensemble_count = ensemble_count + 1
    if "ensemble.output" in file[:len("ensemble.output")]:
      ensemble_output_count = ensemble_output_count + 1
      ensemble_count = ensemble_count + 1
    if "ensemble.samples" in file[:len("ensemble.samples")]:
      ensemble_samples_count = ensemble_samples_count + 1
      ensemble_count = ensemble_count + 1
    if "ensemble.ts" in file[:len("ensemble.ts")]:
      ensemble_ts_count = ensemble_ts_count + 1
      ensemble_count = ensemble_count + 1
    if "ensemble.ts.analysis" in file[:len("ensemble.ts.analysis")]:
      ensemble_ts_analysis_count = ensemble_ts_analysis_count + 1
      ensemble_count = ensemble_count + 1

  line = ""
  if ensemble_count  > 0:
    line = line + f"  - {bcolors.OKGREEN}Ensemble{bcolors.ENDC}\n"
    if ensemble_analysis_count > 0:
      line = line + f"    - analysis #: {ensemble_analysis_count}\n"
    if ensemble_output_count > 0:
      line = line + f"    - output #: {ensemble_output_count}\n"
    if ensemble_samples_count > 0:
      line = line + f"    - sample #: {ensemble_samples_count}\n"
    if ensemble_ts_count > 0:
      line = line + f"    - ts #: {ensemble_ts_count}"
    if ensemble_ts_analysis_count > 0:
      line = line + f", ts analysis #: {ensemble_ts_analysis_count}\n"
    else:
      line = line + "\n"
    print(line)
  if no_known_files:
    print(f"{bcolors.WARNING}  - WF did not contain any known configuration files!{bcolors.ENDC}")

