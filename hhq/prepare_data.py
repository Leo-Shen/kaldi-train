#!/usr/bin/env python
# coding=utf-8
# File Name: prepare_data.py
# Author: Heqing Huang
# Mail: heqing@audvoc.com
# Created Time: Mon Mar 19 12:23:51 2018
# CopyRight: Audvoc 2018

import sys
import os
import re
import subprocess

reload(sys)
sys.setdefaultencoding('utf8')

usage = """ That script is used for generate text/wav.scp/utt2spk file for kaldi feature extraction.
    Usage:
        ./prepare_data.py wave_data_path text_result_path
    """
if len(sys.argv) is not 3:
    print usage
    exit();

text = open(sys.argv[2] + "/text", 'w')
wav_scp = open(sys.argv[2] + "/wav.scp",'w')
utt2spk = open(sys.argv[2] + "/utt2spk", 'w')

#save the files absolute path in wave_data_path
temp_file = open("temp.txt", 'wr')

wav_file_list = subprocess.Popen(["find",sys.argv[1],"-name","*.wav"],stdout=subprocess.PIPE)
files = wav_file_list.stdout.read()
temp_file.write(files)
temp_file.close()

temp_file = open("temp.txt")
print "==============Generate text/utt2spk/wav.scp============="
lines = temp_file.readlines()
lines.sort()
for line in lines:
    filename = line[line.rfind("/") + 1:]

    str_list = line.strip().split("_")
    #generate utt_id
    utterance_id = str_list[1] + "_" + str_list[2] + "_" + str_list[3] + "_" + str_list[4].split(".")[0]
    #generate content
    pattern = re.compile('.{1,1}')
    utterance_content = ' '.join(pattern.findall(str_list[3]))
    #generate utterance speaker
    utterance_speaker = str_list[1]

    text.write(utterance_id + " " + utterance_content + "\n")
    wav_scp.write(utterance_id + " " + line.strip() + "\n")
    utt2spk.write(utterance_id + " " + utterance_speaker + "\n")


text.close()
wav_scp.close()
utt2spk.close()
temp_file.close()
os.remove("temp.txt")


print "==============Generate Success!============="
    


