echo "Start process CloudbaseInitSetup_Stable_x64.msi"
start-process -FilePath 'c:\setup\CloudbaseInitSetup_Stable_x64.msi' -ArgumentList '/qn /l*v C:\setup\cloud-init.log' -Wait
