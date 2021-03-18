# terraform-azure
In the one_vm folder, after running the command "apply", you have to copy the ssh private key into tls_private_key file. After that you can connect to your remote vm in this way:

ssh -i tls_private_key pardo@<ip-address>
