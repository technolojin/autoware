group "default" {
  targets = [
    "components",
    "universe-all"
  ]
}

group "components" {
  targets = [
    "localization-mapping",
    "planning-control",
    "vehicle-system",
    "sensing-perception",
    "api",
    "visualization",
    "simulation"
  ]
}

target "localization-mapping" {
  tags = ["pilot-auto:localization-mapping"]
  target = "localization-mapping"
  dockerfile = "Dockerfile.main"
}

target "planning-control" {
  tags = ["pilot-auto:planning-control"]
  target = "planning-control"
  dockerfile = "Dockerfile.main"
}

target "vehicle-system" {
  tags = ["pilot-auto:vehicle-system"]
  target = "vehicle-system"
  dockerfile = "Dockerfile.main"
}

target "sensing-perception" {
  tags = ["pilot-auto:sensing-perception"]
  target = "sensing-perception"
  dockerfile = "Dockerfile.main"
}

target "api" {
  tags = ["pilot-auto:api"]
  target = "api"
  dockerfile = "Dockerfile.main"
}

target "visualization" {
  tags = ["pilot-auto:visualization"]
  target = "visualization"
  dockerfile = "Dockerfile.main"
}

target "simulation" {
  tags = ["pilot-auto:simulation"]
  target = "simulation"
  dockerfile = "Dockerfile.main"
}

target "evaluation" {
  tags = ["pilot-auto:evaluation"]
  target = "evaluation"
  dockerfile = "Dockerfile.main"
}

target "rosbag" {
  tags = ["pilot-auto:rosbag"]
  target = "rosbag"
  dockerfile = "Dockerfile.main"
}

target "universe-all" {
  tags = ["pilot-auto:universe-all"]
  target = "universe-all"
  dockerfile = "Dockerfile.main"
}
