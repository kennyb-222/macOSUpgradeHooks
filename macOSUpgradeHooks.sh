#!/bin/bash
# macOSUpgradeHooks
# Description: Execute a script when an OS update or upgrade has started, completed, or migrated
# Source: https://github.com/kennyb-222/macOSUpgradeHooks/
# Author: Kenny Botelho

# Upgrade Hooks
PreUpgrade() {
#!/bin/bash
## preupgrade

# add commands here or call some script(s)
/bin/bash /path/to/PreUpgrade.sh

return 0
}

PostUpgrade() {
#!/bin/bash
## postupgrade

# add commands here or call some script(s)
/bin/bash /path/to/PostUpgrade.sh

return 0
}

MigrationComplete() {
#!/bin/bash
## migrationcomplete

# add commands here or call some script(s)
/bin/bash /path/to/MigrationComplete.sh

return 0
}

#####################################
#   DO NOT MIDIFY BELOW THIS LINE   #
#####################################

Install() {
    # Copy script to destination path
    cp "$0" ${ScriptPath}
    
    # Create LaunchDaemon to watch for "Stagged Apple Upgrades"
    cat > ${PlistPath} << \EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.AppleUpgrade.Hooks</string>
    <key>LaunchOnlyOnce</key>
    <true/>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>/private/var/db/.AppleUpgradeHooks.sh</string>
    </array>
    <key>RunAtLoad</key>
    <false/>
    <key>WatchPaths</key>
    <array>
        <string>/private/var/db/.StagedAppleUpgrade</string>
        <string>/private/var/db/.AppleUpgrade</string>
    </array>
</dict>
</plist>
EOF

    # Set Permissions
    chmod 755 ${PlistPath} ${ScriptPath}
    
    # Load LaunchDaemon
    /bin/launchctl load ${PlistPath}
}

FetchUpgradeInfo() {
    # Fetch staged upgrade information
    UpgradeVersion=$(/usr/libexec/PlistBuddy -c \
                "Print :0:auxinfo:macOSProductVersion" \
                ${ProductMetadataPath} )
    UpgradeBuild=$(/usr/libexec/PlistBuddy -c \
                "Print :0:auxinfo:macOSProductBuildVersion" \
                ${ProductMetadataPath} )
    UpgradeProductKey=$(/usr/libexec/PlistBuddy -c \
                "Print :0:cachedProductKey" \
                ${ProductMetadataPath} )
    UpgradeUser=$(/usr/libexec/PlistBuddy -c \
                "Print :User" /private/var/db/.StagedAppleUpgrade )
    UpgradeType=$(/usr/libexec/PlistBuddy -c \
                "Print :UpgradeType" /private/var/db/.StagedAppleUpgrade )
    # Set upgrade type flag            
    if [[ ${UpgradeType} == "Upgrade" ]]; then
        MajorUpgrade=1
    fi
}

Uninstall() {
    # Uninstall launchd task and script
    echo "removing AppleUpgradeHooks..."
    rm ${ScriptPath} ${PlistPath}
    /bin/launchctl remove com.AppleUpgrade.Hooks
}

# Set environment
export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
ScriptPath="/private/var/db/.AppleUpgradeHooks.sh"
PlistPath="/Library/LaunchDaemons/com.AppleUpgrade.Hooks.plist"
ProductMetadataPath="/System/Volumes/Data/Library/Updates/ProductMetadata.plist"
launchdPID=$(launchctl list | grep com.AppleUpgrade.Hooks | awk '{print $1}')

# Check if root
if [[ "$(id -u)" != 0 ]]; then
    echo "This script must be run as root. Exiting..."
    exit 1
fi

# Check if we need to install or uninstall
if [[ $1 == "uninstall" || $4 == "uninstall" ]]; then
    Uninstall
    exit $?
elif [[ -z ${launchdPID} ]]; then
    Install
    exit $?
fi

# Check which stage of the upgrade we are in
if [[ -f /private/var/db/.StagedAppleUpgrade ]] &&
   [[ ! -f /private/var/db/.AppleUpgrade ]]; then
    # Perform pre-upgrade actions
    FetchUpgradeInfo
    PreUpgrade
elif [[ -n ${UpgradeVersion} ]]; then
    exit 1
elif [[ ! -f /private/var/db/.StagedAppleUpgrade ]] &&
     [[ ! -f /private/var/db/.AppleUpgrade ]] &&
     [[ -z ${UpgradeVersion} ]]; then
    # Perform post-upgrade actions
    PostUpgrade
    # Wait for login
    while ! /usr/bin/pgrep -x "Dock" > /dev/null; do
        sleep 10
    done
    # Wait for the post upgrade login to complete
    while /usr/bin/pgrep -x "Installer Progress" > /dev/null; do
        sleep 10
    done
    # Perform post-upgrade-login actions
    MigrationComplete
fi

exit 0
