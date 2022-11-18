# curation-and-promotion
workflow for curation and promotion of packages

Each directory in this project should represent a local Artifactory repository.
If you'd like to add another set of pipelines for a new repo, you can copy the contents of "rpm-dev-local"
directory and update the anchors at the top of the pipelines.yml to reflect the settings you want to use.

# Getting started
Before you can create a pipeline from this project, you must complete the following setup steps
## create the following pipelines integrations
  - [Artifactory](https://www.jfrog.com/confluence/display/JFROG/Artifactory+Integration)
  - [Distribution](https://www.jfrog.com/confluence/display/JFROG/Distribution+Integration)

Once created, add their names to the pipelines.yml in the `integrationDetails` section

## create the following artifactory repositories
note: adjust the names as needed. This step could also be done in the UI directly
### rpm-dev-local
```sh
echo '{"key":"rpm-dev-local","packageType":"rpm","rclass":"local"}' > template.json
jf rt repo-create template.json
```

### rpm-prod-local
```sh
echo '{"key":"rpm-prod-local","packageType":"rpm","rclass":"local"}' > template.json
jf rt repo-create template.json
```

### rpm-remote
```sh
echo '{"key":"rpm-remote","packageType":"rpm","rclass":"remote","url":"http://mirror.genesisadaptive.com/fedora/linux"}' > template.json
jf rt repo-create template.json
```

### rpm-virtual (optional)
another option is to create a "virtual" repo and put your remotes behind it. This would allow you to cover more remote repositories with the same workflow.

```sh
echo '{"key":"rpm-virtual","packageType":"rpm","rclass":"virtual","repositories":"rpm-remote"}' > template.json
jf rt repo-create template.json
```

*note: if you want your virtual to contain multiple remotes, you can add them to the template as comma separated strings in the "repositories" field*

### yq and jq
in order to create your pipelines from the command line, you'll need to have both `yq` and `jq` installed and in your path. 
see the following URLs for instructions in setup
- https://github.com/mikefarah/yq
- https://github.com/stedolan/jq

### access token 
To make pipelines API calls, you need an access token with appropriate permission.
The fastest way to create a token that represents the logged in user is to take the following steps:
1. click the dropdown in the top right of the Artifactory UI. Select "edit profile"
2. enter your password if prompted so that it will allow you to make changes to this page
3. select the "Generate an Identity Token" and add a description if you want.
4. Save this token somewhere. see the "to use" section on how we will utilize it


## Other requirements
These requirements may be showcased in the pipeline but are ultimately optional
### Slack
As part of the [approval gate feature](https://www.jfrog.com/confluence/display/JFROG/Approval+Gates), you can have your pipeline send a message through Slack

start by creating an "incoming wehbook" integration [in Slack itself](https://api.slack.com/messaging/webhooks)
then, create a slack integration [in the pipelines UI](https://www.jfrog.com/confluence/display/JFROG/Slack+Integration) 

*note: to customize the recipients field when sending a notification, your integration will have to be the old style Slack incoming webhook, which is now deprecated.  If you create the newer version which is based on having a slack app, you wont be able to change the channel or target user at runtime.*


# Description
This repository is designed to create one pipeline source per directory. Each pipeline source will create two pipelines. One pipeline is for curation (caching something from remote to local) and the other pipeline is for promotion and distribution. 

## to use
see above for prerequisites.

before executing any of the helper scripts, make sure to export the following variables
```bash
PIPELINES_API_TOKEN="<token from the setup section>"
PIPELINES_API_URL="https://<your domain>.jfrog.io/pipelines/api/v1"
```

create a new pipeline source by first copying the existing example to a new directory. At the top of the "pipelines.yml" file you'll find many yaml anchors that might need to be updated or changed based on what you want your pipeline to do

Once your yaml is in a good place run "createPipelineSource.sh" with the expected parameters.

If creation is successful, make sure to capture the "id" from the response, which should be printed to the console.

If you want to make additional changes to the existing source, make sure to call "updatePipelineSource.sh", passing in the appropriate ID that was returned from the "create" workflow

After creating/updates the source, make sure to visit the PipelineSources page in the pipelines UI to make sure sync was successful


# FAQs and Common Errors
- If you get a "409 validation error" when running a "createPipelineSource" script, it likely means you need to pick a unique name for the `pipelineSourceName` field
- If your creation succeeds, but your sync fails, see the logs in the UI for more details
- If you lose your pipelineSourceId for a particular source, you can always find it again by calling the `GET /pipelineSources?names=<the name>`
- The pipelines API token is used as a Bearer token in an authorization header.
