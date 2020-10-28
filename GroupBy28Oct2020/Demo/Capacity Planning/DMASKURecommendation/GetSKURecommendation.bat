cd "C:\Program Files\Microsoft Data Migration Assistant"
.\DmaCmd.exe /Action=SkuRecommendation /SkuRecommendationInputDataFilePath="C:\GroupBy\Demo\Capacity Planning\DMASKURecommendation\Counter.csv" /SkuRecommendationOutputResultsFilePath="C:\GroupBy\Demo\Capacity Planning\DMASKURecommendation\skurecommedation.html" /SkuRecommendationTsvOutputResultsFilePath="C:\GroupBy\Demo\Capacity Planning\DMASKURecommendation\skurecommendation.tsv" /SkuRecommendationPreventPriceRefresh=true
@echo off
pause