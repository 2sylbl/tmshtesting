run_tmsh.yml - Ansible Playbook to run arbitrary tmsh commands using the bigip_command module:

This playbook imports a list of tmsh commands you wish to run in sequence from a YML file that you specify. 
It will output the command results into a filename of your choosing on your local machine, in a subdirectory called output_files.

The example command file (samplecommands.yml) provided executes 'tmsh show sys performance throughput historical' and 'tmsh show sys performance system historical'
These lines can be altered to the tmsh commands of your choosing (leave off "tmsh" within the command file).

Usage: 
ansible-playbook run_tmsh.yml -i (your inventory file) -e "filename=(your desired output filename)" -e "command_file=(your YML file containing the list of tmsh commands)
