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
|                Copyright (c) 2007 Hypercosm, LLC.             |
\***************************************************************/

if (!is_win) {
  // redirect to platform error page.
  // 
  alert("platform error");
  window.top.location = "http://www.hypercosm.com/download/player/platform_error.html"; 
} else {
    
  // check web browsers
  //
  if (is_ie6up) {
      
    // Internet Explorer 6 and up
    //
    
    // create an instance of the player using vbscript
    //
    document.writeln('<script language="VBScript">')
    document.writeln('On Error Resume Next')
    document.writeln('Set theObject = CreateObject("HypercosmActivex.HyperX.1")'); 
    document.writeln('If IsObject(theObject) Then'); 
    document.writeln("haveHypercosm = true")
    document.writeln("Else")
    document.writeln("haveHypercosm = false")
    document.writeln('End If');
    document.writeln('</script>')
      
    if (haveHypercosm == false) {
      var button = confirm("The Hypercosm 3D Player is needed to view this page.\nWould like to be redirected to the  Player's download page?");
      if (button == true) {
        window.top.location = "http://www.hypercosm.com/download/player/index.html";
      }
    }   
  } else if (is_gecko) {
      
    // Firefox, Netscape etc.
    //
    haveHypercosm = false;
    for (i=0; i<navigator.plugins.length; i++) {
      if (navigator.plugins[i].name == "Hypercosm 3D Player") {
        haveHypercosm = true;
      }
    }
    if (haveHypercosm == false) {
      var button = confirm("The Hypercosm 3D Player is needed to view this page.\nWould like to be redirected to the  Player's download page?");
      if (button == true) {
        window.top.location = "http://www.hypercosm.com/download/player/index.html";
      }
    }
  } else {
      
    // unrecognized web browser
    //
    
    // redirect to browser error page.
    // 
    window.top.location = "http://www.hypercosm.com/download/player/browser_error.html";     
  }
}