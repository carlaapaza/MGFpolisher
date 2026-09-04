#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd); source "$ROOT/lib/common.sh"
out="$RUN_DIR/06_polish"; mkdir -p "$out"
find "$RUN_DIR/05_polish_work/clusters" -name final.fasta -type f -print0 | sort -z | xargs -0 cat > "$out/mgfpolisher.polished.fasta"
need_file "$out/mgfpolisher.polished.fasta"
seqkit stats -T "$out/mgfpolisher.polished.fasta" > "$out/polished.stats.tsv"
cp "$RUN_DIR/05_polish_work/iterations.tsv" "$out/iterations.tsv"
{
  echo -e 'metric\tvalue'
  echo -e "candidate_reads\t$(wc -l < "$RUN_DIR/02_family_reads/read_names.txt" | tr -d ' ')"
  echo -e "clusters_retained\t$(grep -c '^>' "$out/mgfpolisher.polished.fasta")"
  echo -e "polish_rounds\t$POLISH_ROUNDS"
} > "$out/run_summary.tsv"
log "MGFpolisher finished: $out/mgfpolisher.polished.fasta"
