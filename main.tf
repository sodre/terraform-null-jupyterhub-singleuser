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

locals {
  dir_prefix = "${path.module}/.supervisor"
  program_name = "jupyterhub-singleuser"
}

locals {
  jupyter_ip   = "127.0.0.1"
  jupyter_port = 8889
}

data "template_file" "supervisord_conf" {
  template = "${file("${path.module}/template/supervisord.conf")}"
  vars = {
    dir_prefix="${local.dir_prefix}"

    ip   = "${local.jupyter_ip}"
    port = "${local.jupyter_port}"
  }
}

resource "local_file" "supervisord_conf" {
  filename = "${local.dir_prefix}/supervisord.conf"
  content = "${data.template_file.supervisord_conf.rendered}"
}

resource "null_resource" "supervisord" {
  provisioner "local-exec" {
    environment = {
      JUPYTERHUB_API_TOKEN = "${var.api_token}"
      JUPYTERHUB_API_URL   = "${var.api_url}",
      JUPYTERHUB_BASE_URL  = "${var.base_url}",

      JUPYTERHUB_HOST      = "${var.host}",
      JUPYTERHUB_CLIENT_ID = "${var.client_id}",
      JUPYTERHUB_OAUTH_CALLBACK_URL = "${var.oauth_callback_url}",

      JUPYTERHUB_SERVICE_PREFIX = "${var.service_prefix}",
      JUPYTERHUB_USER           = "${var.user}",
    }

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
    STARTING = ""
    FAILED = 1
  }
  supervisor_state = "${data.external.jupyterhub-singleuser.result["state"]}"
}
locals {
  jupyter_state = "${local.supervisor_to_jupyter_state["${local.supervisor_state}"]}"
}