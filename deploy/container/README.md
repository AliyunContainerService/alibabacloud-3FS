# Setup 3FS on Kubernetes

## Prepare a Cluster

This guide is written for [Alibaba Cloud Container Service for Kubernetes (ACK)][ACK].
It should work with minor tweaks on other standard Kubernetes environments.

[eRDMA][eRDMA] is available on multiple regions of Alibaba Cloud without extra fee.
And it is fully compatible with 3FS.

Here is an example of creating a compatible ACK cluster with `aliyun` CLI:
```bash
aliyun cs POST /clusters --header "Content-Type=application/json" --body '{
    "name": "3FS-example",
    "cluster_type": "ManagedKubernetes",
    "kubernetes_version": "1.32.1-aliyun.1",
    "region_id": "cn-beijing",
    "snat_entry": true,
    "proxy_mode": "ipvs",
    "addons": [
        {
            "name": "terway-controlplane"
        },
        {
            "name": "terway-eniip"
        },
        {
            "name": "csi-plugin"
        },
        {
            "name": "managed-csiprovisioner"
        },
        {
            "name": "nginx-ingress-controller",
            "disabled": true
        },
        {
            "name": "ack-erdma-controller",
            "config": "{\"agent\":{\"preferDriver\":\"compat\",\"allocateAllDevices\":true}}"
        }
    ],
    "cluster_spec": "ack.pro.small",
    "charge_type": "PostPaid",
    "zone_ids": [
        "cn-beijing-i"
    ],
    "service_cidr": "192.168.0.0/16",
    "ip_stack": "ipv4",
    "is_enterprise_security_group": true,
    "nodepools": [
        {
            "nodepool_info": {
                "name": "default-nodepool"
            },
            "scaling_group": {
                "system_disk_category": "cloud_essd",
                "system_disk_size": 60,
                "system_disk_performance_level": "PL0",
                "system_disk_encrypted": false,
                "instance_types": [
                    "ecs.g8ise.xlarge",
                    "ecs.g8i.xlarge"
                ],
                "instance_charge_type": "PostPaid",
                "platform": "AliyunLinux",
                "image_type": "AliyunLinux3",
                "desired_size": 4
            },
            "kubernetes_config": {
                "pre_user_data": "bWtkaXIgLXAgL2V0Yy9jb250YWluZXJkL2NlcnQuZC9kb2NrZXIuaW8vCmNhdCA+IC9ldGMvY29udGFpbmVyZC9jZXJ0LmQvZG9ja2VyLmlvL2hvc3RzLnRvbWwgPDxFT0YKc2VydmVyID0gImh0dHBzOi8vcmVnaXN0cnktMS5kb2NrZXIuaW8iCltob3N0LiJodHRwczovL21pcnJvcnMtc3NsLmFsaXl1bmNzLmNvbS8iXQogIGNhcGFiaWxpdGllcyA9IFsicHVsbCIsICJyZXNvbHZlIl0KICBza2lwX3ZlcmlmeSA9IHRydWUKRU9G",
                "runtime": "containerd",
                "runtime_version": "1.6.37"
            }
        }
    ]
}'
```

- Please choose instance types that support eRDMA (e.g. ecs.g8ise family).
- It is recommended to choose instance types and zones that supports elastic ephemeral disks (EED), such as cn-beijing-i, for higher performance.
  Alternatively, you can choose local SSD instance types (ecs.i4 family) for optimal performance, but manual initialization of the local disk is required.
- Please create at least 3 nodes, as the fdb operator requires 3 coordinators on 3 different nodes by default.
- ack-erdma-controller component is required to enable eRDMA.
- The open-source FoundationDB component needs to be pulled from DockerHub. To accelerate that, it is recommended to configure Alibaba's mirror.

## Deploy FDB Operator

3FS uses FoundationDB. If you also want to deploy the FDB cluster in Kubernetes, you may want to use the [operator][fdb-op].
For your convenience, we provide example deployment manifests here:
```bash
kubectl create ns fdb
kubectl apply -n fdb -f ./fdb-operator
```

## Deploy 3FS Cluster

Use helm to deploy the 3FS cluster along with the FDB cluster:
```bash
helm install 3fs ./chart -n 3fs --create-namespace --timeout 10m
```
It will take several minutes. Before the initialization completes, some containers may crash several times, this is normal.

When deploying out of cn-beijing region, please remove the "-vpc" from domain name of image.

Once deployed, you can access the 3FS cluster via:
* admin-cli: `kubectl attach -n 3fs admin-cli-3fs -it` (Press Ctrl+D to see the prompt)
  ```
  / > list-nodes
  Id     Type     Status               Hostname           Pid  Tags  LastHeartbeatTime    ConfigVersion  ReleaseVersion
  2      MGMTD    PRIMARY_MGMTD        mgmtd-3fs-2        1    []    N/A                  0(UPTODATE)    250228-dev-1-999999-f5fd8c05
  1      MGMTD    HEARTBEAT_CONNECTED  mgmtd-3fs-1        1    []    2025-03-21 19:52:58  0(UPTODATE)    250228-dev-1-999999-f5fd8c05
  100    META     HEARTBEAT_CONNECTED  meta-3fs-100       1    []    2025-03-21 19:52:59  0(UPTODATE)    250228-dev-1-999999-f5fd8c05
  101    META     HEARTBEAT_CONNECTED  meta-3fs-101       1    []    2025-03-21 19:52:56  0(UPTODATE)    250228-dev-1-999999-f5fd8c05
  10000  STORAGE  HEARTBEAT_CONNECTED  storage-3fs-10000  1    []    2025-03-21 19:53:04  0(UPTODATE)    250228-dev-1-999999-f5fd8c05
  10001  STORAGE  HEARTBEAT_CONNECTED  storage-3fs-10001  1    []    2025-03-21 19:53:04  0(UPTODATE)    250228-dev-1-999999-f5fd8c05
  10002  STORAGE  HEARTBEAT_CONNECTED  storage-3fs-10002  1    []    2025-03-21 19:53:04  0(UPTODATE)    250228-dev-1-999999-f5fd8c05
  ```
  Press Ctrl+D again to exit.
* fuse: `kubectl exec -n 3fs fuse-3fs -it -- ls /mnt/3fs` and you will see `3fs-virt`.
  It will also mount /mnt/3fs to the host, where you can run fio or other tools to further test it.

These two pods are just examples, you may delete them without affecting the 3FS cluster.

This deployment use 64GiB elastic ephemeral disks (EED), which are the bottleneck of the throughput.
To test the performance, Please consider:
* The throughput of the disks
* The cloud disk throughput of the instance
* The network throughput of the instance


[ACK]: https://www.alibabacloud.com/product/kubernetes
[eRDMA]: https://www.alibabacloud.com/help/zh/ecs/user-guide/elastic-rdma-erdma/
[fdb-op]: https://github.com/FoundationDB/fdb-kubernetes-operator