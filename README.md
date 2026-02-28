# Mass-Installer-Scripts-and-Automation
CROSS-PLATFORM AUTOMATION SCRIPTS

==========================================

A collection of Windows and macOS scripts designed to automate the provisioning and software deployment of enterprise environments. These scripts combine local USB installation media with network-share downloads to radpidly setup enterprise devices.

IMPORTANT: WHITE-LABEL SECURITY DISCLAIMER

To adhere to enterprise security and data privacy standards, the code in this repository has been heavily "white-labeled." All proprietary IP addresses, organizational domain names, specific software packages, and internal network share paths have been removed and replaced with generic placeholder categories.

You cannot run these scripts out-of-the-box in a new environment. If you intend to use this code for your own infrastructure, you must edit the source files:

1. Update the Server IP and Network Share variables at the top of both scripts (e.g., SERVER_IP="YOUR.SERVER.IP").

2. Modify the exception-handling loops in the script bodies to match the exact string names of your organization's .exe, .msi, .pkg, or .dmg payloads.

3. Replace the placeholder JSON extension IDs (used for Chrome Security Policies in the macOS script) with your specific organizational IDs.

WINDOWS DEPLOYMENT (installall.ps1 & RunME.bat)

The Windows suite uses a Batch file wrapper to bypass PowerShell execution policies and enforce administrator privileges before launching the script.

• SILENT & INTERACTIVE ROUTING:
Automatically loops through the local \Installers directory. It executes standard .exe and .msi files silently, while intentionally pausing execution for complex, interactive installers to allow the technician to input any needed inputs or parameters.

• NETWORK PAYLOAD DELIVERY:
Reaches out to enterprise network shares (UNC paths) to silently install massive software packages directly from the server, bypassing local USB storage limits.

USAGE (WINDOWS):
STEP 1: Plug the deployment USB into the target machine.
STEP 2: Double-click "RunME.bat".
STEP 3: Accept the UAC Admin prompt. The PowerShell script will automatically take over, elevate privileges, and begin installing.

macOS DEPLOYMENT (installall.sh)

• DYNAMIC DMG EXTRACTION:
Instead of relying on standard PKG installers, the script intelligently creates hidden temporary mount points, force-mounts .dmg files, locates the nested .app binaries, and copies them to the /Applications directory before unmounting the volume.

• AUTHENTICATED SMB MOUNTING:
Prompts the technician for their network credentials, mounts an encrypted SMB share (smb://) via the terminal, executes the remote network installer, and cleanly unmounts the volume upon completion.

USAGE (macOS):
STEP 1: Log in as the Local Administrator.
STEP 2: Open Terminal.
STEP 3: Type "sudo bash " (ensure there is a trailing space).
STEP 4: Drag and drop the .sh file into the Terminal window to auto-fill the path, then press Enter.
STEP 5: Provide network credentials when prompted for the SMB share mount.

