variable "TAG" {
  default = "dev"
}

variable "PREFIX" {
  default = "registry-vpc.cn-beijing.aliyuncs.com/huweiwen-test/3fs"
}

group "default" {
  targets = [
    "meta", "storage", "mgmtd", "admin-cli", "fuse", "init",
    "meta-debug", "storage-debug", "mgmtd-debug", "admin-cli-debug", "fuse-debug"
  ]
}

group "prod" {
  targets = ["meta", "storage", "mgmtd", "admin-cli", "fuse", "init"]
}

target "docker-metadata-action" {}

target "_common" {
  inherits = ["docker-metadata-action"]
  context = "./deploy/container"
  contexts = {
    bin = "./super/build/3fs-prefix/src/3fs-build/bin"
  }
}

target "3fs" {
  inherits = ["_common"]
  name = "${component}${variant}"
  matrix = {
    component = ["meta", "storage", "mgmtd", "admin-cli", "fuse"]
    variant = ["", "-debug"]
  }
  target = "${component}${variant}"
  tags = ["${PREFIX}-${component}:${TAG}${variant}"]
}

target "init" {
  inherits = ["_common"]
  target = "init"
  tags = ["${PREFIX}-init:${TAG}"]
  contexts = {
    data_placement = "./deploy/data_placement"
  }
}
