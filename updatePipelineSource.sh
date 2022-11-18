#!/bin/bash
###### updatePipelineSource.sh ###
# Usage: ./updatePipelineSource.sh <pipelines.yml directory> <pipeline source id>
# note: make sure you've verified the pipelines.yml file has the correct values that you want
# the pipeline source id argument comes from first executing "createPipelineSource.sh"
########


function put_by_uri() {
  # this function assumes it is in the context of an execute_command
  ###
  # $1 = the uri you want to call
  # $2 = the path to the payload to PUT. it is assumed to be a json object
  #####
  ## returns the JSON response from API on stdout.
  ###

  if [[ $# -le 1 ]]; then
      echo "Must provide 2 arguments to put_by_uri" >&2
      return 1
  fi

  local uri="${1#/}"
  shift

  local payloadPath="${1}"
  shift

  local output_dir=/tmp
  local outputfile="putOut.json"
  if [ -f "$output_dir/$outputfile" ]; then
    rm $output_dir/$outputfile
  fi

  local put_status_code=0

    put_status_code=$(curl -s -XPUT \
      -w '%{http_code}' \
      -H "Content-type:Application/json" \
      -H "Authorization:Bearer $PIPELINES_API_TOKEN" \
      "$PIPELINES_API_URL/$uri" \
      --data "@$payloadPath" \
       -o $output_dir/$outputfile)

    if [ "$put_status_code" != "200" ]; then
      echo "Unable to put $uri. Status: $put_status_code." >&2
      if [ -f "$output_dir/$outputfile" ]; then
        echo "$(cat $output_dir/$outputfile)" >&2
      fi
      echo "" >&2
      return 1
    elif [ ! -f "$output_dir/$outputfile" ]; then
      echo "something went wrong. No response object from api" >&2
      echo ""
      return 1
    else
      cat $output_dir/$outputfile
      rm $output_dir/$outputfile
    fi
}



if [ -z "$PIPELINES_API_URL" ] || [ -z "$PIPELINES_API_TOKEN" ]; then
  echo "must have PIPELINES_API_URL and PIPELINES_API_TOKEN defined in the environment."
  exit 1
fi

if [[ $# -le 1 ]]; then
  echo "this script requires 2 inputs: 1. the path to the pipelines.yml, 2. the pipelineSourceId to be updated"
  exit 1
fi

if [ -z "$(which yq)" ]; then
 echo "yq is required for this operation. see https://github.com/mikefarah/yq" >&2
 exit 1
fi
if [ -z "$1" ]  || [ ! -d "$1" ]; then
  echo "no directory given, or given parameter $1 is not a directory"
  exit 1
fi

yq -o=json $1/pipelines.yml > /tmp/payload.json

result=$(put_by_uri pipelineSources/$2 /tmp/payload.json)
jq '.id' <<< $result
