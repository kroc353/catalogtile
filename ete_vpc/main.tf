variable "ssh_key" {}
variable "image_name" {}
variable "privileged_resource_group" {}
variable "vpc_name" {}
variable "zone_1" {}
variable "zone_2" {}
variable "zone_3" {}
variable "region" {}

provider "ibm" {
  generation = 2
  region     = var.region
}

#locals {
#  BASENAME = "ko-tf"
#  ZONE     = "us-south-1"
#}

resource "ibm_is_vpc" "vpc" {
  name                      = "${var.vpc_name}-vpc"
  address_prefix_management = "manual"
  #default_security_group = ibm_is_security_group.sg1.id
  #default_network_acl    = ibm_is_network_acl.acl1.id
}

resource ibm_is_vpc_address_prefix "prefix1" {
  name = "${var.vpc_name}-prefix1"
  zone = var.zone_1
  vpc  = ibm_is_vpc.vpc.id
  cidr = "10.9.9.0/24"
}

resource ibm_is_vpc_address_prefix "prefix2" {
  name = "${var.vpc_name}-prefix2"
  zone = var.zone_2
  vpc  = ibm_is_vpc.vpc.id
  cidr = "10.9.10.0/24"
}

resource ibm_is_vpc_address_prefix "prefix3" {
  name = "${var.vpc_name}-prefix3"
  zone = var.zone_3
  vpc  = ibm_is_vpc.vpc.id
  cidr = "10.9.11.0/24"
}

resource "ibm_is_subnet" "subnet1" {
  name            = "${var.vpc_name}-subnet1"
  vpc             = ibm_is_vpc.vpc.id
  zone            = var.zone_1
  ipv4_cidr_block = ibm_is_vpc_address_prefix.prefix1.cidr
}

resource "ibm_is_subnet" "subnet2" {
  name            = "${var.vpc_name}-subnet2"
  vpc             = ibm_is_vpc.vpc.id
  zone            = var.zone_2
  ipv4_cidr_block = ibm_is_vpc_address_prefix.prefix2.cidr
}

resource "ibm_is_subnet" "subnet3" {
  name            = "${var.vpc_name}-subnet3"
  vpc             = ibm_is_vpc.vpc.id
  zone            = var.zone_3
  ipv4_cidr_block = ibm_is_vpc_address_prefix.prefix3.cidr
}

resource "ibm_is_subnet_network_acl_attachment" attach {
  subnet      = ibm_is_subnet.subnet1.id
  network_acl = ibm_is_network_acl.netacl1.id
}

resource "ibm_is_subnet_network_acl_attachment" attach2 {
  subnet      = ibm_is_subnet.subnet2.id
  network_acl = ibm_is_network_acl.netacl1.id
}

resource "ibm_is_subnet_network_acl_attachment" attach3 {
  subnet      = ibm_is_subnet.subnet3.id
  network_acl = ibm_is_network_acl.netacl1.id
}

resource "ibm_is_network_acl" "netacl1" {
  name           = "${var.vpc_name}-netacl1"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = var.privileged_resource_group
  rules {
    name        = "outbound-c2-deny-1"
    action      = "deny"
    source      = "0.0.0.0/0"
    destination = "165.160.13.20/32"
    direction   = "outbound"
  }
  rules {
    name        = "outbound-c2-deny-2"
    action      = "deny"
    source      = "0.0.0.0/0"
    destination = "165.160.15.20/32"
    direction   = "outbound"
  }
  rules {
    name        = "outbound-all-any"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "outbound"
  }
  rules {
    name        = "inbound-telnet-deny"
    action      = "deny"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "inbound"
    tcp {
      port_max = 23
      port_min = 23
    }
  }
  rules {
    name        = "inbound-smb-deny"
    action      = "deny"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "inbound"
    tcp {
      port_max = 445
      port_min = 445
    }
  }
  rules {
    name        = "inbound-web-deny"
    action      = "deny"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "inbound"
    tcp {
      port_max = 80
      port_min = 80
    }
  }
  rules {
    name        = "inbound-udp-deny"
    action      = "deny"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "inbound"
    udp {
    }
  }
  rules {
    name        = "inbound-all-permit"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "inbound"
  }
}

data "ibm_is_image" "image" {
  name = var.image_name
}

data "ibm_is_ssh_key" "ssh_key_id" {
  name = var.ssh_key
}

resource "ibm_is_instance" "vsi1" {
  name    = "${var.vpc_name}-vsi1"
  vpc     = ibm_is_vpc.vpc.id
  zone    = var.zone_1
  keys    = [data.ibm_is_ssh_key.ssh_key_id.id]
  image   = data.ibm_is_image.image.id
  profile = "cx2-2x4"

  primary_network_interface {
    subnet          = ibm_is_subnet.subnet1.id
    security_groups = [ibm_is_security_group.sg1.id]
  }
}

resource "ibm_is_instance" "vsi3" {
  name    = "${var.vpc_name}-vsi3"
  vpc     = ibm_is_vpc.vpc.id
  zone    = var.zone_3
  keys    = [data.ibm_is_ssh_key.ssh_key_id.id]
  image   = data.ibm_is_image.image.id
  profile = "cx2-2x4"

  primary_network_interface {
    subnet          = ibm_is_subnet.subnet3.id
    security_groups = [ibm_is_security_group.sg1.id]
  }
}

resource "ibm_is_floating_ip" "fip1" {
  name   = "${var.vpc_name}-fip1"
  target = ibm_is_instance.vsi1.primary_network_interface[0].id
}

resource "ibm_is_security_group" "sg1" {
  name           = "${var.vpc_name}-sg1"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = var.privileged_resource_group
}

# start of egress security rules
resource "ibm_is_security_group_rule" "egress_all_any" {
  group     = ibm_is_security_group.sg1.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# start of ingress security rules
resource "ibm_is_security_group_rule" "ingress_all_sg1" {
  group     = ibm_is_security_group.sg1.id
  direction = "inbound"
  remote    = ibm_is_security_group.sg1.id
}

resource "ibm_is_security_group_rule" "ingress_ssh_kevin1" {
  group     = ibm_is_security_group.sg1.id
  direction = "inbound"
  remote    = "73.126.130.115"

  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "ingress_tcp_bluepop" {
  group     = ibm_is_security_group.sg1.id
  direction = "inbound"
  remote    = "129.41.86.0/23"

  tcp {
    port_min = 1
    port_max = 65535
  }
}

resource "ibm_is_security_group_rule" "ingress_tcp_bouldervpn" {
  group     = ibm_is_security_group.sg1.id
  direction = "inbound"
  remote    = "32.97.110.0/24"

  tcp {
    port_min = 1
    port_max = 65535
  }
}

resource "ibm_is_security_group_rule" "ingress_tcp_portsmouthvpn" {
  group     = ibm_is_security_group.sg1.id
  direction = "inbound"
  remote    = "195.212.29.0/25"

  tcp {
    port_min = 1
    port_max = 65535
  }
}

resource "ibm_is_security_group_rule" "ingress_tcp_amsterdamvpn" {
  group     = ibm_is_security_group.sg1.id
  direction = "inbound"
  remote    = "129.41.46.0/24"

  tcp {
    port_min = 1
    port_max = 65535
  }
}

resource "ibm_is_security_group_rule" "ingress_tcp_bangalorevpn" {
  group     = ibm_is_security_group.sg1.id
  direction = "inbound"
  remote    = "129.41.84.0/23"

  tcp {
    port_min = 1
    port_max = 65535
  }
}

resource "ibm_is_security_group_rule" "ingress_tcp_rcxproxy" {
  group     = ibm_is_security_group.sg1.id
  direction = "inbound"
  remote    = "129.34.20.19"

  tcp {
    port_min = 1
    port_max = 65535
  }
}

resource "ibm_is_security_group_rule" "ingress_bigfix" {
  group     = ibm_is_security_group.sg1.id
  direction = "inbound"
  remote    = "129.34.20.42"

  tcp {
    port_min = 52311
    port_max = 52311
  }
}


output "sshcommand" {
  value = "ssh root@${ibm_is_floating_ip.fip1.address}"
}

output "vpcid" {
  value = "The VPC ID is ${ibm_is_vpc.vpc.id}"
}
