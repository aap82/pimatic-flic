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

The plugin allows connections to multiple daemons.  

|Property               | Default       |Required   |Description 
|:----------------------|:--------------|-----------|:------------------
|name                   |               | **yes**   |A name for your daemon.  A param-case id will be created using this name.
|host                   |*localhost*    | **yes**   |You can also connect to remote ip addresses
|port                   |*5551*         | **yes**   |The port to connect to
|autoReconnect          |*true*         | **no**    |Enable auto-reconnection to flic deamon
|autoReconnectInterval  |*30*           | **no**    |Interval in seconds to attempt reconnects
|maxRetries             |*1000*         | **no**    |The number of retries to attempt


## Devices

Along with a FlicButton device that will be used to capture events from individual flics, this plugin also
provides a utility device called FlicScanWizardButton. 

### FlicButton

This is main *pseudo* device that is essentially a pimatic representation of a single flic button.  The device will connect to a flic, 
and listen for **Single-Click**, **Double-Click** and **Hold** button events sent by the flic daemon server.  
Additionally, the device may also enable listening for **Down** and **Up** button events.  This is disabled by default, as it 
it essentially doubles the number of events reported.

The device provides to actions, and has only one attribute:  **connection_status**.  If you see the value of this attribute as "Press and Hold"
then press the flic for about 5 seconds or so, and you should see this change.

Its *highly* encouraged to add flic using Device Discovery.  
 

|Property               | Default       |Required   |Description 
|:----------------------|:--------------|-----------|:------------------
|daemon                 |               | **yes**   |Daemon to connect. Auto-populated via discovery
|bdAddr                 |               | **yes**   |Unique bluetooth mac address. Auto-populated via discovery
|upDown                 |*false*        | **no**    |Enable listening for button down and up events 
|maxTimeDiff            |*3*            | **yes**   |Time in seconds between button push and receive time after which event ignored


### FlicScanWizardButton

A button device added automatically at installation, with one button for each daemon listed in plugin config.  
The Flic Daemon pressed will be placed into scanning/pairing mode for 30 seconds.  During this process, 
connections to any other daemons will be closed.  

Follow the onscreen instructions to pair a flic to that daemon.  Once pairing is complete,
use device discovery to add the newly found flic button to pimatic. 

This is _experimental_ and _highly discouraged_, BUT, it is possible to pair a single flic with multiple daemons, 
and through the FlicButton device options, select the daemon to which to connect.


### Predicate Provider

The plugin includes a predicate provider that can be used in the rules used in the following form:

    {flic} is {press-type}
    
where flic is the device-id of the flic and press-type is one of the following:

    single-clicked
    double-clicked
    held

and, if upDown is enabled, also:          
          
    pressed-down
    released

### rPi

There is an additional folder in the repository called **rpi** which contains a file named **flicd.service**, 
which is a systemd service unit to enable the daemon on boot.

As written, it assumes the flicd executable is located 

    /home/pi/flic/flicd
    
and will start the server listening at 0.0.0.0, allowing external requests. 


    
      






