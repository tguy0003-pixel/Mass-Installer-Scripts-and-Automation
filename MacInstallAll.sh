#!/bin/bash
# Enterprise macOS Deployment Script
# Must execute with SUDO privileges

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SERVER_IP="YOUR.SERVER.IP"
SHARE_NAME="SoftwareDeployment"
REMOTE_PKG_PATH="/Packages/macOS_EnterpriseSuite_Universal.pkg"

# System Policy Config (e.g., forced browser extensions)
SECURITY_EXT_ID="your_target_extension_id_here"
CHROME_EXT_DIR="/Library/Application Support/Google/Chrome/External Extensions"

echo "=== STARTING macOS ENDPOINT STAGING ==="

# --- PART 1: POLICY ENFORCEMENT ---
echo "--- PHASE 1: Injecting Security Policies ---"
if [ ! -d "$CHROME_EXT_DIR" ]; then
    mkdir -p "$CHROME_EXT_DIR"
    chmod 755 "$CHROME_EXT_DIR"
fi
echo "{
  \"external_update_url\": \"https://clients2.google.com/service/update2/crx\"
}" > "$CHROME_EXT_DIR/$SECURITY_EXT_ID.json"
chmod 644 "$CHROME_EXT_DIR/$SECURITY_EXT_ID.json"
echo "   [+] Security extension policy injected."

# --- PART 2: LOCAL MEDIA STAGING ---
echo "--- PHASE 2: Executing Local Payloads ---"
for INSTALLER in "$SCRIPT_DIR"/*; do
    case $INSTALLER in
        *.pkg)
            echo "Processing PKG: $(basename "$INSTALLER")..."
            installer -pkg "$INSTALLER" -target /
            ;;
        *.dmg)
            echo "Processing DMG: $(basename "$INSTALLER")..."
            
            # 1. Create a known, static temporary mount directory
            TEMP_MOUNT="/tmp/dmg_staging_env"
            mkdir -p "$TEMP_MOUNT"

            # 2. Force mount the DMG silently to bypass interactive prompts
            hdiutil attach "$INSTALLER" -mountpoint "$TEMP_MOUNT" -nobrowse -quiet
            
            # 3. Locate the nested .app binary
            FOUND_APP=$(find "$TEMP_MOUNT" -maxdepth 1 -name "*.app" -print -quit)
            
            if [ -z "$FOUND_APP" ]; then
                echo "   [!] Error: No valid .app binary found in $(basename "$INSTALLER")."
            else
                APP_NAME=$(basename "$FOUND_APP")
                echo "   Binary located: $APP_NAME. Migrating to /Applications..."
                # Copy to Application directory, forcing overwrite if updating
                cp -R "$FOUND_APP" "/Applications/"
                echo "   [+] Successfully installed $APP_NAME"
            fi
            
            # 4. Clean up the mount point forcefully
            hdiutil detach "$TEMP_MOUNT" -force -quiet
            ;;
    esac
done

# --- PART 3: SECURE NETWORK PAYLOAD ---
echo "--- PHASE 3: Authenticated Remote Installation ---"
MOUNT_POINT="/Volumes/SecureNetInstall"
mkdir -p "$MOUNT_POINT"

echo "----------------------------------------------------------------"
echo "Authentication Required for Secure Subnet Access."
echo "Please enter your administrative network username."
echo "----------------------------------------------------------------"
read -p "Admin Username: " NET_USER

echo "Mounting encrypted share at smb://$NET_USER@$SERVER_IP/$SHARE_NAME..."
echo "(Note: Type password silently when prompted by the OS)"

mount_smbfs "smb://$NET_USER@$SERVER_IP/$SHARE_NAME" "$MOUNT_POINT"

FULL_PATH="$MOUNT_POINT$REMOTE_PKG_PATH"

if [ -f "$FULL_PATH" ]; then
    echo "   [+] Remote payload verified. Commencing background installation..."
    installer -pkg "$FULL_PATH" -target /
    echo "   [+] Remote installation complete."
else
    echo "   [!] Error: Remote payload failed to resolve. Check permissions."
fi

# Cleanup
umount "$MOUNT_POINT"
rmdir "$MOUNT_POINT"

echo "=== DEPLOYMENT SEQUENCE COMPLETE ==="
