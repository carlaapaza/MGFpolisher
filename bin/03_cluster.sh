#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd); source "$ROOT/lib/common.sh"
out="$RUN_DIR/03_clusters"; mkdir -p "$out"
reads="$RUN_DIR/02_family_reads/family_reads.fasta"; need_file "$reads"
prefix="$out/clusters"
cd-hit-est -i "$reads" -o "$prefix.representatives.fasta" -c "$CLUSTER_IDENTITY" -n "$CLUSTER_WORD_SIZE" -G 1 -s "$CLUSTER_LENGTH_RATIO" -aS "$CLUSTER_SHORT_COVERAGE" -aL "$CLUSTER_LONG_COVERAGE" -r 1 -g 1 -d 0 -T "$THREADS" -M "$MEMORY_MB" > "$out/cdhit.log"
awk 'BEGIN{OFS="\t";print "cluster_id","read_id","representative"} /^>Cluster/{c="cluster_"$2;next} match($0,/>[^[:space:]]+\.\.\./){id=substr($0,RSTART+1,RLENGTH-4);print c,id,($NF=="*"?"yes":"no")}' "$prefix.representatives.fasta.clstr" > "$out/membership.tsv"
need_file "$out/membership.tsv"
log "read clustering complete: $out/membership.tsv"
