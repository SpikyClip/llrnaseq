// 
// Quantification with Stringtie
// 

params.stringtie_options = [:]

include { STRINGTIE   } from '../../modules/nf-core/stringtie/stringtie/main' addParams( options: params.stringtie_options )
include { COLLATE_TPM } from '../../modules/local/collate_tpm'

workflow STRINGTIE_TPM {
    take:
    bam // channel: [val(meta), path(bam)]
    gtf // channel: path(gtf)

    main:
    // 
    // First pass with Stringtie
    // 
    STRINGTIE( bam, gtf )

    // 
    // Collate all tpm counts for each sample
    // 

    STRINGTIE.out.abundance
    .map { meta, abundance -> abundance}
    .collect()
    .set{ tpm_paths }

    COLLATE_TPM( tpm_paths )

    emit:
    coverage_gtf   = STRINGTIE.out.coverage_gtf
    transcript_gtf = STRINGTIE.out.transcript_gtf
    abundance      = STRINGTIE.out.abundance
    ballgown       = STRINGTIE.out.ballgown

    tpm            = COLLATE_TPM.out.tpm

    version        = STRINGTIE.out.version
}
