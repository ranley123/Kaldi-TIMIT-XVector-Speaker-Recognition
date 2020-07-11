#coding: utf-8

import os
import shutil
from glob import glob
path = os.getcwd()

# remove other files
def remove_files():
    for root, dirs, files in os.walk(os.path.join(path, "timit_sre")):
        n = 0
        for name in files:
            if(name.endswith(".PHN")):
                os.remove(os.path.join(root, name))
            elif(name.endswith(".TXT")):
                os.remove(os.path.join(root, name))
            elif(name.endswith(".WRD")):
                os.remove(os.path.join(root, name))


def move_files(test_or_train):
    dirs = os.listdir(os.path.join(path, "timit_sre", "wav", test_or_train))
    for dir in dirs:
        for root, dirnames, files in os.walk(os.path.join(path, "timit_sre", "wav", test_or_train, dir)):
            # print(root)
            for name in dirnames:
                old_name = os.path.join(root, name)

                base = root[0: root.rfind('/')]
                new_name = os.path.join(base, name)
                os.rename(old_name, new_name)


def change_folder_name(test_or_train, n):
    for root, dirs, files in os.walk(os.path.join(path, "timit_sre", "wav", test_or_train)):
        prefix = root[:-13]

        for name in dirs:
            old_name = os.path.join(root, name)
            new_dir_name = ""

            if len(str(n)) == 1:
                new_dir_name = "SP000" + str(n)
            elif len(str(n)) == 2:
                new_dir_name = "SP00" + str(n)
            elif len(str(n)) == 3:
                new_dir_name = "SP0" + str(n)

            new_name = os.path.join(root, new_dir_name)
            os.rename(old_name, new_name)
            n += 1

def change_wav_name(test_or_train):
    dirs = os.listdir(os.path.join(path, "timit_sre", "wav", test_or_train))
    for dir_name in dirs:
        for root, dirs, files in os.walk(os.path.join(path, "timit_sre", "wav", test_or_train, dir_name)):
            n = 0
            for name in files:
                new_name = dir_name + "W0" + str(n) + ".wav"
                old_name = os.path.join(root, name)
                new_name = os.path.join(root, new_name)

                os.rename(old_name, new_name)
                n += 1

def nist2wav(src_dir):
    count = 0
    for subdir, _, files in os.walk(src_dir):
        for f in files:
            fullFilename = os.path.join(subdir, f)
            if f.endswith('.wav'):
                count += 1
                os.rename(fullFilename,fullFilename+".WAV")
                os.system("sox "+fullFilename+".WAV"+ " " +fullFilename)
                os.remove(fullFilename+".WAV")
                print(fullFilename)

remove_files()
move_files("train")
move_files("test")
change_folder_name("train", 1)
change_folder_name("test", 463)
change_wav_name("train")
change_wav_name("test")
nist2wav("timit_sre/wav/train")
nist2wav("timit_sre/wav/test")

