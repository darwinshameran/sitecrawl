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
  worklist=$(cat "${fn}")

  if [[ ! -e "${fn}.dot" ]]; then
    touch "${fn}.dot"
  fi

  printf "digraph result {\n" > "${fn}.dot"

  while read -r line; do
    read -a line_array <<< "${line}"
    src_domain=${line_array[0]}
    src_path=${line_array[1]}
    target_domain=${line_array[2]}
    target_path=${line_array[3]}

    $(printf "\"%s%s\" -> \"%s%s\"\n" "${src_domain}" "${src_path}" \
      "${target_domain}" "${target_path}" >> "${fn}.dot")

  done <<< "${worklist}"
  printf "}" >> "${fn}.dot"

  $(dot -Tsvg "${fn}.dot" -o "${fn}.svg")   # generate .svg file
}

main "$@"
# vim: set ts=2 sw=2 tw=79 ft=sh foldmethod=marker et :
