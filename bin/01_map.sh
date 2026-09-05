#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd); source "$ROOT/lib/common.sh"
out="$RUN_DIR/01_map"; mkdir -p "$out"
need_file "$REFERENCE_FASTA"; need_file "$READS"
case "$GENOME_MAP_MODE" in
  splice)
    index_args=(-x splice -k14)
    map_args=(-ax splice -uf -k14)
    index_tag=splice
    ;;
  no-splice)
    index_args=(-x "$MAP_PRESET" -k14)
    map_args=(-ax "$MAP_PRESET" -k14)
    index_tag="no-splice.${MAP_PRESET//[^a-zA-Z0-9_-]/_}"
    ;;
  *) die "unsupported GENOME_MAP_MODE: $GENOME_MAP_MODE" ;;
esac
# Keep indexes separate by mode/preset; never reuse the old default-k index.
idx="$out/reference.${index_tag}.k14.mmi"; bam="$out/all.sorted.bam"
[[ -s "$idx" ]] || minimap2 -t "$THREADS" "${index_args[@]}" -d "$idx" "$REFERENCE_FASTA"
log "genome mapping mode: $GENOME_MAP_MODE"
fastq_stream | minimap2 -t "$THREADS" "${map_args[@]}" --secondary=yes -N 50 --MD "$idx" - 2> "$out/minimap2.log" | samtools sort -@ "$THREADS" -o "$bam" -
samtools index -@ "$THREADS" "$bam"
samtools flagstat -@ "$THREADS" "$bam" > "$out/flagstat.txt"
samtools stats -@ "$THREADS" "$bam" > "$out/stats.txt"
log "genome mapping complete: $bam"
