# Phasing

## Input

+ もしFASTAがあれば分類も行う
+ HDBSCANでクラスタリング→rolling meanでマージ

## コマンド

`xxx.sh -ref control.bam -que sample.bam (-f allele.fa -o directory)`

## 出力

アレルごとのBAMファイル

---

## ToDo
+ 引数処理の関数を記載する
+ 依存パッケージは最小限にする

### 依存パッケージ
+ R
  + tidyr
  + tidyfast
  + dplyr
  + purrr
  + furrr
  + reticulate
+ Python
  + HDBSCAN
  + joblib
  + sklearn