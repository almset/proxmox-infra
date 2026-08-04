# infra/terragrunt.hcl

# Global settings
terraform {
  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()
    
    optional_var_files = [
      find_in_parent_folders("common.tfvars", "ignore")
    ]
  }
}

locals {
  state_name = replace(path_relative_to_include(), "/", "-")
}

# GitLab backend configuration
remote_state {
  backend = "http"
  
  config = {
    address         = "http://10.0.10.11/api/v4/projects/2/terraform/state/${local.state_name}"
    lock_address    = "http://10.0.10.11/api/v4/projects/2/terraform/state/${local.state_name}/lock"
    unlock_address  = "http://10.0.10.11/api/v4/projects/2/terraform/state/${local.state_name}/lock"

    username    = "root"
    password    = "glpat-GZqeJtXgknQhJu-7c43Av286MQp1OjExCA.01.0y1y2zglc"
    # for the future -  password = get_env("GITLAB_TOKEN")    

    skip_cert_verification = false
    lock_method   = "POST"
    unlock_method = "DELETE"
    
    retry_wait_min = 5

  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

