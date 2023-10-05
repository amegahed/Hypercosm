/***************************************************************\
| |\  /|                                                We Put  |
| | >< Hypercosm        web_browser_sniffer.js          3d      |
| |/  \|                                                To Work |
|***************************************************************|
|                                                               |
|        This file contains some javascript utilities that      |
|        are used to detect the type of web browser.            |
|                                                               |
|***************************************************************|
|                Copyright (c) 2007 Hypercosm, LLC.             |
\***************************************************************/

var agt=navigator.userAgent.toLowerCase();
var appVer = navigator.appVersion.toLowerCase();
var isMinor = parseFloat(appVer);
var isMajor = parseInt(isMinor);
// Note: On IE, start of appVersion return 3 or 4
// which supposedly is the version of Netscape it is compatible with.
// So we look for the real version further on in the string
//
var iePos  = appVer.indexOf('msie');
if (iePos != -1) {
  isMinor = parseFloat(appVer.substring(iePos+5,appVer.indexOf(';',iePos)));
  isMajor = parseInt(isMinor);
}
// ditto Konqueror
//                                     
var isKonq = false;
var kqPos   = agt.indexOf('konqueror');
if (kqPos !=-1) {                 
   isKonq  = true;
   isMinor = parseFloat(agt.substring(kqPos+10,agt.indexOf(';',kqPos)));
   isMajor = parseInt(isMinor);
}  
// main browser types
//
var isOpera = (agt.indexOf("opera") != -1);
var isKhtml  = (isSafari || isKonq);
var isIe   = ((iePos!=-1) && (!isOpera) && (!isKhtml));
var isIe6up = (isIe && isMinor >= 6);
var isGecko = ((!isKhtml)&&(navigator.product)&&(navigator.product.toLowerCase()=="gecko"))?true:false;
var isSafari = ((agt.indexOf('safari')!=-1)&&(agt.indexOf('mac')!=-1))?true:false;