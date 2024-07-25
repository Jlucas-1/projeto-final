provider "azurerm" {
  features {}
}

# Definir o grupo de recursos
resource "azurerm_resource_group" "rg" {
  name     = "project_final_rg"
  location = "East US"
}

# Definir a rede virtual
resource "azurerm_virtual_network" "vnet" {
  name                = "project_final_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Definir a sub-rede
resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Definir o IP público
resource "azurerm_public_ip" "public_ip" {
  name                = "project_final_public_ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Definir a interface de rede
resource "azurerm_network_interface" "nic" {
  name                = "project_final_nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Definir a máquina virtual
resource "azurerm_virtual_machine" "vm" {
  name                  = "project_final_vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_B1s"

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "azureuser"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "testing"
  }
}

# Definir a extensão da máquina virtual para instalar Docker
resource "azurerm_virtual_machine_extension" "vm_extension" {
  name                 = "install-docker"
  virtual_machine_id   = azurerm_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "bash /var/lib/waagent/custom-script/download/0/cloud-init.sh"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
        "fileUris": ["https://raw.githubusercontent.com/Jlucas-1/projeto-final/main/cloud-init.sh"]
    }
PROTECTED_SETTINGS
}

