#!/bin/sh

# env.sh

# Change the contents of this output to get the environment variables
# of interest. The output must be valid JSON, with strings for both
# keys and values.
cat <<EOF
{
  "id": "$AWS_ACCESS_KEY_ID",
  "secret": "$AWS_SECRET_ACCESS_KEY",
  "token": "$AWS_SESSION_TOKEN"
}
EOF