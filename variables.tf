variable "enabled" {
  default = true
  description = "Whether to start/stop the server"
}

variable "environment" {
  description = "The environment variables from JupyterHub"
  type = "map"
  default = {
    hello = "world"
  }
}

variable "api_token" {
  description = "The JupyterHub API Token"
}

variable "api_url" {
  description = ""
  default = "http://127.0.0.1:8081/hub/api"
}

variable "base_url" {
  default = "/"
}

variable "client_id" {
  default = "jupyterhub-user-sodre"
}

variable "host" {
  default = ""
}

variable "oauth_callback_url" {
  default = "/user/sodre/oauth_callback"
}

variable "service_prefix" {
  default = "/user/sodre/"
}

variable "user" {
  default = "sodre"
}
