# Method, assumptions, and tuning

## Why two mapping modes?

Direct RNA reads are mapped to the genome with `minimap2 -ax splice -uf -k14`,
which supports introns and uses the known direct-RNA transcript orientation. Secondary mappings
are kept because a true read from a repetitive family may map almost equally well
to several paralogues. After clustering, reads are mapped to their own transcript
seed with `map-ont`: this is intentionally not splice-aware because both are
transcript sequences.

Set `GENOME_MAP_MODE=no-splice` when reads should align contiguously, such as
against transcript references or intronless loci. For direct RNA mapped to a
genomic reference, `splice` is usually the appropriate starting
point. This setting affects initial family-read nomination only; cluster-local
polishing is always non-spliced. Genome nomination in `no-splice` mode uses
`MAP_PRESET` (default `map-ont`) with `-k14`, without `-uf`. Both modes build
the reference index with the matching preset and `-k14`; indexes are kept
separate by mode/preset. The old `reference.mmi` is not reused.

## Family selection

Use a curated BED file when annotations are inconsistent. Regex selection is a
convenience and matches the complete GFF attribute column. Confirm `family.bed`
before trusting results. Sequence names must agree between the GFF/BED and FASTA.

## Clustering is the main biological decision

The default 95% global identity is only a starting point. Raise it to separate
very similar paralogues; lower it to tolerate noisier reads. Length and alignment
coverage filters reduce clusters formed only by shared domains. Compare several
thresholds and inspect read support. Singleton clusters are excluded by default.

## Consensus limitations

Racon corrects the seed using all reads in a cluster. It does not model direct-RNA
modifications, transcript isoforms, allelic phase, or systematic basecalling
errors. A polished cluster is evidence for an expressed transcript family, not
automatically proof of a unique genomic locus. Validate against read alignments,
coverage, known splice boundaries, and orthogonal data.
