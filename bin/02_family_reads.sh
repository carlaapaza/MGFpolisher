#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd); source "$ROOT/lib/common.sh"
out="$RUN_DIR/02_family_reads"; mkdir -p "$out"
bam="$RUN_DIR/01_map/all.sorted.bam"; need_file "$bam"
bed="$out/family.bed"
if [[ -n ${FAMILY_BED:-} ]]; then cp "$FAMILY_BED" "$bed"; else
  awk -F '\t' -v OFS='\t' -v type="$FEATURE_TYPE" -v regex="$FAMILY_REGEX" '
    !/^#/ && NF>=9 && $3==type && tolower($9) ~ tolower(regex) {
      id="family_locus"; n=split($9,a,";"); for(i=1;i<=n;i++) if(a[i]~/^ID=/){id=substr(a[i],4);break}
      print $1,$4-1,$5,id,0,$7
    }' "$ANNOTATION_GFF" | LC_ALL=C sort -k1,1 -k2,2n > "$bed"
fi
need_file "$bed"
flags=(-F UNMAP); [[ "$HIT_MODE" == primary ]] && flags=(-F UNMAP,SECONDARY,SUPPLEMENTARY)
samtools view -@ "$THREADS" -q "$MIN_MAPQ" -L "$bed" "${flags[@]}" "$bam" | cut -f1 | LC_ALL=C sort -u > "$out/read_names.txt"
need_file "$out/read_names.txt"
fastq_stream | seqkit grep -f "$out/read_names.txt" -o "$out/family_reads.fastq.gz"
seqkit fq2fa "$out/family_reads.fastq.gz" -o "$out/family_reads.fasta"
printf 'family_loci\t%s\ncandidate_reads\t%s\n' "$(wc -l < "$bed" | tr -d ' ')" "$(wc -l < "$out/read_names.txt" | tr -d ' ')" > "$out/summary.tsv"
log "family reads recovered in full: $out/family_reads.fastq.gz"
