// 
// Quantification with Stringtie
// 

params.st_pass_1_options = [:]
params.st_pass_2_options = [:]
params.st_merge_options  = [:]

include { STRINGTIE as STRINGTIE_ONE } from '../../modules/nf-core/modules/stringtie/stringtie/main'   addParams( options: params.st_pass_1_options )
include { STRINGTIE as STRINGTIE_TWO } from '../../modules/nf-core/modules/stringtie/stringtie/main'   addParams( options: params.st_pass_2_options )
include { STRINGTIE_MERGE            } from '../../modules/nf-core/modules/stringtie/merge/main'       addParams( options: params.st_merge_options  )

workflow STRINGTIE_DE {
    take:
    bam       // channel: [val(meta), path(bam)]
    annot_gtf // channel: path(gtf)

    main:
    // 
    // First pass with Stringtie
    // 
    STRINGTIE_ONE( bam, annot_gtf )

    // Strip meta and collect as merge expects only list of gtf paths
    STRINGTIE_ONE.out.transcript_gtf
        .map { meta, gtf -> gtf }
        .collect()
        .set{ ch_stringtie_all_gtf }

    //
    // Merge gtf files to generate a global set of isoforms across samples
    //
    STRINGTIE_MERGE(ch_stringtie_all_gtf, annot_gtf)

    // 
    // Second pass with Stringtie using merged gtf as reference
    // 
    STRINGTIE_TWO( bam, STRINGTIE_MERGE.out.gtf )

    emit:
    pass_1_coverage_gtf   = STRINGTIE_ONE.out.coverage_gtf
    pass_1_transcript_gtf = STRINGTIE_ONE.out.transcript_gtf
    pass_1_abundance      = STRINGTIE_ONE.out.abundance
    pass_1_ballgown       = STRINGTIE_ONE.out.ballgown

    pass_2_coverage_gtf   = STRINGTIE_TWO.out.coverage_gtf
    pass_2_transcript_gtf = STRINGTIE_TWO.out.transcript_gtf
    pass_2_abundance      = STRINGTIE_TWO.out.abundance
    pass_2_ballgown       = STRINGTIE_TWO.out.ballgown

    version               = STRINGTIE_ONE.out.version
}
