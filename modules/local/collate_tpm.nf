include { saveFiles } from './functions'

params.options = [:]

process COLLATE_TPM {
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'stringtie', meta:[:], publish_by_meta:[]) }

    conda (params.enable_conda ? "conda-forge::pandas=1.4.3" : null)
    container "quay.io/biocontainers/pandas:1.4.3"

    input:
    path(abundance)

    output:
    path("tpm.tsv"), emit: tpm
    path("collate_tpm.log"), emit: log

    shell:
    """
    collate_tpm.py !{abundance}
    """
}