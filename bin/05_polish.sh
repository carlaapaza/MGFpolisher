#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd); source "$ROOT/lib/common.sh"
out="$RUN_DIR/05_polish_work"; mkdir -p "$out/clusters"
reads="$RUN_DIR/02_family_reads/family_reads.fastq.gz"; members="$RUN_DIR/03_clusters/membership.tsv"; seeds="$RUN_DIR/04_seeds/seeds.fasta"; seedtab="$RUN_DIR/04_seeds/seeds.tsv"
for f in "$reads" "$members" "$seeds" "$seedtab"; do need_file "$f"; done
printf 'cluster_id\tround\tprevious_length\tnew_length\tchanged_bases\n' > "$out/iterations.tsv"
while IFS=$'\t' read -r cluster seed _; do
  cdir="$out/clusters/$cluster"; mkdir -p "$cdir"
  awk -F '\t' -v c="$cluster" 'NR>1&&$1==c{print $2}' "$members" > "$cdir/names.txt"
  seqkit grep -f "$cdir/names.txt" "$reads" -o "$cdir/reads.fastq.gz"
  seqkit grep -p "$cluster" "$seeds" -o "$cdir/round0.fasta"
  prev="$cdir/round0.fasta"
  for ((round=1; round<=POLISH_ROUNDS; round++)); do
    paf="$cdir/round${round}.paf"; next="$cdir/round${round}.fasta"
    minimap2 -t "$THREADS" -x "$POLISH_PRESET" "$prev" "$cdir/reads.fastq.gz" > "$paf" 2> "$cdir/round${round}.minimap2.log"
    racon -t "$THREADS" "$cdir/reads.fastq.gz" "$paf" "$prev" > "$next" 2> "$cdir/round${round}.racon.log"
    oldlen=$(seqkit stats -T "$prev" | awk 'NR==2{print $5}'); newlen=$(seqkit stats -T "$next" | awk 'NR==2{print $5}')
    changed=$(minimap2 -c "$prev" "$next" 2>/dev/null | awk 'NR==1{print ($11-$10)+($2-$10)+($7-$10);exit}'); changed=${changed:-NA}
    printf '%s\t%s\t%s\t%s\t%s\n' "$cluster" "$round" "$oldlen" "$newlen" "$changed" >> "$out/iterations.tsv"
    prev="$next"
  done
  cp "$prev" "$cdir/final.fasta"
done < "$seedtab"
log "cluster-local polishing complete"
