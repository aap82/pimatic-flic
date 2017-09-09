# pimatic-flic

Flic Button plugin for <a href="https://pimatic.org">Pimatic</a>.

This plugin is used to connect with a server daemon provided by the <a href="https://github.com/50ButtonsEach/fliclib-linux-hci">Fliclib Linux HCI</a> SDK.
 
## Installation

first stop pimatic with either:

    sudo service pimatic stop
or

    sudo systemctl stop pimatic.service
    
From the root of your pimatic-app installation folder
    
    cd node_modules
    git clone https://github.com/aap82/pimatic-flic.git
    cd pimatic-nest
    npm install
    
## Plugin Configuration

|Property   | *Defaults* | Description 
|:---------------|:-----------|:----------------------------
|host | *localhost* | You can also connect to remote ip addresses
|port | *5551* | The port to connect to
|autoReconnect| *true* | Enable auto-reconnection to flic deamon



## Devices

Along with a FlicButton device that will be used to interact with individual flics, this plugin also
provides a utility device called FlicScanWizardButton that can be used to pair buttons with a daemon.








