#The MIT License (MIT)
#Copyright (c) 2016 Torben Dohrn <torben@nexusger.de>
#
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#


#This file downloads and saves the structure boundary data of the Mouse Brain Atlas (P56, Coronal) from the Allen Brain Atlas Project

#create precondition
if( !(test-path ".\xml")){
    mkdir xml
}
if( !(test-path ".\svg")){
    mkdir svg
}

#The files aren't ordered. This parts downloads a help file and creates a lookup array
#The url is found on the following help site: http://help.brain-map.org/display/api/Atlas+Drawings+and+Ontologies
$atlasImageOrderRequest = invoke-webrequest -uri "http://api.brain-map.org/api/v2/data/query.xml?criteria=model::AtlasImage, rma::criteria, [annotated`$eqtrue], atlas_data_set(atlases[id`$eq1]), alternate_images[image_type`$eq'Atlas+-+Adult+Mouse'], rma::options[order`$eq'sub_images.section_number'][num_rows`$eqall]"
$atlasImageOrderData = [xml]$atlasImageOrderRequest.Content
$atlasImageOrder = @{}
$iterator = 1
$atlasImages = $atlasImageOrderData.SelectNodes("Response/atlas-images/*") | ForEach-Object{
    $atlasImageOrder.Add($_.id,$iterator)
    $iterator = $iterator +1
}
$prefixLength=3


#All docs on http://help.brain-map.org/display/api/Downloading+and+Displaying+SVG
#Download a list of AtlasImages from the "Mouse, P56 Coronal" Atlas (id=1) that have Structure boundary annotations (GraphicGroupLabel.id=28):
$result = Invoke-WebRequest -Uri "http://api.brain-map.org/api/v2/data/query.csv?criteria=model::AtlasImage,rma::criteria,atlas_data_set(atlases[id`$eq1]),graphic_objects(graphic_group_label[id`$eq28]),rma::options[tabular`$eq'sub_images.id'][order`$eq'sub_images.id']&num_rows=all&start_row=0"
$result.Content.Split() | where-object { ($_ -notcontains "id") -and -not ($_ -contains "") } | foreach-object {
    #Download the structure boundary annotations (GraphicGroupLabel.id=28) for an AtlasImage (id=100960033) as a file (.svg):
    $uri = "http://api.brain-map.org/api/v2/svg_download/$_`?groups=28"

    $downloadedSvg =Invoke-WebRequest -Uri $uri
    #prefix the filename with the order
    $prefix=[string]$atlasImageOrder.$_
    $prefixWithPadding=$prefix.PadLeft($prefixLength,'0')
    $fileName = ".\svg\$prefixWithPadding`_$_.svg"
    $downloadedSvg.Content | out-file $fileName
    "Downloaded boundary file: $fileName"
    #don't hammer the site
    Start-Sleep -Milliseconds 500
}

#All files are loaded. Open them, read the id tags and grab these as well
$structureIds=@()
Get-ChildItem -Path .\svg | foreach-object {
    [xml]$content = Get-Content .\svg\$_
    $content.svg.g.g.ChildNodes | ForEach-Object {$structureIds+=$_.structure_id }
}

#$structureIds.Count -> 10972
#$structureIds | get-unique -> 9930
#$structureIds | Sort-Object| get-unique -> 680

#Get unique ids and download the description for later use
$structureIds | Sort-Object| get-unique | ForEach-Object{

    if( test-path ".\xml\$_.xml"){
        "Skipped structureId $_.xml"
    }else{
        $uri = "http://api.brain-map.org/api/v2/data/Structure/$_.xml"

        $downloadedXml =Invoke-WebRequest -Uri $uri

        $downloadedXml.Content | out-file ".\xml\$_.xml"
    
        #don't hammer the site
        Start-Sleep -Milliseconds 1000
        "Downloaded structureId $_.xml"
    }
    $i=$i+1
}
