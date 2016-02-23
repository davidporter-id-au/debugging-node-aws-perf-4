#!/bin/bash -eu
# Largely based on https://gist.github.com/trevnorris/9616784

if [[ $# -lt 1 ]]; then
	echo "usage $0 <nodeJS script to graph>"
	exit 1
fi

if [[ ! -f ~/sources/FlameGraph/stackcollapse-perf.pl ]]; then
	echo "Needs some setup and scripts. Ensure that you've read/executed https://gist.github.com/trevnorris/9616784"
	exit 1
fi

testScript=$1
node --perf-basic-prof $testScript > /dev/null &
nodePID=$!

function cleanup {
	rm out.perf-folded &> /dev/null || true
	pkill -f node || true
	rm isolate-*  || true
}


echo "Letting it stabilize"
sleep 5

echo "Recording events for 30 seconds"
perf record -i -g -e cycles:u  --pid $nodePID -- sleep 30
perf script \
	| egrep -v "( __libc_start| LazyCompile | v8::internal::| Builtin:| Stub:| LoadIC:|\[unknown\]| LoadPolymorphicIC:)" \
	| sed 's/ LazyCompile:[*~]\?/ /' \
	| ~/sources/FlameGraph/stackcollapse-perf.pl > out.perf-folded

~/sources/FlameGraph/flamegraph.pl out.perf-folded > "$(echo "$testScript" | sed 's/.js$//').svg"

pkill -f node
