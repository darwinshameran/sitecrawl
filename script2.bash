#!/usr/bin/env bash
#
# Author: Darwin Shameran <dash17@student.bth.se>
#
# Description: DV1466 project A: web spider
#              Implement a web spider that follows the structure of supplied
#              website and generate a GraphViz digraph.
#

set -euo pipefail

main() {
  declare -r fn="result"
  declare -r domain=${1:-"erikbergenholtz.se"}
  declare -r path=${2:-"/unix/ass4/spider/start.html"}
  declare -a scanned_urls


  if [[ ! -e "${fn}" ]]; then
    touch "${fn}"
  fi

  worklist=$(./script1.bash "${domain}" "${path}" > "${fn}" && cat "${fn}")

  while read -r line; do
    read -a line_array <<< "${line}"
    src_domain=${line_array[0]}
    src_path=${line_array[1]}
    target_domain=${line_array[2]}
    target_path=${line_array[3]}

    if [[ "${target_domain}" == "${domain}" ]]              \
      && [[ ! "${scanned_urls[@]}" =~ "${target_path}" ]]   \
      && [[ ! "${target_path}" =~ ".txt" ]]; then
      $(./script1.bash "${src_domain}" "${target_path}" >> result)
      scanned_urls+=("${target_path}")
    fi
  done <<< "${worklist}"
}

main "$@"

# vim: set ts=2 sw=2 tw=79 ft=sh foldmethod=marker et :
