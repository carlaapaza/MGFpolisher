# MGFpolisher

**M**ulti **G**ene **F**amily polisher!

MGFpolisher is a Bash pipeline for recovering and polishing
expressed members of difficult, repetitive multi-gene families from Oxford
Nanopore direct-RNA reads. It uses permissive genome mapping to nominate reads,
clusters complete reads, chooses a median-length seed per cluster, and performs
cluster-local iterative polishing.

> Closely related paralogues can collapse if clustering thresholds are too permissive. 
> Inspect the cluster and mapping reports before biological interpretation.

## Quick start

```bash
cd ~/Desktop/mgfpolisher
conda env create -f env/environment.yml
conda activate mgfpolisher
cp config/example.env config/my_run.env
# Put inputs in data/reads and data/reference as named in the config.
# Edit FAMILY_REGEX in config/my_run.env
bin/mgfpolisher run config/my_run.env
```

Inputs may be FASTQ/FASTQ.GZ or an unaligned BAM. Family loci can be supplied as
a BED file (`FAMILY_BED`) or selected from GFF3 attributes with a case-insensitive
extended regular expression (`FAMILY_REGEX`). BED takes precedence.

Genome mapping is configurable with `GENOME_MAP_MODE`: use
`splice` (default) or `no-splice`. In non-spliced mode,
`MAP_PRESET` controls the minimap2 preset and defaults to `map-ont`.

Relative input and output paths are resolved from the project folder, even when
running the command from another directory. Absolute paths remain supported.
Override inputs at execution time without editing the config:

```bash
bin/mgfpolisher run config/my_run.env --reads /my/reads.fastq.gz --reference /my/genome.fasta --annotation /my/annotation.gff3
# Resolve all relative input/output paths under a different folder:
bin/mgfpolisher run config/my_run.env --data-dir /my/dataset --run-name sample2
```

`--data-dir` defaults to the project folder; a relative `--data-dir` is resolved
from the current working directory. Paths passed through the other options use
that base too. `--family-bed`, `--output-root`, and `--map-mode` are also supported.
The config filename itself is relative to the current working directory.
Existing configs using `direct-rna-splice` are accepted as an alias for
`splice`. Both modes use `-k14`; only `splice` uses `-uf`. Indexes are built
with the matching preset and k-mer size, separately for each mode/preset.

Useful commands:

```bash
bin/mgfpolisher check config/my_run.env
bin/mgfpolisher run config/my_run.env
bin/mgfpolisher step 03 config/my_run.env
bin/mgfpolisher clean config/my_run.env   # asks before removing this run's results
```

Outputs are isolated under `results/$RUN_NAME/`. The final polished transcripts
are in `06_polish/mgfpolisher.polished.fasta`; cluster membership, per-round edits,
mapping summaries, tool versions, and the resolved configuration are retained.

## Workflow

1. Validate inputs and record configuration/software versions.
2. Map direct-RNA reads to the genome using minimap2's direct-RNA splice settings,
   retaining secondary hits to avoid discarding multi-mappers.
3. Select family loci and recover each nominated read in full.
4. Cluster full reads with CD-HIT-EST.
5. Select the member nearest each cluster's median length as seed.
6. Polish each cluster independently with minimap2 + Racon until the configured
   iteration limit; report sequence change between rounds.

See [docs/METHODS.md](docs/METHODS.md) for assumptions and parameter guidance.

## Citation

Please cite minimap2, samtools, SeqKit, CD-HIT, and Racon when using MGFpolisher.
