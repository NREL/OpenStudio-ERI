#!/bin/bash

export CI=true
export CIRCLECI=true
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

cd /OpenStudio-Beopt
bundle install

rake update_resources

# Run a specific set of tests on each node.
# Test groups are defined in the Rakefile.
# Each group must have a total runtime less
# than 2 hrs.
case $CIRCLE_NODE_INDEX in
  0)
    rake test:measures_group_0
    ;;
  1)
    rake test:measures_group_1
    ;;
  2)
    rake test:measures_group_2
    ;;
  3)
    rake test:measures_group_3
    ;;
  *)
esac