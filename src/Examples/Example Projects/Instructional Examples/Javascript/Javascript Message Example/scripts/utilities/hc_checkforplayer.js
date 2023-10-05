/***************************************************************\
| |\  /|                                                We Put  |
| | >< Hypercosm         hc_checkforplayer.js           3d      |
| |/  \|                                                To Work |
|***************************************************************|
|                                                               |
|        This file contains some javascript to check if the     |
|        web browser and operating system are compatible        |
|        with the Hypercosm Player.                             |
|                                                               |
|***************************************************************|
|                Copyright (c) 2008 Hypercosm, LLC.             |
\***************************************************************/

// check platform
//
var isWin = ((agt.indexOf("win")!=-1) || (agt.indexOf("16bit")!= -1));
var isMac = (agt.indexOf("mac") != -1);

if (!isWin && !isMac) {
  // redirect to platform error page.
  // 
  alert("Sorry - Hypercosm is only supported on Windows and the Macintosh");
  window.top.location = "http://www.hypercosm.com/download/player/platform_error.html";
} else {
  // check web browsers
  //
  if (isIe6up) {
      
    // Internet Explorer 6 and up
    //
    
    // create an instance of the player using vbscript
    //
    document.writeln('<script language="VBScript">')
    document.writeln('On Error Resume Next')
    document.writeln('Set theObject = CreateObject("HypercosmActivex.HyperX.1")'); 
    document.writeln('If IsObject(theObject) Then'); 
    document.writeln("hasHypercosm = true")
    document.writeln("Else")
    document.writeln("hasHypercosm = false")
    document.writeln('End If');
    document.writeln('</script>')
      
    if (!hasHypercosm) {
      var button = confirm("The Hypercosm Player is needed to view this page.\nWould you like to be redirected to the download page?");
      if (button == true)
        window.top.location = "http://www.hypercosm.com/download/player/index.html";
    }   
  } else if (isGecko || isSafari) {
      
    // Firefox, Netscape etc.
    //
    hasHypercosm = false;
    for (i=0; i<navigator.plugins.length; i++) {
      if (navigator.plugins[i].name.substring(0, 9) == "Hypercosm")
        hasHypercosm = true;
    }
    if (!hasHypercosm) {
      var button = confirm("The Hypercosm 3D Player is needed to view this page.\nWould you like to be redirected to the download page?");
      if (button == true)
        window.top.location = "http://www.hypercosm.com/download/player/index.html";
    }
  } else {
      
    // unrecognized web browser - redirect to browser error page.
    //
    window.top.location = "http://www.hypercosm.com/download/player/browser_error.html";     
  }
}