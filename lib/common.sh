#!/usr/bin/env bash
set -euo pipefail

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }
need() { command -v "$1" >/dev/null 2>&1 || die "required program not found: $1"; }
need_file() { [[ -s "$1" ]] || die "missing or empty file: $1"; }

load_config() {
    local cfg=$1
    need_file "$cfg"
    # Config is a trusted shell-style file owned by the researcher.
    # shellcheck disable=SC1090
    source "$cfg"
    : "${READS:?set READS in config}"
    : "${REFERENCE_FASTA:?set REFERENCE_FASTA in config}"
    : "${RUN_NAME:?set RUN_NAME in config}"
    OUTPUT_ROOT=${OUTPUT_ROOT:-results}
    THREADS=${THREADS:-8}
    GENOME_MAP_MODE=${GENOME_MAP_MODE:-direct-rna-splice}
    MAP_PRESET=${MAP_PRESET:-map-ont}
    HIT_MODE=${HIT_MODE:-any}
    MIN_MAPQ=${MIN_MAPQ:-0}
    CLUSTER_IDENTITY=${CLUSTER_IDENTITY:-0.95}
    CLUSTER_LENGTH_RATIO=${CLUSTER_LENGTH_RATIO:-0.80}
    CLUSTER_SHORT_COVERAGE=${CLUSTER_SHORT_COVERAGE:-0.80}
    CLUSTER_LONG_COVERAGE=${CLUSTER_LONG_COVERAGE:-0.80}
    CLUSTER_WORD_SIZE=${CLUSTER_WORD_SIZE:-10}
    MEMORY_MB=${MEMORY_MB:-8000}
    MIN_CLUSTER_SIZE=${MIN_CLUSTER_SIZE:-2}
    POLISH_ROUNDS=${POLISH_ROUNDS:-3}
    POLISH_PRESET=${POLISH_PRESET:-map-ont}
    FEATURE_TYPE=${FEATURE_TYPE:-protein_coding_gene}
    RUN_DIR="$OUTPUT_ROOT/$RUN_NAME"
    export READS REFERENCE_FASTA ANNOTATION_GFF FAMILY_BED FAMILY_REGEX FEATURE_TYPE
    export RUN_NAME OUTPUT_ROOT RUN_DIR THREADS GENOME_MAP_MODE MAP_PRESET HIT_MODE MIN_MAPQ
    export CLUSTER_IDENTITY CLUSTER_LENGTH_RATIO CLUSTER_SHORT_COVERAGE
    export CLUSTER_LONG_COVERAGE CLUSTER_WORD_SIZE MEMORY_MB MIN_CLUSTER_SIZE
    export POLISH_ROUNDS POLISH_PRESET
}

fastq_stream() {
    case "$READS" in
        *.bam) samtools fastq -@ "$THREADS" -n "$READS" ;;
        *.gz) gzip -cd "$READS" ;;
        *) cat "$READS" ;;
    esac
}

run_step() {
    local number=$1 script_dir=$2
    "$script_dir/${number}_"*.sh
}
