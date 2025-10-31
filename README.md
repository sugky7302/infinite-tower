<h1 align=center>無盡之塔</h1>
<p align=center>這是一張魔獸爭霸三地圖。為了增強遊戲表現，我加入了內置 JAPI 來簡化遊戲設計並客製化 UI。</p>
<p align="center">
    <img src="https://img.shields.io/badge/war3-1.26-blue"/>
    <img src="https://img.shields.io/badge/lang-jass-blue" alt="" />
    <img src="https://img.shields.io/badge/ydwe-1.32.13-blue" alt="" />
</p>
<br/>

## 目錄
- [目錄](#目錄)
- [核心創意](#核心創意)
- [專案結構](#專案結構)
- [開發流程](#開發流程)
- [FAQ](#faq)

## 核心創意
![image](./static/mindmap.jpg)

## 專案結構
```
.
├─README.md
├─InfiniteTower.w3x：obj 格式的地圖檔
├─.w3x：lni 格式的地圖檔
├─doc：文件
├─map：地圖的原始碼
├─static：靜態資源
├─resource：地圖的靜態檔
├─table：地圖的數據檔
├─w3x2lni：自動生成的 w3x2lni 格式轉換工具的版本紀錄
├─scripts：程式碼
|  ├─shared：公用包
|  ├─entity：war3 數據映射結構
```

## 開發流程
1. 打開 YDWE，載入 **.w3x**。
2. 在 VS Code 編輯之後，先按下**打包**，然後在 YDWE 按下儲存。
3. 在 VS Code 點擊**執行**命令。
4. 按下**解包**還原因為 YDWE 更新的程式碼。

## FAQ
1. 出現 `The term 'chcp 65001 && E:\projects\map/tools/w3x2lni/bin/w3x2lni-lua.exe' is not recognized` 的問題。
>必須使用 cmd.exe 執行。