while true; do 
  local_height=$(xplad status | jq -r '.SyncInfo.latest_block_height'); 
  network_height=$(curl -s https://og-testnet-rpc.itrocket.net/status | jq -r 'latest_block_height')
  blocks_left=$((network_height - local_height)); 
  echo -e "\033[1;38mYour node height:\033[0m \033[1;34m$local_height\033[0m | \033[1;35mNetwork height:\033[0m \033[1;36m$network_height\033[0m | \033[1;29mBlocks left:\033[0m \033[1;31m$blocks_left\033[0m"; 
  sleep 5; 
done
