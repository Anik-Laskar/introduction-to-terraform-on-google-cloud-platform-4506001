
module "app_netwrok"{
  source  = "terraform-google-modules/network/google"
  version = "18.1.2"

  network_name = "${var.network_name}-network"
  project_id = var.project_id

  subnets = [
        {
            subnet_name           = "${var.network_name}-subnet0"
            subnet_ip             = var.network_ip_range
            subnet_region         = var.region
        }
]

ingress_rules = 

[
    name                    = "${var.network_name}-web"
    description             = "INbound web"
   
    source_ranges           = ["0.0.0.0/0"]
    
    target_tags             = ["${var.network_name}-web"]


    allow =[ 
      {
      protocol = "tcp"
      ports    = ["80", "443"]
       }
    ]
]
  

}
resource "google_compute_network" "app" {
  name                    = var.network_name
  auto_create_subnetworks = false
}
resource "google_compute_subnetwork" "app" {
  name          = var.network_name
  ip_cidr_range = var.network_ip_range
  region        = var.region
  network       = google_compute_network.app.id

}


data "google_compute_image" "ubuntu" {
  most_recent = true
  project     = var.image_project
  family      = var.image_family
}

resource "google_compute_instance" "blog" {
  name         = var.app_name
  machine_type = var.machine_type

  
  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }
  network_interface {
   subnetwork = module.app_network.subnet_name[0]
   access_config {
      # Leave empty for dynamic public IP
    }
  }  

  allow_stopping_for_update = true

}
