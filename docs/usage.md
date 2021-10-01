# nf-core/llrnaseq: Usage

## Samplesheet input

You will need to create a samplesheet with information about the samples you would like to analyse before running the pipeline. Use this parameter to specify its location. It has to be a comma-separated file with 4 columns, and a header row as shown in the examples below.

```console
--input '[path to samplesheet file]'
```

### Multiple runs of the same sample

The `sample` identifiers have to be the same when you have re-sequenced the same sample more than once e.g. to increase sequencing depth. The pipeline will concatenate the raw reads before performing any downstream analysis. Below is an example for the same sample sequenced across 3 lanes:

```console
sample,fastq_1,fastq_2,strandedness
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz,unstranded
CONTROL_REP1,AEG588A1_S1_L003_R1_001.fastq.gz,AEG588A1_S1_L003_R2_001.fastq.gz,unstranded
CONTROL_REP1,AEG588A1_S1_L004_R1_001.fastq.gz,AEG588A1_S1_L004_R2_001.fastq.gz,unstranded
```

### Full samplesheet

The pipeline will auto-detect whether a sample is single- or paired-end using the information provided in the samplesheet. The samplesheet can have as many columns as you desire, however, there is a strict requirement for the first 4 columns to match those defined in the table below.

A final samplesheet file consisting of both single- and paired-end data may look something like the one below. This is for 6 samples, where `TREATMENT_REP3` has been sequenced twice.

```console
sample,fastq_1,fastq_2,strandedness
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz,forward
CONTROL_REP2,AEG588A2_S2_L002_R1_001.fastq.gz,AEG588A2_S2_L002_R2_001.fastq.gz,forward
CONTROL_REP3,AEG588A3_S3_L002_R1_001.fastq.gz,AEG588A3_S3_L002_R2_001.fastq.gz,forward
TREATMENT_REP1,AEG588A4_S4_L003_R1_001.fastq.gz,,reverse
TREATMENT_REP2,AEG588A5_S5_L003_R1_001.fastq.gz,,reverse
TREATMENT_REP3,AEG588A6_S6_L003_R1_001.fastq.gz,,reverse
TREATMENT_REP3,AEG588A6_S6_L004_R1_001.fastq.gz,,reverse
```

| Column         | Description                                                                                                                                                                            |
| -------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sample`       | Custom sample name. This entry will be identical for multiple sequencing libraries/runs from the same sample. Spaces in sample names are automatically converted to underscores (`_`). |
| `fastq_1`      | Full path to FastQ file for Illumina short reads 1. File has to be gzipped and have the extension ".fastq.gz" or ".fq.gz".                                                             |
| `fastq_2`      | Full path to FastQ file for Illumina short reads 2. File has to be gzipped and have the extension ".fastq.gz" or ".fq.gz".                                                             |
| `strandedness` | Sample strand-specificity. Must be one of `unstranded`, `forward` or `reverse`.                                                                                                        |

An [example samplesheet](../assets/samplesheet.csv) has been provided with the
pipeline.

> **NB:** The `group` and `replicate` columns were replaced with a single
> `sample` column as of v3.1 of the pipeline. The `sample` column is
> essentially a concatenation of the `group` and `replicate` columns, however
> it now also offers more flexibility in instances where replicate information
> is not required e.g. when sequencing clinical samples. If all values of
> `sample` have the same number of underscores, fields defined by these
> underscore-separated names may be used in the PCA plots produced by the
> pipeline, to regain the ability to represent different groupings.

### Create a samplesheet from a directory of fastq files
An executable Python script called `fastq_dir_to_samplesheet.py` has been
provided if you would like to auto-create an input samplesheet based on a
directory containing FastQ files before you run the pipeline (requires Python 3
installed locally) e.g.

```console
wget -L https://raw.githubusercontent.com/SpikyClip/llrnaseq/master/bin/fastq_dir_to_samplesheet.py

./fastq_dir_to_samplesheet.py <FASTQ_DIR> samplesheet.csv \
--strandedness reverse \
--read1_extension _1.fastq.gz \
--read2_extension _2.fastq.gz \
--sanitise_name \
--SANITISE_NAME_DELIMITER '_' \
--SANITISE_NAME_INDEX 1
```

The read extension arguments specify the suffix pattern for `read1` and `read2`
files. the `--sanitise_name` argument (default `false`) allows the extraction
of a sample name from the file basename. Here, it splits the base name by
underscores (`_`) and returns the first index group (base 1) as the sample
name. If `--sanitise_name` is not provided, the sample name defaults to the
file basename. The `--help` argument will show the full list of arguments.

## Alignment options

By default, the pipeline uses
 [HISAT2](https://ccb.jhu.edu/software/hisat2/index.shtml) aligner (i.e.
 `--aligner hisat2`) to map the raw FastQ reads to the reference genome.

## Reference genome files

The minimum reference genome requirements are a FASTA and GTF file. However,
it is more storage and compute friendly if you are able to re-use reference
genome files as efficiently as possible. It is recommended to use the
`--save_reference` parameter if you are using the pipeline to build new indices
(e.g. those unavailable on [AWS
iGenomes](https://nf-co.re/usage/reference_genomes)) so that you can save them
somewhere locally. The index building step can be quite a time-consuming
process and it permits their reuse for future runs of the pipeline to save disk
space. You can then either provide the appropriate reference genome files on
the command-line via the appropriate parameters (e.g. `--hisat2_index
'/path/to/hisat2/index/'`) or via a custom config file.

* If `--genome` is provided then the FASTA and GTF files (and existing indices)
  will be automatically obtained from AWS-iGenomes unless these have already
  been downloaded locally in the path specified by `--igenomes_base`.

> **NB:** Compressed reference files are also supported by the pipeline i.e.
> standard files with the `.gz` extension and indices folders with the `tar.gz`
> extension.

<!-- If you are using [GENCODE](https://www.gencodegenes.org/) reference genome
files please specify the `--gencode` parameter because the format of these
files is slightly different to ENSEMBL genome files:

* The `--gtf_group_features_type` parameter will automatically be set to
  `gene_type` as opposed to `gene_biotype`, respectively.
* If you are running Salmon, the `--gencode` flag will also be passed to the
  index building step to overcome parsing issues resulting from the transcript
  IDs in GENCODE fasta files being separated by vertical pipes (`|`) instead of
  spaces (see [this issue](https://github.com/COMBINE-lab/salmon/issues/15)). -->

## Running the pipeline

The typical command for running the pipeline on the LIMS-HPCC is as follows:

```console
nextflow run SpikyClip/rnaseq \
-profile lims \
--input samplesheet.csv \
--genome GRCh37
```

This will launch the pipeline with the `lims` configuration profile. See below
for more information about profiles.

Note that the pipeline will create the following files in your working
directory:

```console
work            # Directory containing the nextflow working files
results         # Finished results (configurable, see below)
.nextflow_log   # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code
from GitHub and stores it as a cached version. When running the pipeline after
this, it will always use the cached version if available - even if the pipeline
has been updated since. To make sure that you're running the latest version of
the pipeline, make sure that you regularly update the cached version of the
pipeline:

```console
nextflow pull SpikyClip/llrnaseq
```

## Core Nextflow arguments

> **NB:** These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen).

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give
configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the
pipeline to use software packaged using different methods (Docker, Singularity,
Podman, Shifter, Charliecloud, Conda) - see below. When using Biocontainers,
most of these software packaging methods pull Docker containers from quay.io
e.g [FastQC](https://quay.io/repository/biocontainers/fastqc) except for
Singularity which directly downloads Singularity images via https hosted by the
[Galaxy project](https://depot.galaxyproject.org/singularity/) and Conda which
downloads and installs software locally from
[Bioconda](https://bioconda.github.io/).

> We highly recommend the use of Docker or Singularity containers for full
> pipeline reproducibility, however when this is not possible, Conda is also
> supported.

The pipeline also dynamically loads configurations from
[https://github.com/nf-core/configs](https://github.com/nf-core/configs) when
it runs, making multiple config profiles for various institutional clusters
available at run time. For more information and to see if your system is
available in these configs please see the [nf-core/configs
documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker`
- the order of arguments is important! They are loaded in sequence, so later
profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all
software to be installed and available on the `PATH`. This is _not_
recommended.

* `lims`
    * A configuration profile for the LIMS-HPCC.
* `docker`
    * A generic configuration profile to be used with
      [Docker](https://docker.com/)
* `singularity`
    * A generic configuration profile to be used with
      [Singularity](https://sylabs.io/docs/)
* `podman`
    * A generic configuration profile to be used with
      [Podman](https://podman.io/)
* `shifter`
    * A generic configuration profile to be used with
      [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
* `charliecloud`
    * A generic configuration profile to be used with
      [Charliecloud](https://hpc.github.io/charliecloud/)
* `conda`
    * A generic configuration profile to be used with
      [Conda](https://conda.io/docs/). Please only use Conda as a last resort
      i.e. when it's not possible to run the pipeline with Docker, Singularity,
      Podman, Shifter or Charliecloud.
* `test`
    * A profile with a complete configuration for automated testing
    * Includes links to test data so needs no other parameters

### `-resume`

Specify this when restarting a pipeline. Nextflow will used cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously.

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Pipeline-specific nextflow arguments

To see a full list of arguments execute the following command:
```console
nextflow run SpikyClip/llrnaseq --help
```

## Custom configuration

Pipeline settings can be configured on a per-user profile basis or on a
per-project basis. See the main [Nextflow
documentation](https://www.nextflow.io/docs/latest/config.html) for more
information about creating your own configuration files.

For example, some of the modules loaded using the `-profile lims` option may be
outdated. To override module loading for a particular process in the `lims`
profile so that Nextflow uses your own installation of a program, add the
following `nextflow.config` file to your `.nextflow` folder (affects all user's
runs) or in your project folder (affects that project only):

```groovy
profiles {
    lims {
        process {
            withName: 'STRINGTIE*' {module = ''}
        }
    }
}
```

This overrides the module loading for all processes starting with `STRINGTIE`
allowing Nextflow to use a local installation of `stringtie` that is available
on `$PATH`.

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow
process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your
terminal so that the workflow does not stop if you log out of your session. The
logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a
detached session which you can log back into at a later time. Some HPC setups
also allow you to run nextflow within a cluster job submitted your job
scheduler (from where it submits more jobs).