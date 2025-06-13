#!/bin/sh
# SPDX-License-Identifier: MIT OR GPL-3.0-or-later

set -eux

cd "$(dirname "$0")"
source_path="$PWD"
dockerfile_path="$PWD/ubuntu-noble.dockerfile"

# 別のフォルダや別のシステムで作業中のdockerイメージと重複しないように
# それらをまとめたハッシュ値をdockerのタグ名としてビルドをする
pwd_and_system="$(pwd):$(uname --machine --operating-system)"
case "$(uname -s)" in
"Linux")
  pwd_and_system_hash=$(echo "$pwd_and_system" | md5sum | cut -d" " -f 1)
  ;;
"Darwin")
  pwd_and_system_hash=$(echo "$pwd_and_system" | md5)
  ;;
*)
  exit 0
  ;;
esac

tag_name="ubuntu-noble-local-tag-${pwd_and_system_hash}"
container_name="ubuntu-noble-local-container-${pwd_and_system_hash}"

mkdir -p "$HOME/visual-workspace/ubuntu-noble"
cd "$HOME/visual-workspace/ubuntu-noble"
port=13389

if ! docker container inspect "$container_name" >/dev/null; then
  docker build \
    --tag "$tag_name" \
    --file "$dockerfile_path" \
    --progress plain \
    "$source_path"
  docker run \
    --gpus=all \
    --detach \
    --publish "127.0.0.1:$port:3389/tcp" \
    --volume "$PWD:/workspace" \
    --name "$container_name" \
    "$tag_name"
else
  docker stop "$container_name"
fi

docker cp "$source_path/ubuntu-noble-entrypoint.sh" "$container_name:/home/xyzzy/entrypoint.sh"
docker start "$container_name" >"$HOME/container-${container_name}.log" &
if ! timeout 5 sh -c "until nc -z 127.0.0.1 $port; do sleep 0.1; done"; then
  echo NG
  exit 1
fi

echo OK "127.0.0.1:$port"
