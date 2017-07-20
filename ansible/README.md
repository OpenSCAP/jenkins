= Apply on Jenkins master =

ansible-playbook -i inventory.ini ./master.yml

= Apply on Jenkins workers =

ansible-playbook -i inventory.ini ./worker.yml
