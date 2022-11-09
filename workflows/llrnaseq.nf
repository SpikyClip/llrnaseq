/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def valid_params = [
    aligners       : ['hisat2'],
]

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowLlrnaseq.initialise(params, log, valid_params)

// Check input path parameters to see if they exist
def checkPathParamList = [
    params.input, params.multiqc_config, 
    params.fasta, params.gtf,
    params.hisat2_index,
    ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

// Check alignment parameters
def prepareToolIndices  = []
if (!params.skip_alignment) { prepareToolIndices << params.aligner }

// Save AWS IGenomes file containing annotation version
def anno_readme = params.genomes[ params.genome ]?.readme
if (anno_readme && file(anno_readme).exists()) {
    file("${params.outdir}/genome/").mkdirs()
    file(anno_readme).copyTo("${params.outdir}/genome/")
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Don't overwrite global params.modules, create a copy instead and use that within the main script.
def modules = params.modules.clone()

//
// MODULE: Local to the pipeline
//

// include { GET_SOFTWARE_VERSIONS } from '../modules/local/get_software_versions' addParams( options: [publish_files : ['tsv':'']] )

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//

def publish_genome_options = params.save_reference ? [publish_dir: 'genome']       : [publish_files: false]
def publish_index_options  = params.save_reference ? [publish_dir: 'genome/index'] : [publish_files: false]

def hisat2_build_options    = modules['hisat2_build']
if (!params.save_reference) { hisat2_build_options['publish_files'] = false }

include { INPUT_CHECK    } from '../subworkflows/local/input_check'    addParams( options: [:] )
include { PREPARE_GENOME } from '../subworkflows/local/prepare_genome' addParams( genome_options: publish_genome_options, index_options: publish_index_options, hisat2_index_options: hisat2_build_options )

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//

def cat_fastq_options     = modules['cat_fastq']
if (!params.save_merged_fastq) { cat_fastq_options['publish_files'] = false }

def multiqc_options       = modules['multiqc']
// !multiqc_options.args     += params.multiqc_title ? Utils.joinModuleArgs(["--title \"$params.multiqc_title\""]) : ''

def featurecounts_options = modules['subreads_featurecounts']


include { CAT_FASTQ             } from '../modules/nf-core/cat/fastq/main'             addParams( options: cat_fastq_options       )
include { MULTIQC               } from '../modules/nf-core/multiqc/main'               addParams( options: multiqc_options         )
include { SUBREAD_FEATURECOUNTS } from '../modules/nf-core/subread/featurecounts/main' addParams( options: featurecounts_options   )
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//

// Trimgalore
def trimgalore_options    = modules['trimgalore']
// !trimgalore_options.args  += params.trim_nextseq > 0 ? Utils.joinModuleArgs(["--nextseq ${params.trim_nextseq}"]) : ''
if (params.save_trimmed)  { trimgalore_options.publish_files.put('fq.gz','') }

// Hisat2
def hisat2_align_options         = modules['hisat2_align']
if (params.save_align_intermeds) { hisat2_align_options.publish_files.put('bam','') }
if (params.save_unaligned)       { hisat2_align_options.publish_files.put('fastq.gz','unmapped') }

// Samtools
def samtools_sort_genome_options    = modules['samtools_sort_genome']
def samtools_index_genome_options   = modules['samtools_index_genome']
// !samtools_index_genome_options.args += params.bam_csi_index ? Utils.joinModuleArgs(['-c']) : ''

// Block for conditional publishing of alignment files
if (['hisat2'].contains( params.aligner )) {
    samtools_sort_genome_options.publish_files.put('bam','')
    samtools_index_genome_options.publish_files.put('bai','')
    samtools_index_genome_options.publish_files.put('csi','')
}

// Stringtie
def stringtie_options   = modules['stringtie']
// !stringtie_options.args += params.stringtie_ignore_gtf ? '' : Utils.joinModuleArgs(['-e'])


include { FASTQC_TRIMGALORE } from '../subworkflows/nf-core/fastqc_trimgalore' addParams( fastqc_options: modules['fastqc'], trimgalore_options: trimgalore_options )
include { ALIGN_HISAT2      } from '../subworkflows/nf-core/align_hisat2'      addParams( align_options: hisat2_align_options, samtools_sort_options: samtools_sort_genome_options, samtools_index_options: samtools_index_genome_options, samtools_stats_options: samtools_index_genome_options )
include { STRINGTIE_TPM     } from '../subworkflows/nf-core/stringtie'         addParams( stringtie_options: stringtie_options )

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow LLRNASEQ {

    ch_versions = Channel.empty()


    //
    // SUBWORKFLOW: Uncompress and prepare reference genome files
    //
    PREPARE_GENOME (
        prepareToolIndices
    )


    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    )
    .map {
        meta, fastq ->
            meta.id = meta.id.split('_')[0..-2].join('_')
            [ meta, fastq ] }
    .groupTuple(by: [0])
    .branch {
        meta, fastq ->
            single  : fastq.size() == 1
                return [ meta, fastq.flatten() ]
            multiple: fastq.size() > 1
                return [ meta, fastq.flatten() ]
    }
    .set { ch_fastq }

    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    //
    // MODULE: Concatenate FastQ files from same sample if required
    //
    CAT_FASTQ (
        ch_fastq.multiple
    )
    .mix(ch_fastq.single)
    .set { ch_cat_fastq }


    //
    // MODULE: Run FastQC and trimgalore
    //
    FASTQC_TRIMGALORE (
        ch_cat_fastq,
        params.skip_fastqc || params.skip_qc,
        params.skip_trimming
    )
    ch_trimmed_reads     = FASTQC_TRIMGALORE.out.reads


    //
    // SUBWORKFLOW: Alignment with HISAT2
    //
    ch_hisat2_multiqc = Channel.empty()
    if (!params.skip_alignment && params.aligner == 'hisat2') {
        ALIGN_HISAT2 (
            ch_trimmed_reads,
            PREPARE_GENOME.out.hisat2_index,
            PREPARE_GENOME.out.splicesites
        )
        ch_genome_bam        = ALIGN_HISAT2.out.bam
        ch_genome_bam_index  = ALIGN_HISAT2.out.bai
        ch_samtools_stats    = ALIGN_HISAT2.out.stats
        ch_samtools_flagstat = ALIGN_HISAT2.out.flagstat
        ch_samtools_idxstats = ALIGN_HISAT2.out.idxstats
        ch_hisat2_multiqc    = ALIGN_HISAT2.out.summary
        if (params.bam_csi_index) {
            ch_genome_bam_index  = ALIGN_HISAT2.out.csi
        }
        ch_versions = ch_versions.mix(ALIGN_HISAT2.out.hisat2_version.first().ifEmpty(null))
        ch_versions = ch_versions.mix(ALIGN_HISAT2.out.samtools_version.first().ifEmpty(null))
    }

    // 
    // MODULE: Subreads featureCounts
    // 

    ch_genome_bam
        .map {
            meta, bam ->
            meta_subset = ["strandedness": meta.strandedness, "id": meta.strandedness]
            [meta_subset, bam]
        }
        .groupTuple()
        .set{ ch_feature_bam }

    SUBREAD_FEATURECOUNTS (
        ch_feature_bam,
        PREPARE_GENOME.out.gtf
    )

    // 
    // MODULE: Stringtie
    // 

    if (!params.skip_alignment && !params.skip_stringtie) {
        STRINGTIE_TPM(
            ch_genome_bam,
            PREPARE_GENOME.out.gtf
            )
        ch_versions = ch_versions.mix(STRINGTIE_TPM.out.version.first().ifEmpty(null))
    }


    //
    // MODULE: Pipeline reporting
    //

    // Gather software versions
    ch_versions = ch_versions.mix(PREPARE_GENOME.out.hisat2_version.ifEmpty(null))
    ch_versions = ch_versions.mix(FASTQC_TRIMGALORE.out.fastqc_version.first().ifEmpty(null))
    ch_versions = ch_versions.mix(FASTQC_TRIMGALORE.out.trimgalore_version.first().ifEmpty(null))
    ch_versions = ch_versions.mix(SUBREAD_FEATURECOUNTS.out.version.first().ifEmpty(null))

    // ch_versions
    //     .map { it -> if (it) [ it.baseName, it ] }
    //     .groupTuple()
    //     .map { it[1][0] }
    //     .flatten()
    //     .collect()
    //     .set { ch_versions }

    // GET_SOFTWARE_VERSIONS (
    //     ch_software_versions.map { it }.collect()
    // )

    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    //
    // MODULE: MultiQC
    //

    if (!params.skip_multiqc) {
    methods_description    = WorkflowLlrnaseq.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.collect().ifEmpty([]),
        ch_multiqc_custom_config.collect().ifEmpty([]),
        ch_multiqc_logo.collect().ifEmpty([])
    )
    multiqc_report = MULTIQC.out.report.toList()
    ch_versions    = ch_versions.mix(MULTIQC.out.versions)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.adaptivecard(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
