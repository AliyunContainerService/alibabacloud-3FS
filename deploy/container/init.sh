#!/bin/bash

set -e

cd
python3 data_placement/src/model/data_placement.py \
    -ql -relax -type CR --num_nodes "$STORAGE_NODES" --replication_factor "$REPLICATION_FACTOR" --min_targets_per_disk "$MIN_TARGETS_PER_DISK"
python3 data_placement/src/setup/gen_chain_table.py \
    --chain_table_type CR --node_id_begin 10000 --node_id_end $(( 10000 + STORAGE_NODES - 1 )) \
    --num_disks_per_node "$DISKS_PER_NODE" --num_targets_per_disk "$MIN_TARGETS_PER_DISK" \
    --target_id_prefix 1 --chain_id_prefix 9 \
    --incidence_matrix_path output/DataPlacementModel-*/incidence_matrix.pickle

while ! [ -s /etc/foundationdb/fdb.cluster ]; do
    echo "Waiting for fdb cluster to be ready..."
    sleep 5
done

admin_cli "$@" "init-cluster 1 1048576 $STRIPE_SIZE"

echo "Waiting for $STORAGE_NODES storage nodes to be ready..."
while :; do
    N_STORAGE=$(admin_cli "$@" list-nodes | grep -c STORAGE || true)
    if [ "$N_STORAGE" -eq "$STORAGE_NODES" ]; then
        break
    else
        echo "Waiting for $STORAGE_NODES storage nodes to be ready, currently $N_STORAGE"
        sleep 5
    fi
done

admin_cli "$@" < output/create_target_cmd.txt

admin_cli "$@" <<EOF
upload-chains output/generated_chains.csv
upload-chain-table --desc stage 1 output/generated_chain_table.csv
EOF

# Token    xxxx(Expired at N/A)
TOKEN=$(admin_cli "$@" 'user-add --root --admin 0 root' | grep  -oP 'Token\s+\K[^\s]+(?=\(Expired at N/A\))')

echo "Uploading root token to Kubernetes secret..."

SA=/var/run/secrets/kubernetes.io/serviceaccount
NAMESPACE=$(cat $SA/namespace)
curl -X PUT --fail-with-body --silent --show-error -H "Content-Type: application/json" \
    --cacert $SA/ca.crt \
    --header "Authorization: Bearer $(cat $SA/token)" \
    -d '{
        "apiVersion": "v1",
        "kind": "Secret",
        "metadata": {"name": "'"$ROOT_TOKEN_NAME"'"},
        "stringData": {"token": "'"$TOKEN"'"}
    }' \
    "https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/secrets/$ROOT_TOKEN_NAME"
