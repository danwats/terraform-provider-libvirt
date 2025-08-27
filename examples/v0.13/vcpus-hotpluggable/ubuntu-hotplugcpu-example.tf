terraform {
 required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      #version = "0.6.2"
    }
  }
}

# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "ubuntu" {
  name = "ubuntu"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-ubuntu"
}


# We fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "ubuntu-qcow2" {
  name   = "ubuntu-qcow2"
  pool   = libvirt_pool.ubuntu.name
  source = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  format = "qcow2"
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.ubuntu.name
}

resource "libvirt_domain" "ubuntu-vm" {
  name = "ubuntu-test"

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  # will connect to guest and will automatically change cpus
  # requires the qemu-guest-agent package
  # and enabled in systemd
  hotplug_guest_cpu=true
  vcpu {
    # set the min and max cpu values
    set = "0-7"
    # set this as the highest
    value = 8
    # set this as the cpu count to use
    current = 3
  }

  disk {
    volume_id = libvirt_volume.ubuntu-master.id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = 0
  }
}

