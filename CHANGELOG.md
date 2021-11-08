# SpikyClip/llrnaseq: Changelog

```
e20abf6 (HEAD -> master, tag: 0.3.3-dev) Merge branch 'dev'
4ef02ea (origin/master) Added collate_tpm.log file to stringtie results folder.
d440af2 (origin/dev, dev) Added collate_tpm.log file to stringtie results folder.
026e6a0 Fixed an issue caused by Stringtie producing duplicate genes, affecting TPM collation.
58034ee (tag: 0.3.2-dev) removed
4a3c2f3 (tag: 0.3.1-dev) Bumped version.
85d1e15 Merge branch 'dev'
0ba86d2 Added link to use of -resume in usage.md.
555a46f Formatting.
26f6ae1 Tweaked to always get absolute path for csv.
42f085e Tweaked slurm settings.
b7b35d1 Corrected executor settings.
65e3665 (tag: 0.3.0-dev) Merge branch 'dev'
d0893ca Removed 2 pass stringtie, made compatible with version 1.3.5 on HPCC.
b962be6 Added version numbers.
b233bfb Corrected link.
f963d1d (tag: 0.2.1-dev) Merge.
6dfcfac Bumped version number.
470070b Reduced index to gene_id only.
7717fcc Bumped version.
9c28995 (tag: 0.2.0-dev) Bumped version.
25dad27 Fixed double version issue for hisat2.
972c9ec Finalised TODOs.
dab7e08 Added correct version number extraction for Hisat2.
33add3f Fixed manifest.
7086cf5 Cleaned up readme's and lint.
d79d29f Simplified StringTie module selector.
2cff8ff Added STRINGTIE_MERGE module load.
8e7e443 Added tpm collate and cleaned up code.
c62ef78 Added stringtie, working on local.
bf22b90 (tag: 0.1.1-dev) Bumped version
ac29488 added python3 to py script shebang to stop python2 conflicts with f-strings. Switch DAG format to .png
081febb (tag: 0.1.0-dev) Removed .view() used for debugging
c663a9f Bumped version
2eba11e General linting
f760177 Corrected typo
1d06c4f Fixed bug where strandedness was not carried by meta, and added featurecounts
83fd5a5 Alignment works on hpcc
31a7476 (tag: 0.0.2-dev) Fixed multiqc filename filtering and format
7917ae0 deleted non matching underscore
d578055 Module commands were overriding each other, separated them out
3b5298f Added samtool module load to hisat2 alignment
64bb34a Attempting to fix withName regex
35a1c5b Added module loading for samtools and HISAT
9e8c3a0 Added hisat2 alignment, samtools sorting and indexing
0d59f4c Bumped version to 0.0.1-alpha
1a542ae Samples with same name now merged before analysis
bc7053e Gave fastq_dir_to_samplesheet.py executable permissions and updated readmes
6fa383d added hisat2 module load for indexing
16b4bff added valid_params to initialise functions
19174e2 Updated schema.json
8569ac9 indexing working on local
06056bd Added test and test_full profiles
ae76377 Added strandedness check and python script to gen input.csv, corrected --skip_trimming description in schema.json
40fa71e Reduced long process time on hpc to 8 hours to utilise 8h compute nodes
7f1b639 Added some optimisations to slurm configs and java memory usage
a056780 Added module requirement for process TRIMGALORE
8947844 added fastqc_trimgalore sub-workflow (working on dev)
e7afdf5 Configured standard profile memory and cpu requirements
a425687 added lims profile to nextflow.config
006b41f Restored UNIX file permissions
765c218 (origin/TEMPLATE, TEMPLATE) initial template build from nf-core/tools, version 2.1
```