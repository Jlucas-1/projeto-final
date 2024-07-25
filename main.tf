# Configuração do provedor Azure
provider "azurerm" {
  features {}

  # Variáveis para autenticação na Azure
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

# Criação do grupo de recursos
resource "azurerm_resource_group" "resource_group" {
  name     = "project_final_rg"
  location = "West Europe"
}

# Criação da rede virtual
resource "azurerm_virtual_network" "virtual_network" {
  name                = "project_final_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

# Criação da sub-rede
resource "azurerm_subnet" "subnet" {
  name                 = "project_final_subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Criação do endereço IP público
resource "azurerm_public_ip" "public_ip" {
  name                = "project_final_public_ip"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Dynamic"
}

# Criação da interface de rede
resource "azurerm_network_interface" "network_interface" {
  name                = "project_final_nic"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Criação da máquina virtual
resource "azurerm_virtual_machine" "virtual_machine" {
  depends_on           = [azurerm_public_ip.public_ip] # Garantir que o IP público seja criado antes da VM
  name                 = "project_final_vm"
  location             = azurerm_resource_group.resource_group.location
  resource_group_name  = azurerm_resource_group.resource_group.name
  network_interface_ids = [azurerm_network_interface.network_interface.id]
  vm_size              = "Standard_B1s"  # Tamanho da VM (Standard_B1s é um tamanho básico e econômico)

  # Configuração do perfil do sistema operacional
  os_profile {
    computer_name  = "hostname"  # Nome do computador
    admin_username = "azureuser" # Nome de usuário do administrador
    admin_password = "Password1234!" # Senha do administrador
  }

  os_profile_linux_config {
    disable_password_authentication = false # Desativar a autenticação por senha (false = permitir)
  }

  # Configuração do disco do sistema operacional
  storage_os_disk {
    name              = "osdisk"  # Nome do disco do SO
    caching           = "ReadWrite"  # Cache de leitura/escrita
    create_option     = "FromImage"  # Criar a partir da imagem
    managed_disk_type = "Standard_LRS" # Tipo de disco gerenciado (Standard_LRS é o armazenamento localmente redundante padrão)
  }

  # Imagem do sistema operacional
  storage_image_reference {
    publisher = "Canonical"  # Editora da imagem (Canonical é a editora do Ubuntu)
    offer     = "UbuntuServer"  # Oferta da imagem (UbuntuServer é a oferta do servidor Ubuntu)
    sku       = "18.04-LTS"  # SKU da imagem (18.04-LTS é a versão de longo prazo do Ubuntu)
    version   = "latest"  # Versão da imagem (latest é a versão mais recente)
  }
}

# Criação do grupo de segurança de rede
resource "azurerm_network_security_group" "network_security_group" {
  name                = "project_final_nsg"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  # Regras de segurança para SSH
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

  # Regras de segurança para HTTP
  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associação da interface de rede com o grupo de segurança de rede
resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id      = azurerm_network_interface.network_interface.id
  network_security_group_id = azurerm_network_security_group.network_security_group.id
}

# Extensão da máquina virtual para instalar Docker
resource "azurerm_virtual_machine_extension" "vm_extension" {
  name                 = "install-docker"
  virtual_machine_id   = azurerm_virtual_machine.virtual_machine.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  settings = <<SETTINGS
  {
    "fileUris": ["https://github.com/Jlucas-1/projeto-final/blob/main/cloud-init.sh"],
    "commandToExecute": "bash cloud-init.sh"
  }
SETTINGS
}

# Saída do endereço IP público da VM
output "public_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
}
