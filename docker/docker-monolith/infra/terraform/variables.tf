variable project {
  description = "Project ID"
}

variable region {
  description = "Region"

  # Значение по умолчанию
  default = "europe-west1"
}

variable zone {
  description = "Zone"

  # Значение по умолчанию
  default = "europe-west1-b"
}

variable public_key_path {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}

variable private_key_path {
  # Описание переменной
  description = "Path to the private key used for ssh access"
}

variable disk_image {
  description = "Disk image"
}

variable "node_count" {
  default = "1"
}

variable input_port {
  description = "Порт для входищих соединений"
}

variable source_tag_name {
  description = "Тэг сети для входящих соединений"

  default     = "reddit-app"
}
