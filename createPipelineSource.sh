#!/bin/bash -e
###### createPipelineSource.sh ###
# Usage: ./createPipelineSource.sh <pipelines.yml directory>
# note: make sure you've verified the pipelines.yml file has the correct values that you want
########



function post_by_uri() {
  ###
  # $1 = the uri you want to call
  # $2 = the path to the payload to POST. it is assumed to be a json object
  #####
  ## returns the JSON response from API on stdout.
  ###

  if [[ $# -le 1 ]]; then
      echo "Must provide 2 arguments to post_by_uri" >&2
      return 1
  fi

  local uri="${1#/}"
  shift

  local payloadPath="${1}"
  shift

  echo "Posting by uri:  $uri with payload location: $payloadPath" >&2
  local output_dir=/tmp
  local outputfile="postOut.json"
  if [ -f "$output_dir/$outputfile" ]; then
    rm $output_dir/$outputfile
  fi

  local post_status_code=$(curl -XPOST \
    -w '%{http_code}' \
    -H "Content-type:Application/json" \
    -H "Authorization:Bearer $PIPELINES_API_TOKEN" \
    "$PIPELINES_API_URL/$uri" \
    --data "@$payloadPath" \
     -o $output_dir/$outputfile)

  if [ "$post_status_code" != "200" ]; then
    echo "Unable to post $uri. Status: $post_status_code." >&2
    if [ -f "$output_dir/$outputfile" ]; then
      echo "$(cat $output_dir/$outputfile)"  >&2
    fi
    echo ""
    return 1
  fi
  if [ ! -f "$output_dir/$outputfile" ]; then
    echo "something went wrong. No response object from api" >&2
    echo ""
    return 1
  else
    cat $output_dir/$outputfile
    rm $output_dir/$outputfile
  fi
}

if [ -z "$PIPELINES_API_URL" ] || [ -z "$PIPELINES_API_TOKEN" ]; then
  echo "must have PIPELINES_API_URL and PIPELINES_API_TOKEN defined in the environment." >&2
  exit 1
fi

if [ -z "$1" ]; then
  echo "first argument is required. It should be the directory name where the pipelines.yml can be found" >&2
  exit 1
fi

if [ -z "$(which yq)" ]; then
 echo "yq is required for this operation. see https://github.com/mikefarah/yq" >&2
 exit 1
fi
if [ -z "$1" ]  || [ ! -d "$1" ]; then
  echo "no directory given, or given parameter $1 is not a directory" >&2
  exit 1
fi

yq -o=json $1/pipelines.yml > /tmp/payload.json

result=$(post_by_uri pipelineSources /tmp/payload.json)
jq '.id' <<< $result
