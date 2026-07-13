module "app_network" {
  source  = "terraform-google-modules/network/google"
  version = "18.1.2"

  network_name = "${var.network_name}-network"
  project_id   = var.project_id

  subnets = [
    {
      subnet_name   = "${var.network_name}-subnet0"
      subnet_ip     = var.network_ip_range
      subnet_region = var.region
    }
  ]

  ingress_rules = [        # ← must be inside module block
    {                      # ← each rule is an object {}
      name          = "${var.network_name}-web"
      description   = "Inbound web"
      source_ranges = ["0.0.0.0/0"]
      target_tags   = ["${var.network_name}-web"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["80", "443"]
        }
      ]
    }
  ]
}                          # ← closes module block

data "google_compute_image" "ubuntu" {
  most_recent = true
  project     = var.image_project
  family      = var.image_family
}

resource "google_compute_instance" "blog" {
  name         = var.app_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["${var.network_name}-web"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = module.app_network.subnets_names[0]  # ← fixed reference
    access_config {
      # Leave empty for dynamic public IP
    }
  }

  metadata_startup_script = "apt -y update; apt -y install nginx; echo ${var.app_name} > /var/www/html/index.html"  # ← fixed key and path

  allow_stopping_for_update = true
}