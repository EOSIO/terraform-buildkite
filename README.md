# Terraform provider for [buildkite](https://www.buildkite.com)

Manage buildkite pipelines with Terraform!

## Usage

```terraform
resource "buildkite_pipeline" "eosio" {
  name                 = "EOSIO"
  repository           = "git@github.com:EOSIO/eos.git"
  slug                 = "eosio"
  branch_configuration = "master release/* develop v*.*.*"
  default_branch       = "develop"
  description          = ":muscle: The Most Powerful Infrastructure for Decentralized Applications"
  
  github_settings {
    trigger_mode = "code"
  }

  env                  =  {
    "BUILDKITE_CLEAN_CHECKOUT" = "true"
    "SKIP_CONTRACT_BUILDER" = "true"
    "PREP_COMMANDS" = <<EOF
if [[ "$(uname)" == "Darwin" ]]; then export BUILDKITE_FULL_BUILD_PATH=$(echo /Users/anka/build/$BUILDKITE_PROJECT_SLUG); else export BUILDKITE_FULL_BUILD_PATH=$(echo $BUILDKITE_BUILD_PATH/$BUILDKITE_AGENT_NAME/$BUILDKITE_PROJECT_SLUG); fi && mkdir -p $BUILDKITE_FULL_BUILD_PATH && cd $BUILDKITE_FULL_BUILD_PATH;
git clone -v -- $([[ "$BUILDKITE_REPO" =~ "@" ]] && echo $BUILDKITE_REPO | awk -F: '{print "https://github.com/"\$\$2}' || echo $BUILDKITE_REPO) .;
[[ $BUILDKITE_BRANCH =~ ^pull/[0-9]+/head: ]] && git fetch -v --prune origin refs/pull/$(echo $BUILDKITE_BRANCH | cut -d/ -f2)/head || git checkout $BUILDKITE_BRANCH;
git checkout $BUILDKITE_COMMIT;
git clean -ffxdq;
./.cicd/prep-submodules.sh;
    EOF
  }

  step = [
    {
      type    = "script"
      name    = ":pipeline: Pipeline Upload"
      command = <<CMD
        bash -c "$$PREP_COMMANDS ./.cicd/generate-pipeline.sh > pipeline.yml && buildkite-agent artifact upload pipeline.yml && buildkite-agent pipeline upload pipeline.yml"
      CMD
      agent_query_rules = [
        "queue=automation-basic-builder-fleet"
      ]
    },
  ]
}
```

- IF you don't set github_settings or bitbucket_settings, buildkite will set true for some of the options. See the tests for an example.
- All github_settings and bitbucket properties not defined will default to false or an empty string.

## Building the plugin

```
./build.sh
```
- Take the ./dist/terraform-provider-buildkite-*.zip file and make sure it's on the docker tag you're using:
  ```
  RUN mkdir -p "/root/.terraform.d/plugins/"
  COPY ./packages/terraform-provider-buildkite-v0.0.6-linux-amd64.zip /root/terraform-provider-buildkite-v0.0.6-linux-amd64.zip
  RUN unzip /root/terraform-provider-buildkite-v0.0.6-linux-amd64.zip -d "/root/.terraform.d/plugins/"
  RUN rm -rf /root/terraform-provider-buildkite-v0.0.6-linux-amd64.zip
  ```

## Development & Testing

```
./test.sh
```
- You can set `export TF_LOG=DEBUG` before executing the test script to get a better idea of what is failing.