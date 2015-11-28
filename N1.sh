#!/bin/bash
N1_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd );
node_modules/.bin/electron --executed-from="$(pwd)" --pid=$$ "$@" $N1_PATH
exit $?
