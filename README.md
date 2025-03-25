Ansible Folder

run_tmsh.yml - Ansible Playbook to run arbitrary tmsh commands using the bigip_command module:

This playbook imports a list of tmsh commands you wish to run in sequence from a YML file that you specify. 
It will output the command results into a filename of your choosing on your local machine, in a subdirectory called output_files.

The example command file (samplecommands.yml) provided executes 'tmsh show sys performance throughput historical' and 'tmsh show sys performance system historical'
These lines can be altered to the tmsh commands of your choosing (leave off "tmsh" within the command file).

Usage: 
ansible-playbook run_tmsh.yml -i (your inventory file) -e "filename=(your desired output filename)" -e "command_file=(your YML file containing the list of tmsh commands)


Bash Folder

bash_tmsh.sh - Bash script to run arbitrary tmsh commands on a remote host of your choosing via SSH

Similarly to the Ansible playbook, this bash script will take a list of tmsh commands provided in a separate text file and run them against a remote BIG-IP. 

Usage:
./bash_tmsh.sh commands.txt
