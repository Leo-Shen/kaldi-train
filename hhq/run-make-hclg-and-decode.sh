#!/bin/bash

# File Name: run.sh
# Author: Heqing Huang
# Mail: heqing@audvoc.com
# Created Time: Mon Mar 19 16:08:58 2018
# CopyRight: Audvoc 2018

. ./cmd.sh
. ./path.sh

stage=5
decode_set=test_set

nj=1

data_set=~/data/DataRecorder
data=./data
data_affix=pre_files
dict_file=$data/dict/lexicon.txt
dict=$data/dict
corpus_file=$data/dict/corpus.txt
lm_file=$data/lm/lm.arpa
gzip_lm_file=$data/lm/lm.arpa.gz
graph_dir=$data/graph # output CLG.fst
lang_dir=$data/lang
hclg_graph=exp/hclg
decode_result=exp/decode_result
treedir=$data/tree
librispeech_model=exp/librispeech/lattices
librispeech_phone=./exp/librispeech/phones

mfcc_conf=conf/mfcc_hires.conf
ivector_path=./exp/librispeech/extractor
score_path=./score

#Generate text/utt2spk/wav.scp
if [ $stage -le 0 ]; then
    echo "==============Data Prepare============"
    ./local/prepare_data.py $data_set $data/$data_affix
    if [ "$decode_set" == "test_set" ]; then
        #cp ~/Audvoc/IND/text_train_1_9 $data/$data_affix/text
        ./utils/fix_data_dir.sh $data/$data_affix
    fi

    if [ "$decode_set" == "train_set" ]; then
        #cp ~/Audvoc/IND/text_train $data/$data_affix/text
        ./utils/fix_data_dir.sh $data/$data_affix
    fi
    ./utils/utt2spk_to_spk2utt.pl $data/$data_affix/utt2spk > $data/$data_affix/spk2utt
fi

#Compute Mfcc feature
if [ $stage -le 1 ]; then
    mfccdir=mfcc 
    echo "============Compute Mfcc============="
    steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj --mfcc-config $mfcc_conf $data/$data_affix exp/make_mfcc $mfccdir
    steps/compute_cmvn_stats.sh $data/$data_affix exp/make_mfcc $mfccdir
fi

#Generate LM with Indonesian dict
if [ $stage -le 3 ]; then
    echo "==============LM Training============"
    #call kaldi's prepare_lang.sh to get a phones.txt
    #utils/prepare_lang.sh --position-dependent-phones true $dict "<UNK>" $data/local/lang $lang_dir 1>/dev/null || exit 1
    #./local/generate_new_phones.py $librispeech_phone/phones.txt $lang_dir/phones.txt ./local/phones.txt 1>/dev/null
    utils/prepare_lang.sh --position-dependent-phones true $dict "<UNK>" $data/local/lang $lang_dir  || exit 1
    ./local/generate_new_phones.py $librispeech_phone/phones.txt $lang_dir/phones.txt ./local/phones.txt 

    #call local prepare_lang.sh to map the local phones.txt to librispeech
    ./local/prepare_lang.sh --position-dependent-phones true $dict "<UNK>" $data/local/lang $lang_dir data/temp \
        $librispeech_phone ./local || exit 1
    ngram-count -order 1 -ndiscount -text $corpus_file -lm $lm_file
    gzip $lm_file
fi

#Generate HCLG.fst for decoder
if [ $stage -le 4 ]; then
    echo "=============Fst Commbine============"
    mkdir -p $graph_dir
    utils/format_lm.sh ./data/lang $gzip_lm_file $dict_file $graph_dir
    mkdir -p $graph_dir/phones
    cp $graph_dir/*.txt $graph_dir/*.int $graph_dir/*.csl $graph_dir/phones
    utils/mkgraph.sh --self-loop-scale 1.0 --remove-oov  $graph_dir $treedir $hclg_graph

    fstrmsymbols --apply-to-output=true --remove-arcs=true "echo 3|" $hclg_graph/HCLG.fst - | \
        fstconvert --fst_type=const > $graph_dir/temp.fst
    mv $graph_dir/temp.fst $graph_dir/HCLG.fst 
fi

#Decode use new HCLG.fst and librispeech final.mdl
if [ $stage -le 5 ]; then
    echo "================Decode==============="
    steps/nnet3/decode.sh --acwt 0.5 --post-decode-acwt 10.0 \
        --nj $nj --cmd "$decode_cmd" \
        $hclg_graph $data/$data_affix $librispeech_model
        #--online-ivector-dir ./exp/ivectors \
fi

#Scoring with sclite
if [ $stage -le 6 ]; then
    echo "================Scoring==============="
    ./local/prepare_socre_file.py exp/librispeech/lattices/log/decode.1.log data/pre_files/text $score_path
    cd $score_path
    sclite -r ref.txt -h hyp.txt -i rm -o sum pra
fi
