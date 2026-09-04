#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd); source "$ROOT/lib/common.sh"
out="$RUN_DIR/01_map"; mkdir -p "$out"
need_file "$REFERENCE_FASTA"; need_file "$READS"
idx="$out/reference.mmi"; bam="$out/all.sorted.bam"
[[ -s "$idx" ]] || minimap2 -t "$THREADS" -d "$idx" "$REFERENCE_FASTA"
case "$GENOME_MAP_MODE" in
  direct-rna-splice) map_args=(-ax splice -uf -k14) ;;
  splice)            map_args=(-ax splice) ;;
  no-splice)         map_args=(-ax "$MAP_PRESET") ;;
  *) die "unsupported GENOME_MAP_MODE: $GENOME_MAP_MODE" ;;
esac
log "genome mapping mode: $GENOME_MAP_MODE"
fastq_stream | minimap2 -t "$THREADS" "${map_args[@]}" --secondary=yes -N 50 --MD "$idx" - 2> "$out/minimap2.log" | samtools sort -@ "$THREADS" -o "$bam" -
samtools index -@ "$THREADS" "$bam"
samtools flagstat -@ "$THREADS" "$bam" > "$out/flagstat.txt"
samtools stats -@ "$THREADS" "$bam" > "$out/stats.txt"
log "genome mapping complete: $bam"
