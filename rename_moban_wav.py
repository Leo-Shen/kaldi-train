import sys
import os
import os.path
import shutil

# argv[1]: moban wav files name list
for eachline in open(sys.argv[1]):
	tmp_line = eachline.rstrip('\r\t\n ')
        tmp_dir, line = tmp_line.rsplit('/', 1)
        time_name, rest_line = line.split('_', 1)
	word, rest2_line = rest_line.split('_', 1)
	s_id = rest2_line.split('-', 1)[0]
	target_dir = tmp_dir + '/' + s_id
        print s_id + ' ' + time_name + ' ' + word
	if not os.path.exists(target_dir):
        	os.makedirs(target_dir)
	if (-1 == word.find('\'')):
	    word_ignore_accent_sign = word
	else:
	    word_ignore_accent_sign = word.split('\'', 1)[0] + word.split('\'', 1)[1]
	target_file = target_dir + '/' + s_id + '-' + time_name + '-' + word_ignore_accent_sign.upper() + '.wav'
	shutil.copy(tmp_line, target_file)
	trans_file = target_dir + '/' + s_id + '.trans.txt'
	trans_line = s_id + '-' + time_name + '-' + word_ignore_accent_sign.upper() + ' ' + word.upper() + '\n'
        open(trans_file, "a").write(trans_line)


