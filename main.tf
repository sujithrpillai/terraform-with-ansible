terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.4.0"
    }
}
}
provider "docker" {
  host = "unix:///var/run/docker.sock"
}

variable "content_from_terraform_variable" {
  description = "Content_passed_from_terraform"
  type        = string
  
}
variable "create" {
  description = "Flag to determine whether to run ansible_create"
  type        = bool
  default     = true
}
variable "destroy" {
  description = "Flag to determine whether to run ansible_destroy"
  type        = bool
  default     = false
}
resource "random_string" "example" {
  length  = 8
  special = false
}
resource "local_file" "example" {
  filename = "${path.module}/output.json"
  content  = jsonencode({
    generated_content = "Content written by terraform in to output.json",
  })
}

# Read an existing JSON file and use its content
data "local_file" "existing_json" {
  filename = "${path.module}/input.json"
}

resource "docker_container" "ansible_create" {
  count = var.create ? 1 : 0
  name  = "ansible-create"
  image = "alpine/ansible:latest"
  rm = true
  volumes {
    host_path      = "/Users/srpillai/GitHub/AWS ROI Training/automation/ansible"
    container_path = "/ansible"
  }

  command = [
    "ansible-playbook",
    "-i",
    "/ansible/inventory",
    "/ansible/playbook-create.yaml",
    "--extra-vars",
    "{\"content_from_terraform\":\"{ 'variable value': '${var.content_from_terraform_variable}', 'output file value': '${jsondecode(local_file.example.content).generated_content}', 'Input file value' : '${jsondecode(data.local_file.existing_json.content).content_by_input}' }\"}",
  ]
}

resource "docker_container" "ansible_destroy" {
  count = var.destroy ? 1 : 0
  name  = "ansible-destroy"
  image = "alpine/ansible:latest"
  rm = true
  volumes {
    host_path      = "/Users/srpillai/GitHub/AWS ROI Training/automation/ansible"
    container_path = "/ansible"
  }

  command = [
    "ansible-playbook",
    "-i",
    "/ansible/inventory",
    "/ansible/playbook-destroy.yaml",
    "--extra-vars",
    "{\"content_from_terraform\":\"{ 'variable value': '${var.content_from_terraform_variable}', 'output file value': '${jsondecode(local_file.example.content).generated_content}', 'Input file value' : '${jsondecode(data.local_file.existing_json.content).content_by_input}' }\"}",
  ]
}

