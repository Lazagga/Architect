#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

for n in 1 2 3 4 5 6 7 8; do
    t="testcase${n}"
    cp ./*.v "${t}/"
    (
        cd "${t}"
        iverilog -o sim ./*.v
        out="$(timeout 20s vvp sim)"
        if grep -q "Simulation success!!!" <<<"${out}"; then
            echo "${t}: Simulation success!!!"
        else
            echo "${t}: FAIL"
            printf '%s\n' "${out}"
            exit 1
        fi
    )
done
