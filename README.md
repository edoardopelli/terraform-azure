# terraform-azure
In the one_vm folder, after the command "apply", you have to copy the ssh private key into tls_private_key file. After that you can connect to ypur remote vm in this way:

ssh -i tls_private_key pardo@<ip-address>
