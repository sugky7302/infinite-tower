@echo off
::设置为UTF-8编码
chcp 65001

::填写路径设置
set ydwePath=D:\war3\ydwe
set w3x2lniPath=%~1\tools\w3x2lni\w2l.exe
echo "當前 w3x2lni 路徑為 %w3x2lniPath%"

set mapName=%~1\%~2

echo "正在使用 w3x2lni 轉換 %mapName%"
%w3x2lniPath% obj "%~1"

echo "使用 YDWE 啟動 %mapName%"
%ydwePath%\ydwe.exe -war3 -loadfile "%mapName%"