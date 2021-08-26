//
// Uncompress and prepare reference genome files
//

params.genome_options       = [:]
params.index_options        = [:]
params.hisat2_index_options = [:]

include {
    GUNZIP as GUNZIP_FASTA
    GUNZIP as GUNZIP_GTF
    GUNZIP as GUNZIP_TRANSCRIPT_FASTA
    GUNZIP as GUNZIP_ADDITIONAL_FASTA } from '../../modules/nf-core/modules/gunzip/main'       addParams( options: params.genome_options       )
include { UNTAR as UNTAR_HISAT2_INDEX } from '../../modules/nf-core/modules/untar/main'        addParams( options: params.hisat2_index_options )
include { HISAT2_BUILD                } from '../../modules/nf-core/modules/hisat2/build/main' addParams( options: params.hisat2_index_options )

workflow PREPARE_GENOME {
    take:
    prepare_tool_indices // list  : tools to prepare indices for

    main:

    //
    // Uncompress genome fasta file if required
    //
    if (params.fasta.endsWith('.gz')) {
        ch_fasta = GUNZIP_FASTA ( params.fasta ).gunzip
    } else {
        ch_fasta = file(params.fasta)
    }

    //
    // Uncompress GTF annotation file or create from GFF3 if required
    //
    // ch_gffread_version = Channel.empty()
    if (params.gtf) {
        if (params.gtf.endsWith('.gz')) {
            ch_gtf = GUNZIP_GTF ( params.gtf ).gunzip
        } else {
            ch_gtf = file(params.gtf)
        }
    }

    //
    // Uncompress HISAT2 index or generate from scratch if required
    //
    ch_hisat2_index   = Channel.empty()
    ch_hisat2_version = Channel.empty()
    if ('hisat2' in prepare_tool_indices) {
        if (params.hisat2_index) {
            if (params.hisat2_index.endsWith('.tar.gz')) {
                ch_hisat2_index = UNTAR_HISAT2_INDEX ( params.hisat2_index ).untar
            } else {
                ch_hisat2_index = file(params.hisat2_index)
            }
        } else {
            ch_hisat2_index   = HISAT2_BUILD ( ch_fasta, ch_gtf ).index
            ch_hisat2_version = HISAT2_BUILD.out.version
        }
    }

    emit:
    fasta            = ch_fasta            // path: genome.fasta
    gtf              = ch_gtf              // path: genome.gtf
    hisat2_index     = ch_hisat2_index     // path: hisat2/index/
    hisat2_version   = ch_hisat2_version   // path: *.version.txt
}
