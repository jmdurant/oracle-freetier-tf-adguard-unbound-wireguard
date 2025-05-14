provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.oracle_api_key_fingerprint
  private_key_path = var.oracle_api_private_key_path
  region           = var.region
}

# create compartment
# resource "oci_identity_compartment" "adguard_compartment" {
#   name           = "adguard"
#   description    = "compartment for adguard"
#   compartment_id = var.tenancy_ocid
#   enable_delete  = false // true will cause this compartment to be deleted when running `terrafrom destroy`
# }

# data "oci_identity_compartments" "adguard_compartments" {
#   compartment_id = oci_identity_compartment.adguard_compartment.compartment_id
#   filter {
#     name   = "name"
#     values = ["adguard"]
#   }
# }

# output "compartment_name" {
#   value = data.oci_identity_compartments.adguard_compartments.compartments[0].name
# }
# output "adguard_compartment_ocid" {
#   value = data.oci_identity_compartments.adguard_compartments.compartments[0].id
# }

# create groups
# resource "oci_identity_dynamic_group" "adguard_dyn_group" {
#   compartment_id = var.tenancy_ocid
#   name           = "adguard_dyn_group"
#   description    = "dynamic group created for wirehole compartment"
#   matching_rule  = "ANY {instance.compartment.id = '${data.oci_identity_compartments.adguard_compartments.compartments[0].id}'}"
# }

# data "oci_identity_dynamic_groups" "adguard_dyn_group" {
#   compartment_id = var.tenancy_ocid
#   filter {
#     name   = "id"
#     values = [oci_identity_dynamic_group.adguard_dyn_group.id]
#   }
# }

# policies
# resource "oci_identity_policy" "adguard-dyn-policy-1" {
#   name           = "adguard-dyn-policy-1"
#   description    = "dynamic policy created for adguard"
#   compartment_id = data.oci_identity_compartments.adguard_compartments.compartments[0].id
#   statements = [
#     "Allow dynamic-group ${oci_identity_dynamic_group.adguard_dyn_group.name} to read instances in compartment ${data.oci_identity_compartments.adguard_compartments.compartments[0].name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.adguard_dyn_group.name} to inspect instances in compartment ${data.oci_identity_compartments.adguard_compartments.compartments[0].name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.adguard_dyn_group.name} to manage objects in compartment ${data.oci_identity_compartments.adguard_compartments.compartments[0].name}",
#   ]
# }

# data "oci_identity_policies" "adguard-dny-policies-1" {
#   compartment_id = data.oci_identity_compartments.adguard_compartments.compartments[0].id
#   filter {
#     name   = "id"
#     values = [oci_identity_policy.adguard-dyn-policy-1.id]
#   }
# }

# output "dynamicPolicies" {
#   value = data.oci_identity_policies.adguard-dny-policies-1.policies[0].statements
# }
# create buckets
# data "oci_objectstorage_namespace" "ns" {}
# resource "oci_objectstorage_bucket" "adguard_bucket" {
#   compartment_id = data.oci_identity_compartments.adguard_compartments.compartments[0].id
#   name = "ADGUARD_BUCKET"
#   namespace = data.oci_objectstorage_namespace.ns.namespace
# }

# resource "oci_objectstorage_bucket" "adguard_archive_bucket" {
#   compartment_id = data.oci_identity_compartments.adguard_compartments.compartments[0].id
#   name = "ADGUARD_ARCHIVE_BUCKET"
#   namespace = data.oci_objectstorage_namespace.ns.namespace
# }

data "oci_objectstorage_namespace" "ns" {}

# VCN
resource "oci_core_vcn" "adguard_vcn" {
  cidr_block     = var.vcn_cidr_block
  compartment_id = var.tenancy_ocid # Use root compartment or update as needed
  display_name   = "AdguardVCN"
  dns_label      = "AdguardVCN"
}

resource "oci_core_subnet" "adguard_subnet" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  cidr_block          = "10.1.0.0/24"
  display_name        = "AdguardSubnet"
  dns_label           = "AdguardSubnet"
  security_list_ids   = [oci_core_security_list.adguard_security_list.id]
  compartment_id      = var.tenancy_ocid # Use root compartment or update as needed
  vcn_id              = oci_core_vcn.adguard_vcn.id
  route_table_id      = oci_core_vcn.adguard_vcn.default_route_table_id
  dhcp_options_id     = oci_core_vcn.adguard_vcn.default_dhcp_options_id
}

resource "oci_core_internet_gateway" "adguard_internet_gateway" {
  compartment_id = var.tenancy_ocid # Use root compartment or update as needed
  display_name   = "Adguard_IG"
  vcn_id         = oci_core_vcn.adguard_vcn.id
}

resource "oci_core_default_route_table" "adguard_route_table" {
  manage_default_resource_id = oci_core_vcn.adguard_vcn.default_route_table_id
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.adguard_internet_gateway.id
  }
}

resource "oci_core_security_list" "adguard_security_list" {
  compartment_id = var.tenancy_ocid # Use root compartment or update as needed
  vcn_id         = oci_core_vcn.adguard_vcn.id
  display_name   = "Adguard Security List"

  // allow outbound tcp traffic on all ports
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  // allow inbound ssh traffic from a all ports to port
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      source_port_range {
        min = 1
        max = 65535
      }
      min = 22
      max = 22
    }
  }

  // allow inbound udp traffic from all ports to 51820
  ingress_security_rules {
    protocol  = "17" // udp
    source    = "0.0.0.0/0"
    stateless = false
    udp_options {
      source_port_range {
        min = 1
        max = 65535
      }
      min = 51820
      max = 51820
    }
  }

  // allow inbound icmp traffic of a specific type
  ingress_security_rules {
    description = "icmp_inbound"
    protocol    = 1
    source      = "0.0.0.0/0"
    stateless   = false
    icmp_options {
      type = 3
      code = 4
    }
  }
}

# Commented out AdGuard instance and provisioners
# resource "oci_core_instance" "adguard_instance" { ... }
# resource "oci_core_instance_console_connection" "adguard_instance_console_connection" { ... }
# data "oci_core_vnic_attachments" "instance_vnics" { ... }
# data "oci_core_vnic" "instance_vnic" { ... }
# output "connect_with_ssh" { ... }
# output "connect_with_vnc" { ... }
# resource "null_resource" "adguard_configure" { ... }

# Example: Add your new null_resource for WireGuard/OpenEMR deployment here
# resource "null_resource" "wireguard_openemr_configure" {
#   triggers = {
#     state = "RUNNING"
#   }
#   connection {
#     type        = "ssh"
#     host        = <your_instance_public_ip>
#     user        = "ubuntu"
#     port        = "22"
#     private_key = file(var.ssh_private_key_path)
#   }
#   provisioner "file" {
#     source      = "resources/docker-wireguard-unbound.zip"
#     destination = "/home/ubuntu/docker-wireguard-unbound.zip"
#   }
#   provisioner "file" {
#     source      = "resources/docker_wg_openemr_install.sh"
#     destination = "/tmp/docker_wg_openemr_install.sh"
#   }
#   provisioner "remote-exec" {
#     inline = [
#       "unzip -o /home/ubuntu/docker-wireguard-unbound.zip -d /home/ubuntu/",
#       "chmod uga+x /tmp/docker_wg_openemr_install.sh",
#       "/bin/bash -x /tmp/docker_wg_openemr_install.sh"
#     ]
#   }
# }

