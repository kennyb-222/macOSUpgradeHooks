# macOSUpgradeHooks

Did you know that you can have macOS run a script whenever you update or upgrade the system? Well... you can't. But you can if you adopt "Upgrade Hooks" for macOS. An upgrade hook tells macOS to execute a script when an OS update or upgrade has started, completed, or migrated.

### With an upgrade hook:

- The upgrade hook will be run as root
- Executes when the following events occur:
	- Staged upgrade (OS upgrade/update is staged and pending restart)
	- Upgrade completion (OS update/upgrade has finished and the loginwindow is loaded)
	- Migration completion (automated user login in after the update/upgrade is complete)
- Upgrade actions will not wait until the hook has completely executed


### How to setup your upgrade hooks

Input your script code info the following functions that you would like to be called during each event.

The customizable events are `PreUpgrade`, `PostUpgrade`, and `MigrationComplete`

### How to install macOS upgrade hooks

`sudo /bin/bash /path/to/macOSUpgradeHooks.sh`

### How to uninstall

`sudo /bin/bash /private/var/db/.AppleUpgradeHooks.sh "uninstall"`

##### Notes
Tested on both major (10.14.x - 10.15.x) and minor (10.15 - 10.15.x) macOS release updates
