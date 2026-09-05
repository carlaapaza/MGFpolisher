#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd); source "$ROOT/lib/common.sh"
need minimap2; need samtools; need seqkit; need cd-hit-est; need racon; need awk
need_file "$READS"; need_file "$REFERENCE_FASTA"
if [[ -n ${FAMILY_BED:-} ]]; then need_file "$FAMILY_BED"; else
    need_file "${ANNOTATION_GFF:-}"; [[ -n ${FAMILY_REGEX:-} ]] || die "set FAMILY_BED or FAMILY_REGEX"
fi
[[ "$HIT_MODE" == any || "$HIT_MODE" == primary ]] || die "HIT_MODE must be any or primary"
case "$GENOME_MAP_MODE" in
  splice|no-splice) ;;
  *) die "GENOME_MAP_MODE must be splice or no-splice" ;;
esac
mkdir -p "$RUN_DIR/00_metadata" logs
{
  printf 'run_name\t%s\nreads\t%s\nreference\t%s\n' "$RUN_NAME" "$READS" "$REFERENCE_FASTA"
  printf 'genome_map_mode\t%s\nmap_preset\t%s\n' "$GENOME_MAP_MODE" "$MAP_PRESET"
  for p in minimap2 samtools seqkit cd-hit-est racon; do printf '%s\t' "$p"; "$p" --version 2>&1 | head -n1; done
} > "$RUN_DIR/00_metadata/provenance.tsv"
env | LC_ALL=C sort | awk -F= '/^(READS|REFERENCE_FASTA|ANNOTATION_GFF|FAMILY_|FEATURE_TYPE|RUN_NAME|OUTPUT_ROOT|THREADS|GENOME_MAP_MODE|MAP_PRESET|HIT_MODE|MIN_MAPQ|CLUSTER_|MEMORY_MB|MIN_CLUSTER_SIZE|POLISH_)/' > "$RUN_DIR/00_metadata/resolved.env"
log "checks passed; metadata written to $RUN_DIR/00_metadata"
