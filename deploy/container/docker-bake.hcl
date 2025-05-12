variable "TAG" {
  default = "dev"
}

variable "PREFIX" {
  default = "registry-vpc.cn-beijing.aliyuncs.com/huweiwen-test/3fs"
}

group "default" {
  targets = [
    "3fs-meta", "3fs-storage", "3fs-mgmtd", "3fs-admin-cli", "3fs-fuse", "3fs-init",
    "3fs-meta-debug", "3fs-storage-debug", "3fs-mgmtd-debug", "3fs-admin-cli-debug", "3fs-fuse-debug"
  ]
}

group "prod" {
  targets = ["3fs-meta", "3fs-storage", "3fs-mgmtd", "3fs-admin-cli", "3fs-fuse", "3fs-init"]
}

target "docker-metadata-action" {}

target "_common" {
  inherits = ["docker-metadata-action"]
  context = "./deploy/container"
  contexts = {
    bin = "./super/build/3fs-prefix/src/3fs-build/bin"
    data_placement = "./deploy/data_placement"
  }
}

target "3fs" {
  inherits = ["_common"]
  name = "3fs-${component}${variant}"
  matrix = {
    component = ["meta", "storage", "mgmtd", "admin-cli", "fuse"]
    variant = ["", "-debug"]
  }
  target = "${component}${variant}"
  tags = ["${PREFIX}-${component}:${TAG}${variant}"]
}

target "3fs-init" {
  inherits = ["_common"]
  target = "init"
  tags = ["${PREFIX}-init:${TAG}"]
}

target "reuseable_cache" {
  inherits = ["_common"]
  target = "reuseable_cache"
}
