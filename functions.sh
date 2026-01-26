#!/usr/bin/bash

# THIS FILE IS INTENDED TO BE SOURCED
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then exit 1; fi

# Get project dir
readonly sourced_functions_file_path=$(realpath "$BASH_SOURCE")
project_dir=$(dirname "$sourced_functions_file_path")

# Get last version (without leading v)
github_get_latest_version() {
  local owner="$1"
  local repo="${2:-$1}"
  local i=0
  local version=""
  local releases

  releases=$(curl -sL "https://api.github.com/repos/${owner}/${repo}/releases")

  while true; do
    # Get last "name" | Get last word, if version is prefixed with a release name
    version=$(echo "$releases" | jq -r ".[$i].name" | awk '{print $NF}')

    # Si vide, on a atteint la fin
    if [[ -z "$version" || "$version" == "null" ]]; then
      echo "No version found for ${owner}/${repo}"
      return 1
    fi

    # Check if format matchs vX.X.X ou X.X.X
    if [[ "$version" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      if [[ "${version:0:1}" == "v" ]]; then version="${version:1}"; fi
      echo "$version"
      return 0
    fi

    ((i++))
  done
}

# Import tools
tools_dir="${project_dir}/tools"
tapctl(){            "${tools_dir}/tapctl/tapctl"                       "$@"; }
bridgectl(){         "${tools_dir}/bridgectl/bridgectl"                 "$@"; }
libvirt_allow_nat(){ "${tools_dir}/libvirt_allow_nat/libvirt_allow_nat" "$@"; }
packer(){            "${tools_dir}/packer"                              "$@"; }
tofu(){              "${tools_dir}/tofu"                                "$@"; }


compress_xz(){
    local file_to_compress="$1"
    local options='-v -9' # -T0

    if [ -v 2 ]; then
        local destination_file="$2"
        xz $options -c "$file_to_compress" > "$destination_file"
    else
        xz $options "$file_to_compress"
    fi
}

decompress_xz(){
    local file_to_decompress="$1"

    options='-v'
    if [ -v 2 ]; then
        local destination_file="$2"
        unxz $options "$file_to_decompress" > "$destination_file"
    else
        unxz $options "$file_to_decompress"
    fi    
}

compress_zstd(){
    local file_to_compress="$1"
    local options='-T0 -6' # progress bar is shown by default

    if [ -n "$2" ]; then
        local destination_file="$2"
        zstd $options -c "$file_to_compress" > "$destination_file"
    else
        zstd $options "$file_to_compress"
    fi
}

decompress_zstd(){
    local file_to_decompress="$1"
    local options='-v -d'

    if [ -n "$2" ]; then
        local destination_file="$2"
        zstd $options -c "$file_to_decompress" > "$destination_file"
    else
        zstd $options "$file_to_decompress"
    fi
}

compress_lz4(){
    local file_to_compress="$1"
    local options='-v'

    if [ -n "$2" ]; then
        local destination_file="$2"
        lz4 $options "$file_to_compress" "$destination_file"
    else
        lz4 $options "$file_to_compress"
    fi
}

decompress_lz4(){
    local file_to_decompress="$1"
    local options='-v -d'

    if [ -n "$2" ]; then
        local destination_file="$2"
        lz4 $options "$file_to_decompress" "$destination_file"
    else
        lz4 $options "$file_to_decompress"
    fi
}

compress_lrzip_zpaq(){
    local file_to_compress="$1"
    local options='-v -T -a zpaq -l 9'  # -T : multithread, -v : verbose

    if [ -n "$2" ]; then
        local destination_file="$2"
        # lrzip écrit normalement un fichier .lrz; on force sortie sur stdout puis redirige si destination fournie
        lrzip $options -c "$file_to_compress" > "$destination_file"
    else
        lrzip $options "$file_to_compress"
    fi
}

decompress_lrzip_zpaq(){
    local file_to_decompress="$1"
    local options='-v -T -d'  # -d : decompression

    if [ -n "$2" ]; then
        local destination_file="$2"
        # lrzip -d -c writes decompressed data on stdout
        lrzip $options -c "$file_to_decompress" > "$destination_file"
    else
        lrzip $options "$file_to_decompress"
    fi
}

export cp=xz # compressed extension
compress(){   compress_xz   "$@"; }
decompress(){ decompress_xz "$@"; }

# Global vars
export xz_level=0
readonly xz_level

readonly cp
export node_disk_size='12G'
readonly node_disk_size

export nc_ip=$(ip route get 1.1.1.1 | awk '{print $7}')
export nc_port=64271

# Functions
netcat_script_stdout(){

    # Create netcat command (listen)
    netcat_cmd="nc -l -p $nc_port"
    # Clean eventual old instance of nc (previous crash)
    pids=$(ps aux | grep "$netcat_cmd" | grep -v grep | awk '{print $2}' || true)
    kill -9 $pids 2>/dev/null || true
    $netcat_cmd &
}

wait_netcat(){
    echo -n 'Waiting log deconnexion... ' && wait && echo 'Done.'
}

wait_for_ssh(){
    hostname="$1"
    ip="$2"
    echo -n "Wait for $hostname ssh started... "
    until nc -z "$ip" 22 &>/dev/null; do sleep 5; done
    echo "[OK]"
    ssh-keygen  -R "$ip"                &>/dev/null
    ssh-keygen  -R "$hostname"          &>/dev/null
    ssh-keygen  -R "${hostname}.lab.ln" &>/dev/null
    # shellcheck disable=SC2129
    ssh-keyscan -H "$ip"                >> ~/.ssh/known_hosts
    ssh-keyscan -H "$hostname"          >> ~/.ssh/known_hosts
    ssh-keyscan -H "${hostname}.lab.ln" >> ~/.ssh/known_hosts
}
