group "default" {
  targets = [
    "components"
  ]
}

group "components" {
  targets = [
    "sensing-perception-cuda",
  ]
}

target "sensing-perception-cuda" {
  tags = ["pilot-auto:sensing-perception-cuda"]
  target = "sensing-perception"
  dockerfile = "Dockerfile.main"
}
