# AllenBrainAtlas-AnnotationDownloader
This script requests the structure boundary data of the P56 Mouse Coronal from http://atlas.brain-map.org/

## How to use this script
Execute the script with PowerShell.

The script will issue requests to the server of the Allen Institute and download the .SVG and .XML files associated with the P56 Mouse Brain.
The script creates one folder per filetype and puts the accordingly.

The .SVG files have the filename `<SortOrder>_<SvgId>.svg`. All in all 132 files will be created.
The .XML files (of which 680 will be created) contain the corresponding meta information (name of area, area id and so forth)   
