#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
source "$ROOT/lib/common.sh"
(
 cd /tmp
 load_config "$ROOT/config/example.env"
 [[ "$READS" == "$ROOT/data/reads/direct_rna.fastq.gz" ]]
 [[ "$OUTPUT_ROOT" == "$ROOT/results" ]]
 [[ "$GENOME_MAP_MODE" == splice ]]
)
(
 load_config "$ROOT/config/example.env" --data-dir '/tmp/data folder' --reads reads.fastq --reference /tmp/ref.fa --annotation genes.gff --family-bed family.bed --output-root out --run-name sample --map-mode no-splice
 [[ "$READS" == '/tmp/data folder/reads.fastq' ]]
 [[ "$REFERENCE_FASTA" == /tmp/ref.fa ]]
 [[ "$ANNOTATION_GFF" == '/tmp/data folder/genes.gff' ]]
 [[ "$FAMILY_BED" == '/tmp/data folder/family.bed' ]]
 [[ "$RUN_DIR" == '/tmp/data folder/out/sample' ]]
 [[ "$GENOME_MAP_MODE" == no-splice ]]
)
(
 load_config "$ROOT/config/example.env" --data-dir local --map-mode direct-rna-splice
 [[ "$READS" == "$PWD/local/data/reads/direct_rna.fastq.gz" ]]
 [[ "$GENOME_MAP_MODE" == splice ]]
)
if (load_config "$ROOT/config/example.env" --reads) 2>/dev/null; then exit 1; fi
if (load_config "$ROOT/config/example.env" --unknown value) 2>/dev/null; then exit 1; fi
echo 'Config tests passed'
