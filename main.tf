provider null {
  version = "~>2.1"
}

provider external {
  version = "~>1.1"
}

provider template {
  version = "~>2.1"
}

provider local {
  version = "~>1.2"
}

provider random {
  version = "~>2.1"
}

locals {
  dir_prefix   = "${path.module}/.supervisor"
  program_name = "jupyterhub-singleuser"
}

locals {
  jupyter_ip   = "127.0.0.1"
  jupyter_port = "${random_integer.jupyter_port.result}"
}

resource "random_integer" "jupyter_port" {
  min     = 49152
  max     = 65535
  keepers = {
    # Generate a new integer each time we change the environment variables
    env = "${var.env["JUPYTERHUB_API_TOKEN"]}"
  }
}

//
// Convert map(k,v) to string list [k1=v1,...,kn=vn]
locals {
  env_keys = "${keys(var.env)}"
}
data "template_file" "environment" {
  count = "${length(local.env_keys)}"
  template = "$${key}=\"$${value}\""
  vars = {
    key = "${local.env_keys[count.index]}"
    value = "${lookup(var.env, local.env_keys[count.index])}"
  }
}

data "template_file" "supervisord_conf" {
  template = "${file("${path.module}/template/supervisord.conf")}"
  vars = {
    var_log     ="${local.dir_prefix}"
    var_run     ="${local.dir_prefix}"
    socket_file ="/tmp/${basename(path.module)}.sock"

    ip   = "${local.jupyter_ip}"
    port = "${local.jupyter_port}"

    environment = "${join(",",data.template_file.environment.*.rendered)}"
  }
}

resource "local_file" "supervisord_conf" {
  filename = "${local.dir_prefix}/supervisord.conf"
  content = "${data.template_file.supervisord_conf.rendered}"
}

resource "null_resource" "supervisord" {
  provisioner "local-exec" {
    command = "conda run -n supervisor supervisord -c ${local_file.supervisord_conf.filename}"
  }

  provisioner "local-exec" {
    when = "destroy"
    command = "conda run -n supervisor supervisorctl -c ${local_file.supervisord_conf.filename} shutdown"
  }
}

data "external" "jupyterhub-singleuser" {
  program = ["bash", "${path.module}/files/state.sh"]
  query = {
    supervisord_conf = "${local_file.supervisord_conf.filename}"
    program_name = "${local.program_name}"
  }

  depends_on = [
    "null_resource.supervisord"
  ]
}
locals {
  supervisor_to_jupyter_state = {
    RUNNING = ""
    STARTING = 0
    FAILED = 1
  }
  supervisor_state = "${data.external.jupyterhub-singleuser.result["state"]}"
}
locals {
  jupyter_state = "${local.supervisor_to_jupyter_state["${local.supervisor_state}"]}"
}
