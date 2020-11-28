# TODO for DAJIN2

## データ準備

+ [ ] NanoSimによる正常アレルと異常アレル（50bp insertion/deletion）を1000リードずつ用意する
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

## 前処理

+ [ ] 脱NanoSim
+ [x] サンプルを各アレル（WT, Target, Inversionなど）に対してminimap2でアライメントしたsamファイルを出力する

## 分類

### 各アレルの分類

+ [ ] 脱GPU
  + [x] 変異塩基数をカウントする
  + [x] 変異塩基数を非変異塩基数で割り, これを”score”とする（大型欠失アレルでは変異塩基数も非変異塩基数も減るため）
    + [ ] （異常な大型欠失の場合はマップ塩基数が減って変異塩基数が増えているが, 問題ないか？→異常アレルの判定がしやすいのでよいか？）
  + [x] 各リードに対してもっとも"score"が小さいアレルをそのアレルとする
  + [ ] controlの"score"をもとにして異常検知をする

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
