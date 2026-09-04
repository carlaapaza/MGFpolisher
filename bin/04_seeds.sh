#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd); source "$ROOT/lib/common.sh"
out="$RUN_DIR/04_seeds"; mkdir -p "$out"
reads="$RUN_DIR/02_family_reads/family_reads.fasta"; members="$RUN_DIR/03_clusters/membership.tsv"
need_file "$reads"; need_file "$members"
seqkit fx2tab -nl "$reads" > "$out/read_lengths.tsv"
awk -F '\t' 'NR==FNR{len[$1]=$2;next} FNR>1{print $1"\t"$2"\t"len[$2]}' "$out/read_lengths.tsv" "$members" | LC_ALL=C sort -k1,1 -k3,3n > "$out/member_lengths.tsv"
awk -F '\t' -v OFS='\t' -v min="$MIN_CLUSTER_SIZE" '
 function emit(  m,lo,hi,target,best,d,i){if(n<min)return;m=(n+1)/2;lo=int(m);hi=(m==lo?lo:lo+1);target=(L[lo]+L[hi])/2;best=1;for(i=2;i<=n;i++){d=L[i]-target;if(d<0)d=-d;if(d<bestd){best=i;bestd=d}}print C,R[best],L[best],target,n}
 {if(C!=""&&$1!=C)emit();if($1!=C){C=$1;n=0}n++;R[n]=$2;L[n]=$3;d=L[n];bestd=1e99} END{emit()}' "$out/member_lengths.tsv" > "$out/seeds.tsv"
cut -f2 "$out/seeds.tsv" > "$out/seed_names.txt"; need_file "$out/seed_names.txt"
seqkit grep -f "$out/seed_names.txt" "$reads" | seqkit replace -p '^(.+)$' -r '{kv}' -k <(awk -F '\t' '{print $2"\t"$1"|seed|source="$2}' "$out/seeds.tsv") -o "$out/seeds.fasta"
log "median-length seeds selected: $out/seeds.fasta"
