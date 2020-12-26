# TODO for DAJIN2

<!-- markdownlint-disable MD004 MD005 -->

## オプション確認

+ [ ] `parse_arguments.sh`

## 依存ソフトウェア確認

+ [ ] `check_dependencies.sh`
  + [ ] samtools
  + [ ] minimap2
  + [ ] emboss
  + [ ] python
    + [ ] numpy, pandas, sklearn
  + [ ] R

## 小さなプログラムに分割

+ [ ] check_arguments.sh
+ [ ] check_dependencies.sh
+ [ ] phasing.sh
+ [ ] consensus.sh
+ [ ] igvjs.sh

## 汎用性のあるファイルフォーマットを意識する

+ [ ] phasing: input=fastqと参照アレルのfasta, オプションで分類したいアレルのfasta, output=bam
+ [ ] consensus: input=bamと参照アレルのfasta, output=vcfとfastaとhtmlレポート
  + VCFを入力にするとDAJINの目的以外にも使える
+ [ ] igvjs: input=bamまたはbamファイルを記載したテキスト, output=html (browserポップアップ)

## ディレクトリ構成

+ .DAJIN_temp/mapping/temp
+ .DAJIN_temp/classification/temp
+ .DAJIN_temp/clustering/temp
+ .DAJIN_temp/consensus/temp
+ .DAJIN_temp/igvjs/temp

## データ準備

+ [ ] NanoSimによる正常アレルと異常アレル（50bp insertion/deletion）を1000リードずつ用意する
+ `simulation/data`に保存
  + [ ] Tyr c140GC
    + [ ] WT
    + [ ] WT insertion
    + [ ] WT deletion
    + [ ] Target
    + [ ] Target insertion
    + [ ] Target deletion
  + [ ] Prdm14
    + [ ] WT
    + [ ] WT insertion
    + [ ] WT deletion
    + [ ] Target
    + [ ] Target insertion
    + [ ] Target deletion
    + [ ] Inversion
    + [ ] Inversion insertion
    + [ ] Inversion deletion
  + [ ] Cables2 WT
    + [ ] WT
    + [ ] WT insertion
    + [ ] WT deletion
    + [ ] Target
    + [ ] Target insertion
    + [ ] Target deletion
    + [ ] Inversion
    + [ ] Inversion insertion
    + [ ] Inversion deletion
    + [ ] Left LoxP
    + [ ] Left LoxP insertion
    + [ ] Left LoxP deletion
    + [ ] Right LoxP
    + [ ] Right LoxP insertion
    + [ ] Right LoxP deletion
    + [ ] Deletion
    + [ ] Deletion insertion
    + [ ] Deletion deletion

> .DAJIN_temp/mapping/tempにははじめにCSタグつきのsamファイルを保存する
> かつ, のちのちBAMファイルの保存先も.DAJIN_temp/mapping/が兼ねる

## 前処理 `preprocess.sh`

+ [ ] 脱NanoSim

+ [ ] `preprocess_fasta.sh`

+ [ ] `preprocess_fastq.sh`
  + [ ] 変数input_dirに指定されているFASTQディレクトリから`qcat`および`Guppy`を判定する
  + [ ] `Guppy`スタイルなら`barcode01.fastq`といったフォーマットに変換する
  + [ ] `qcat`ならなにもしない
  + [ ] それ以外ならエラー処理
  + [ ] fasta_ontディレクトリに保存する

+ [x] `preprocess_mapping.sh`
  + [x] fasta_ontにあるサンプルを各アレル（WT, Target, Inversionなど）に対してminimap2でアライメントしてsamファイルを出力する
  + [x] samディレクトリに保存する

## 分類 `classif.sh`

### 各アレルの分類

+ [x] 脱GPU

+ [x] `classif_scoring.sh` スコアを作る
  + [x] 変異塩基数をカウントする
  + [x] 変異塩基数を非変異塩基数で割る（大型欠失アレルでは変異塩基数も非変異塩基数も減るため）
  + [x] 割った値に対して対数をとる
  + [x] scoreディレクトリに保存する

> 異常な大型欠失の場合はマップ塩基数が減って変異塩基数が増えているが, 問題ないか？→異常アレルの判定がしやすいのでよいか？）

+ [x] `classif_annotate.sh`
  + [x] 各リードの"score"がもっとも小さいアレルに分類する
  + [x] `*`の非マップリードは**abnormal**に分類する
  + [x] classifディレクトリに保存する

+ [x] `classif_anomaly_control_trim.R`
  + [x] controlの"score"に対して, Hotelling T2を用いて正常のスコアのみを取り出す
  + [x] classifディレクトリに保存する

+ [x] `classif_anomaly_control_lof.py`
  + [x] controlの"score"をLOFにて学習する
  + [x] classifディレクトリに保存する

+ [x] `classif_anomaly_sample_lof.py`
  + [x] sampleの"score"をLOFに入れて正常アレルと異常アレルを分類する
  + [x] classifディレクトリに保存する

### 異常アレルと正常アレルの分類

+ [ ] 2-cutのときにほかのエクソンに影響を与えていない異常アレルを「non-problematic」（仮称）とする

## クラスタリング

## コンセンサス

+ [ ] 大型欠失にも対応する（計算速度の向上）
+ [ ] Cas切断部をハイライトする
+ [ ] 変異部位をハイライトする


## UX

+ [ ] GUIサポート
  + [ ] PysimpleGUIでシェルコマンドとRスクリプトが動くか確認
  + [ ] PysimpleGUIでシェルコマンドとRスクリプトで並列処理ができるか確認
  + [ ] PysimpleGUIでシェルコマンドとRスクリプトでプログレスバーの表示ができるか確認
  + [ ] PysimpleGUIで入力画面を作る
  + [ ] PysimpleGUIの入力画面でファイルアップロードを試す
  + [ ] PysimpleGUIの入力画面で入力された情報が正しいかどうかのチェックをする
  + [ ] PysimpleGUIの入力画面でエラー表示をする
  + [ ] PysimpleGUIの実行中画面でプログレスバーを表示する
  + [ ] PysimpleGUIの実行中画面でエラー表示をする
  + [ ] PysimpleGUIの出力画面で出力ディレクトリを表示する
  + [ ] PysimpleGUIの出力画面でエラー表示をする

## 今後の課題

+ [ ] 大規模な構造異常の同定は？
+ [ ] PCRフリー（より長鎖）に対応
  + [ ] 長さが参照配列よりも短い場合, いまの手法ではDeletionが多くなってしまう. 