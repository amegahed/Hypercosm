/***************************************************************\
| |\  /|                                                We Put  |
| | >< Hypercosm        hc_scriptable_applet.js         3d      |
| |/  \|                                                To Work |
|***************************************************************|
|                                                               |
|        This file defines a Javascript function to add a       |
|        scriptable Hypercosm applet to a web page.             |
|                                                               |
|***************************************************************|
|                Copyright (c) 2007 Hypercosm, LLC.             |
\***************************************************************/

//
// "class" constructor
//

function HCScriptableApplet(element, appletSrc, resources, commandLine, parent) {
  if (!element)
    return this;
  // call superclass constructor
  //
  HCApplet.call(this, element, appletSrc, resources, commandLine, parent);
  
  // message passing attributes
  //
  this.messages = "";
  this.bufferMessages = false;
  this.bufferNestingLevel = 0;
  this.enabled = true;
  
  // these attributes can be used to view messages
  // messages that are being passed on to the applet
  //
  this.verbose = false;
  this.debug = false;
  
  return this;
}	// HCScriptableApplet

// inherit prototype from "superclass"
//
HCScriptableApplet.prototype = new HCApplet();

/***************************************************************\
|            scriptable applets and applet activation           |
|***************************************************************|
|                                                               |
|       Scriptable applets must be activated before their     	|
|       methods can be called.  The applet is considered        |
|       started after it has been downloaded and started        |
|       running.  Only at that point will it respond to         |
|       messsages passed into it from its Javascript            |
|       interface.   Note that the Hypercosm applet is          |
|       responsible for calling its Javascript interface's      |
|       "onActivate" method to notify that it's ready.          |
|                                                               |
\***************************************************************/

//
// "object" or "instance" methods
//

//
// method to enable or disable message passing
//

HCScriptableApplet.prototype.setEnabled = function(enabled) {
  this.enabled = enabled;
}	// setEnabled

/***************************************************************\
|                           scripting                           |
|***************************************************************|
|                                                               |
|        The following methods are used to communicate          |
|        with a Hypercosm applet through Javascript.            |
|                                                               |
|        Hypercosm applets can be passed messages from          |
|        Javascript and they can in turn respond by             |
|        calling Javascript functions that belong to their      |
|        enclosing web page.                                    |
|                                                               |
|        Note that whether a Hypercosm applet will respond      |
|        to messages passed into in and what messages it        |
|        will accept are determined by what functionality       |
|        has been compiled into that particular Hypercosm       |
|        applet.  Some Hypercosm applets respond to a rich      |
|        variety of messages and some do not respond to any.    |
|                                                               |
\***************************************************************/

//
// message passing methods
//

HCScriptableApplet.prototype.sendMessage = function(message) {
  if (!this.isActivated())
    return;
	
  if (this.verbose)
    setStatus(message);
	
  if (this.bufferMessages) {
    if (this.messageBuffer != "")
      this.messageBuffer = this.messageBuffer + ";";
    this.messageBuffer = this.messageBuffer + message;
  } else {
    if (this.debug)
	  alert("sending message: " + message);
    if (this.enabled)
      this.plugIn.SendMessage(message);
  }
}	// sendMessage

// 
// message buffering methods
//

HCScriptableApplet.prototype.beginMessages = function() {
	
  if (this.bufferMessages) {
	  
    // already buffering messages
    //
    this.bufferNestingLevel++;
  } else {
	  
    // start buffering messages
    //
    this.bufferMessages = true;
    this.messageBuffer = "";
    this.bufferNestingLevel = 0;
  }
}	// beginMessages

HCScriptableApplet.prototype.endMessages = function() {
  if (!this.isActivated())
    return;
	
  if (this.bufferNestingLevel == 0) {
	
    // end message buffering
    //
    if (this.messageBuffer != "") {
      if (this.debug)
	    alert("sending message: " + this.messageBuffer);
      if (this.enabled)
        this.plugIn.SendMessage(this.messageBuffer);
	}
	
    this.bufferMessages = false;
    this.messageBuffer = "";
  } else {
    // drop down a level in nesting
    //
    this.bufferNestingLevel--;
  }
}	// endMessages