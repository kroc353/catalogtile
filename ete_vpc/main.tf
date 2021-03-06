terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.20.1"
    }
  }
}

provider "ibm" {
  generation       = 2
  region           = var.region
  ibmcloud_timeout = 300
}

resource "ibm_is_vpc" "vpc" {
  name = "${var.vpc_name}-vpc"
  #address_prefix_management = "manual"
}
