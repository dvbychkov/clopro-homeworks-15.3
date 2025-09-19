terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  service_account_key_file = "./key.json"
  cloud_id  = "b1ggid9nl12161umo6r8"
  folder_id = "b1grekf05a830gqkk35s"
  zone      = "ru-central1-a"
}

resource "yandex_kms_symmetric_key" "bucket_key" {
  name        = "storage-bucket-key"
  description = "KMS key for Object Storage bucket encryption"
  
  default_algorithm = "AES_256"
  rotation_period   = "8760h"
  
  labels = {
    environment = "production"
    purpose     = "storage-encryption"
  }
}

resource "yandex_iam_service_account_static_access_key" "sa_static_key" {
  service_account_id = "aje6rrj0pm3d4ie340fn"
  description        = "static access key for object storage"
}

resource "yandex_storage_bucket" "my_bucket" {
  access_key = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_static_key.secret_key
  bucket     = "student-bucket-encrypted-2025-09-16"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.bucket_key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }

  anonymous_access_flags {
    read = true
    list = false
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  force_destroy = true

  depends_on = [yandex_kms_symmetric_key.bucket_key]
}

resource "yandex_storage_object" "picture" {
  access_key = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_static_key.secret_key
  bucket     = yandex_storage_bucket.my_bucket.id
  key        = "my-picture.jpg"
  source     = "./my-picture.jpg"
  acl        = "public-read"

  depends_on = [yandex_storage_bucket.my_bucket]
}

resource "yandex_vpc_network" "main" {
  name = "main-network"
}

resource "yandex_vpc_subnet" "public" {
  name           = "public"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "private" {
  name           = "private"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.private.id
}

resource "yandex_compute_instance" "nat_instance" {
  name = "nat-instance"
  zone = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd80mrhj8fl2oe87o4e1"
    }
  }

  network_interface {
    subnet_id      = yandex_vpc_subnet.public.id
    nat            = true
    ip_address     = "192.168.10.254"
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_vpc_route_table" "private" {
  name       = "private-route-table"
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "192.168.10.254"
  }
}

resource "yandex_compute_instance" "public_vm" {
  name = "public-vm"
  zone = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8bkgba66kkf9eenpkb"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_compute_instance" "private_vm" {
  name = "private-vm"
  zone = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8bkgba66kkf9eenpkb"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private.id
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_compute_instance_group" "lamp_group" {
  name                = "lamp-group"
  folder_id           = "b1grekf05a830gqkk35s"
  service_account_id  = "aje6rrj0pm3d4ie340fn"
  deletion_protection = false

  instance_template {
    platform_id = "standard-v3"
    
    resources {
      memory = 2
      cores  = 2
    }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = "fd827b91d99psvq5fjit"
        size     = 10
      }
    }

    network_interface {
      network_id = yandex_vpc_network.main.id
      subnet_ids = [yandex_vpc_subnet.public.id]
      nat        = true
    }

    metadata = {
      ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
      user-data = <<-EOF
        #cloud-config
        write_files:
          - content: |
              <!DOCTYPE html>
              <html>
              <head>
                  <title>LAMP Server with Encrypted Storage</title>
                  <style>
                      body { 
                          font-family: Arial, sans-serif; 
                          text-align: center; 
                          padding: 50px; 
                          background-color: #f0f0f0;
                      }
                      .container { 
                          max-width: 800px; 
                          margin: 0 auto; 
                          background: white; 
                          padding: 30px; 
                          border-radius: 10px; 
                          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                      }
                      img { 
                          max-width: 100%; 
                          height: auto; 
                          border-radius: 10px; 
                          margin: 20px 0;
                      }
                      h1 { color: #333; }
                      p { color: #666; font-size: 18px; }
                      .security { 
                          background: #e8f5e8; 
                          padding: 15px; 
                          border-radius: 5px; 
                          margin: 20px 0;
                      }
                  </style>
              </head>
              <body>
                  <div class="container">
                      <h1> LAMP сервер с зашифрованным хранилищем</h1>
                      <div class="security">
                          <strong> Безопасность:</strong> Все файлы в Object Storage зашифрованы с помощью Yandex KMS
                      </div>
                      <p>Это веб-страница из Instance Group</p>
                      <p>Сервер: $(hostname)</p>
                      <h2>Зашифрованная картинка из Object Storage:</h2>
                      <img src="https://storage.yandexcloud.net/student-bucket-encrypted-2025-09-16/my-picture.jpg" alt="Зашифрованная картинка из бакета">
                      <p>Время создания: $(date)</p>
                      <p><small>Картинка хранится в зашифрованном виде с помощью KMS ключа</small></p>
                  </div>
              </body>
              </html>
            path: /var/www/html/index.html
            permissions: '0644'
        runcmd:
          - systemctl restart apache2
      EOF
    }

    scheduling_policy {
      preemptible = true
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = ["ru-central1-a"]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }

  health_check {
    http_options {
      port = 80
      path = "/"
    }
    interval            = 30
    timeout             = 10
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  load_balancer {
    target_group_name        = "lamp-target-group"
    target_group_description = "Target group for LAMP servers"
  }
}

resource "yandex_lb_network_load_balancer" "lamp_lb" {
  name = "lamp-load-balancer"

  listener {
    name = "http-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.lamp_group.load_balancer[0].target_group_id

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}
