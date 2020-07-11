#!/bin/bash
. ./cmd.sh
. ./path.sh

nj=8
set -e # exit on error
nnet_dir=exp/xvector_nnet_1a
mfccdir=mfcc

##### prepare files, eg. wav.scp #####
local/timit_data_prep.sh timit_sre/wav

#### extract mfcc, segments ######
extract mfcc
steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj data/train exp/make_mfcc/train $mfccdir

# generate vad.scp
sid/compute_vad_decision.sh --nj $nj --cmd "$train_cmd" data/train exp/make_mfcc/train $mfccdir

# generate segments
diarization/vad_to_segments.sh --nj $nj --cmd "$train_cmd" data/train data/train_seg

# copy segments 
cp data/train_seg/segments data/train
utils/fix_data_dir.sh data/train

# for test
steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj data/test exp/make_mfcc/test $mfccdir
sid/compute_vad_decision.sh --nj $nj --cmd "$train_cmd" data/test exp/make_mfcc/test $mfccdir
diarization/vad_to_segments.sh --nj $nj --cmd "$train_cmd" data/test data/test_seg
cp data/test_seg/segments data/test
utils/fix_data_dir.sh data/test

#### prepare features #####
local/nnet3/xvector/prepare_feats.sh --nj $nj --cmd "$train_cmd" \
      data/train data/train_cmn data/train_cmn
cp data/train/segments data/train_cmn
utils/fix_data_dir.sh data/train_cmn
  
local/nnet3/xvector/prepare_feats.sh --nj $nj --cmd "$train_cmd" \
      data/test data/test_cmn data/test_cmn
cp data/test/segments data/test_cmn
utils/fix_data_dir.sh data/test_cmn

##### split test data #####
cp data/train/vad.scp data/train_cmn
cp data/test/vad.scp data/test_cmn
mkdir -p data/test_cmn/enroll data/test_cmn/eval
cp data/test_cmn/{spk2utt,feats.scp,vad.scp} data/test_cmn/enroll
cp data/test_cmn/{spk2utt,feats.scp,vad.scp} data/test_cmn/eval

local/split_data_enroll_eval.py data/test_cmn/utt2spk  data/test_cmn/enroll/utt2spk  data/test_cmn/eval/utt2spk
trials=data/test_cmn/test_cmn.trials

local/produce_trials.py data/test_cmn/eval/utt2spk $trials
utils/fix_data_dir.sh data/test_cmn/enroll
utils/fix_data_dir.sh data/test_cmn/eval

#### extract xvectors #####
sid/nnet3/xvector/extract_xvectors.sh --cmd "$train_cmd --mem 6G" --nj $nj \
  $nnet_dir data/train_cmn \
  $nnet_dir/xvectors_train

sid/nnet3/xvector/extract_xvectors.sh --cmd "$train_cmd --mem 6G" --nj $nj \
  $nnet_dir data/test_cmn/eval \
  $nnet_dir/xvectors_eval

sid/nnet3/xvector/extract_xvectors.sh --cmd "$train_cmd --mem 6G" --nj $nj \
  $nnet_dir data/test_cmn/enroll \
  $nnet_dir/xvectors_enroll


#### PLDA scoring #####
## if failed, please remove directory scores and then try again
cp $nnet_dir/xvectors_train/xvector.scp exp/xvectors_sre_combined
local/nnet3/xvector/plda_scoring.sh data/train_cmn data/test_cmn/enroll data/test_cmn/eval \
  exp/xvectors_sre_combined $nnet_dir/xvectors_enroll $nnet_dir/xvectors_eval $trials $nnet_dir/scores

##### compute EER #####
eer=$(compute-eer <(python local/prepare_for_eer.py $trials $nnet_dir/scores/plda_scores) 2>/dev/null)
printf "%15s %5.2f \n" "$i eer:" $eer >$nnet_dir/scores/results.txt

exit 0