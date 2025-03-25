This repository contains two methods of running tmsh commands against a remote BIG-IP - a simple bash shell script or an Ansible playbook. They are both configured so that the user simply needs to supply a list of the tmsh commands for any given use case they wish to test.

*Note: The user that is provided, either in the Bash script prompt, or the Ansible inventory, must have **Advanced Shell** access on the BIG-IP, because both methods use SSH to log in and run the commands.*

Please edit any IP addresses in the provided use case testing files (txt or yml) before running them, so they have proper addressing for your testing location and don't duplicate any existing ones in your lab environment.

**Bash Folder**

bash_tmsh.sh - Bash script to run arbitrary tmsh commands on a remote host of your choosing via SSH

This bash script will take a list of tmsh commands provided in a separate text file and run them against a remote BIG-IP. (The commands in the text file should not include the *tmsh* at the beginning of each line)

*Usage:*
./bash_tmsh.sh commands.txt

You will be prompted for the username and IP address of the system you wish to run the commands against, and you will provide a name for the output file, which will be created in an output_files directory underneath the directory you're running the script from. 

**Ansible Folder**

run_tmsh.yml - Ansible Playbook to run arbitrary tmsh commands using the bigip_command module:

Similarly to the bash script, this playbook imports a list of tmsh commands you wish to run in sequence from a YML command file that you specify. 
It will output the command results into a filename of your choosing on your local machine, in a subdirectory called output_files.

The example command file (samplecommands.yml) provided executes 'tmsh show sys performance throughput historical' and 'tmsh show sys performance system historical'
These lines can be altered to the tmsh commands of your choosing (leave off *tmsh* within the command file).

*Usage:* 
ansible-playbook run_tmsh.yml -i (your inventory file) -e "filename=(your desired output filename)" -e "command_file=(your YML file containing the list of tmsh commands)

