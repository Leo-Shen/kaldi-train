# kaldi-train
本文主要介绍使用mini_lirispeech脚本来训练ipad自录的语料。
注：1. 我这次使用ipad自录的16k采样wav格式的语料，可能是由于录音时设置的问题还是什么其它原因，录出的是JUNK格式的wav，即wav头部多了4096个字节，不过还好，最新版本的kaldi已支持JUNK的解析。
    2. wav文件名的格式如：20180410090508_funny_C25C47F7-37BC-4D3A-8B45-63C7987D9556_1_6_1.wav，需把wav文件重命名为格式如：C25C47F7-20180410090508-FUNNY.wav
    3. wav文件名中不能包含特殊字符\'，需直接删除特殊字符，如：20180410085002_I'm_503CD279-8B54-4087-B546-514639CA428D_2_6_1.wav，重命令格式如：503CD279-20180410085002-IM.wav
    4. 由于原生的mini_lirispeech训练脚本，对wav文件的要求是全数字，如果现在想支持包含字母的文件，则需把相关脚本上数字值比较的判断逻辑修改字符串比较的判断逻辑。

数据准备：
1. find train-clean-5/ -name *.wav > train_wav_files.txt #收集训练集的语料
   find dev-clean-2/ -name *.wav > dev_wav_files.txt #收集测试集的语料

2. python rename_moban_wav.py train_wav_files.txt #把训练集的语料重命名，分文件夹，为每个文件夹生成trans.txt。
   python rename_moban_wav.py test_wav_files.txt #把测试集的语料重命名，分文件夹，为每个文件夹生成trans.txt。

3. ./run.sh #开始训练

生成语言模型
1. find train-clean-5/ -name *.trans.txt > trans_files.txt #合并所有train-clean-5目录下的trans.txt文件
2. python combine_train_txt.py trans_files.txt trans.txt #提取所有trans_files.txt中所列文件中的内容到trans.txt中
3. python split2words.py trans.txt > word.txt #提取trans.txt中的单词
4. cat word.txt | sort -u | uniq > word_uniq.txt #对单词唯一并排序
5. python filter_lexicon.py lexicon_full.txt word_uniq.txt lexicon.txt #从大的发音字典中提取指定单词集的发音字典
6. cp word.txt corpus_moban.txt #把word.txt中单词的出现频率当作生成语言模型的参考文本
7. ./make_librispeech_graph.sh #生成HCLG.fst
