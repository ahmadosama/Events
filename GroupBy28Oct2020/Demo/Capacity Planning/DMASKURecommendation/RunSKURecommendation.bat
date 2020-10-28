cd "C:\Program Files\Microsoft Data Migration Assistant\"
powershell.exe -File .\SkuRecommendationDataCollectionScript.ps1 -ComputerName appvm -OutputFilePath "C:\GroupBy\Demo\Capacity Planning\DMASKURecommendation\Counter.csv" -CollectionTimeInSeconds 2400 -DbConnectionString "Server=appvm;Initial Catalog=master;Integrated Security=SSPI;"
@echo off
pause