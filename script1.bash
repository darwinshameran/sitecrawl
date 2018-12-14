#!/usr/bin/env bash
#
# Author: Darwin Shameran <dash17@student.bth.se>
#
# Description: DV1466 project A: web spider
#              Implement a web spider that follows the structure of supplied
#              website and generate a GraphViz digraph.
#
# Usage: ./script1.bash domain path
#

set -euo pipefail
declare -a scanned_urls

# {{{ printfstderr
printfstderr() {
  printf "$@ Aborting" >&2
}
# }}}
# {{{ printfworklist
printfworklist() {
  if [[ "${3}" =~ ^http(s?) ]]; then
    cmp="${3}"
  else
    cmp="${4}"
  fi

  if ! [[ "${scanned_urls[@]}" =~ "${cmp}" ]]; then
    scanned_urls+=("${cmp}")
    printf "%s %s %s %s\n" "${1}" "${2}" "${3}" "${4}"
  fi
}
# }}}
# {{{ sanity_check
sanity_check() {
  if (( "${#args[@]}" != 2 )); then
    printfstderr "Error: Invalid amount of arguments passed."
    exit 1
  fi

  declare -r domain_re="^(http(s?):\/\/|www.)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$"

  if ! [[ "${args[0]}" =~ $domain_re ]]; then
    printfstderr "Error: Enter a valid URL."
    exit 1
  fi

  if ! [[ -x "$(command -v curl)" ]]; then
    printfstderr "Error: script requires \`curl'."
    exit 1
  fi
}
# }}}

fetch_page() {
  declare -r url="${domain}/${path}"
  printf "$(curl --silent "${url}")"
}

extract_href() {
  printf "$(fetch_page "${domain}" "${path}" | grep -Po "(?<=href=['\"])[^'\"]+(?=['\"])")"
}

resolve_paths() {
  declare -r target_path=(`printf ${url} | sed 's/\// /g'`)
  declare -r src_url=(`printf "${path}" | sed 's/\// /g'`)
  declare -r src_url_len=$(("${#src_url[@]} - $1"))
  u=$(printf "%s/" "${src_url[@]:0:$src_url_len}" "${target_path[@]:$2}")
  printf "/${u::-1}\n" # rm trailing forward slash (/) char
}

main() {
  declare -r args=("$@")
  sanity_check "${args[@]}"

  declare -r domain="${args[0]}"
  declare -r path="${args[1]}"
  declare -a urls

  for url in $(extract_href "${domain}" "${path}"); do
    if ! [[ "$url" =~ ^mailto ]] && [[ "$url" =~ (.*$|^http(s?)) ]]; then
      urls+=("${url}")
    fi
  done

  for url in ${urls[@]}; do
    # rm query string if in url
    if [[ "${url}" == *?* ]]; then
      url="${url%\?*}"
    fi

    if [[ "${url}" =~ ^http(s?) ]]; then                # if http(s)
      target_path=(`printf ${url} | sed 's/\// /g'`)

      if (( "${#target_path[@]}" == 2 )); then          # if going to root (/)
        url=$(printf "%s//" "${target_path[@]}")
        url=$(printf "${url::-2}\n")                    # rm // at end
        _path="/"
      elif (( "${#target_path[@]}" > 2 )); then         # if has a non-root path
        url=$(printf "%s//" ${target_path[@]:0:2})
        url=$(printf "${url::-2}\n")
        _path=$(printf "/%s" ${target_path[@]:2})
      fi

      printfworklist "${domain}" "${path}" "${url}" "${_path}"
    fi

    if [[ "${url}" =~ ^./ ]]; then                      # ./
      printfworklist "${domain}" "${path}" $"${domain}" $(resolve_paths 1 1)

    elif [[ "${url}" =~ ^\.\. ]]; then    # ../

      if [[ "${url}" =~ ^\.\.\/\.\.\/ ]]; then          # ../../
        printfworklist "${domain}" "${path}" "${domain}" $(resolve_paths 3 2)
        continue  # jump iter
      fi

      printfworklist "${domain}" "${path}" "${domain}" $(resolve_paths 2 1)
    elif [[ "${url}" =~ (^\/).*(html|txt)$ ]];  then    # /path/to/file.html
      printfworklist "${domain}" "${path}" "${domain}" "${url}"

    elif [[ ${url} =~ ^[a-zA-Z0-9]+/?.*.(html|txt)$ ]]; then
      printfworklist "${domain}" "${path}" "${domain}" $(resolve_paths 1 0)
    fi
  done
}

main "$@"

# vim: set ts=2 sw=2 tw=79 ft=sh foldmethod=marker et :
