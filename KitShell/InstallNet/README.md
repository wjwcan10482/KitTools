apt update -y;apt install sshpass -y

chmod a+x InstallNET.sh

./InstallNET.sh -k juniper -v aarch64 -a --ip-addr 178.102.128.82 --ip-mask 255.255.255.0 --ip-gate 178.102.128.1
