group "default" {
  targets = [
    "base-image-runtime",
    "base-image-build",
  ]
}

group "cuda" {
  targets = [
    "base-image-runtime-cuda",
    "base-image-build-cuda",
  ]
}

target "base-image-runtime" {
  tags = ["pilot-auto-base-image:runtime"]
  target = "base-image-runtime"
  dockerfile = "Dockerfile.base"
}

target "base-image-build" {
  tags = ["pilot-auto-base-image:build"]
  target = "base-image-build"
  dockerfile = "Dockerfile.base"
}

target "base-image-runtime-cuda" {
  tags = ["pilot-auto-base-image:runtime-cuda"]
  target = "base-image-runtime-cuda"
  dockerfile = "Dockerfile.base"
}

target "base-image-build-cuda" {
  tags = ["pilot-auto-base-image:build-cuda"]
  target = "base-image-build-cuda"
  dockerfile = "Dockerfile.base"
}
