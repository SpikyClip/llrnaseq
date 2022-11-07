//
// Uncompress and prepare reference genome files
//

params.genome_options       = [:]
params.index_options        = [:]
params.hisat2_index_options = [:]

include {
    GUNZIP as GUNZIP_FASTA
    GUNZIP as GUNZIP_GTF              } from '../../modules/nf-core/gunzip/main'                    addParams( options: params.genome_options       )
include { UNTAR as UNTAR_HISAT2_INDEX } from '../../modules/nf-core/untar/main'                     addParams( options: params.hisat2_index_options )
include { HISAT2_EXTRACTSPLICESITES   } from '../../modules/nf-core/hisat2/extractsplicesites/main' addParams( options: params.hisat2_index_options )
include { HISAT2_BUILD                } from '../../modules/nf-core/hisat2/build/main'              addParams( options: params.hisat2_index_options )

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
    ch_splicesites    = Channel.empty()
    ch_hisat2_index   = Channel.empty()
    ch_hisat2_version = Channel.empty()
    if ('hisat2' in prepare_tool_indices) {
        if (!params.splicesites) {
            ch_splicesites    = HISAT2_EXTRACTSPLICESITES ( ch_gtf ).txt
            ch_hisat2_version = HISAT2_EXTRACTSPLICESITES.out.version
        } else {
            ch_splicesites = file(params.splicesites)
        }
        if (params.hisat2_index) {
            if (params.hisat2_index.endsWith('.tar.gz')) {
                ch_hisat2_index = UNTAR_HISAT2_INDEX ( params.hisat2_index ).untar
            } else {
                ch_hisat2_index = file(params.hisat2_index)
            }
        } else {
            ch_hisat2_index   = HISAT2_BUILD ( ch_fasta, ch_gtf, ch_splicesites ).index
            ch_hisat2_version = HISAT2_BUILD.out.version
        }
    }

    emit:
    fasta            = ch_fasta            // path: genome.fasta
    gtf              = ch_gtf              // path: genome.gtf
    splicesites      = ch_splicesites      // path: genome.splicesites.txt
    hisat2_index     = ch_hisat2_index     // path: hisat2/index/
    hisat2_version   = ch_hisat2_version   // path: *.version.txt
}
