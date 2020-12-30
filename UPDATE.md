# DAJIN2へ向けてのToDOリスト

## 必須

+ [ ] NanoSim脱依存
+ [ ] シークエンスエラー検出（時系列データの異常検知問題）
+ [ ] GUIの実装
+ [ ] Consensus配列にgRNAおよび変異部位を表記
  + [ ] gRNAは囲み, 変異部位はbold？
+ [ ] 他のエクソンに影響を与えているabnormalかそうでないかの判別
+ [ ] フレームシフト変異の有無を報告

## 推奨

### WETとの組み合わせ

+ [ ] UMI対応（←水野先生のWetが可能かによる）
  + [ ] [IDM-seqのデータ](https://genomebiology.biomedcentral.com/articles/10.1186/s13059-020-02143-8#availability-of-data-and-materials)を使用しても良い. 
+ [ ] in vivoゲノム編集対応（←水野先生のWetが可能かによる）
+ [ ] nCATS対応（[データ](https://www.nature.com/articles/s41587-020-0407-5#data-availability)）

### Prediction

#### CPUでやる場合（こちらのほうが理想）

+ [ ] CPUのみでDAJINと同性能の分類・異常検知
+ [ ] macOSでの動作確認

#### GPUでやる場合

+ [ ] より再現性の高い前処理またはDNNモデル（Attention?）
+ [ ] multiGPU対応

### そのほか

+ [ ] 可能な限り小さい関数・コンポーネントに分割する
+ [ ] テストを書く
+ [ ] 類似リードのマージ閾値についてコサイン類似度以外の方法を検討する
+ [ ] progress barの実装
+ [ ] gRNA情報を用いた正確な変異部位の検出

### デバッグリスト

https://docs.google.com/spreadsheets/d/1JtfFiRQxfSKL-4aNk0bTBU_4N8vtQ0I0q-qMQn-Z2-A/edit?usp=sharing

-----

## メモ

### ルールベースの分類方法

+ 予想される全配列にmappingする→各参照配列ごとにマッピングされやすさをスコア化→スコアが最も高かった参照配列をそのアレルとする.
  + [ ] mappingしたあとにその変異部位を含むかどうかのチェックをおこなう
  + [ ] 変異部の探索はgRNA配列を用いる（せっかくPAMつきgRNAを入力に用いているので！）. これでinversionの場合にも正確な切断部位が認識可能になるはず. 
+ その後, 異常アレルの検知とクラスタリングを行う（要検討）