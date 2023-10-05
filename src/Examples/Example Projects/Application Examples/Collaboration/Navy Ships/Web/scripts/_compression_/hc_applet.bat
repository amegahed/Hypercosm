::
:: This script copies a set of Javascript files, 
:: combining them together into a single file.
::
@ECHO OFF
:: This is the name of the output file
::
SET output=hc_applet.js
:: This is the Javascript compressor \ compiler to use
::
SET compress="true"
SET compressor="C:\Program Files\YUI Compressor\build\yuicompressor-2.4.2.jar"
:: Create the output file
::
ECHO creating %output%
ECHO. 2>> %output%
:: For each of the following files...
::
FOR %%I IN (
..\utilities\web_browser_sniffer.js
..\utilities\web_browser_utils.js
..\utilities\web_browser_plug_ins.js
..\utilities\hc_checkforplayer.js
..\components\component.js
..\applet\hc_applet.js
  
) DO (
  ECHO adding %%I
  TYPE %%I >> %output%
  ECHO. >> %output%
  ECHO. >> %output%
  ECHO. >> %output%
)
:: Last, compress the resulting javascript file
::
IF %compress%=="true" (
  java -jar %compressor% %output% > temp
  copy temp %output%
  del temp
)