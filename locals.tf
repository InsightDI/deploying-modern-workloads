locals {
  tags = {
    owner   = "YOURNAMEHERE"
    project = "Deploying Modern Workloads"
  }

  networks = {
    hub = {
      address_space = "10.0.0.0/16"
    }
    spoke = {
      address_space = "10.1.0.0/16"
    }
  }
}
