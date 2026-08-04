locals {
  templates = {

    ubuntu-22 = {
      vmid       = 9991
      os         = "linux"
      cloud_init = true
      connection = "ssh"
      username   = "ubuntu"
    }

    windows-2022 = {
      vmid       = 9992
      os         = "windows"
      cloud_init = false
      connection = "winrm"
      username   = "Administrator"
    }

    opnsense-25 = {
      vmid       = 9993
      os         = "bsd"
      cloud_init = false
      connection = "ssh"
      username   = "root"
    }
  }

  selected_template = local.templates[var.template]
}
