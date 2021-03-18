# Configure the Microsoft Azure Provider
provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you're using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "prdterraformgroup" {
    name     = "prdResourceGroup"
    location = "westus"

    tags = {
        environment = "Pardo Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "prdterraformnetwork" {
    name                = "prdVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "westus"
    resource_group_name = azurerm_resource_group.prdterraformgroup.name

    tags = {
        environment = "Pardo Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "prdterraformsubnet" {
    name                 = "prdSubnet"
    resource_group_name  = azurerm_resource_group.prdterraformgroup.name
    virtual_network_name = azurerm_virtual_network.prdterraformnetwork.name
    address_prefixes       = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "prdterraformpublicip" {
    name                         = "prdPublicIP"
    location                     = "westus"
    resource_group_name          = azurerm_resource_group.prdterraformgroup.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Pardo Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "prdterraformnsg" {
    name                = "prdNetworkSecurityGroup"
    location            = "westus"
    resource_group_name = azurerm_resource_group.prdterraformgroup.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Pardo Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "prdterraformnic" {
    name                      = "prdNIC"
    location                  = "westus"
    resource_group_name       = azurerm_resource_group.prdterraformgroup.name

    ip_configuration {
        name                          = "prdNicConfiguration"
        subnet_id                     = azurerm_subnet.prdterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.prdterraformpublicip.id
    }

    tags = {
        environment = "Pardo Demo"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.prdterraformnic.id
    network_security_group_id = azurerm_network_security_group.prdterraformnsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.prdterraformgroup.name
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "prdstorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.prdterraformgroup.name
    location                    = "westus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Pardo Demo"
    }
}

# Create (and display) an SSH key
resource "tls_private_key" "pardo_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}
output "tls_private_key" { value = tls_private_key.pardo_ssh.private_key_pem }

# Create virtual machine
resource "azurerm_linux_virtual_machine" "prdterraformvm" {
    name                  = "prdVM"
    location              = "westus"
    resource_group_name   = azurerm_resource_group.prdterraformgroup.name
    network_interface_ids = [azurerm_network_interface.prdterraformnic.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "prdOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "prdvm"
    admin_username = "pardo"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "pardo"
        public_key     = tls_private_key.pardo_ssh.public_key_openssh
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.prdstorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Pardo Demo"
    }
}