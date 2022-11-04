include { saveFiles } from './functions'

params.options = [:]

process COLLATE_TPM {
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'stringtie', meta:[:], publish_by_meta:[]) }

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    // Pointed to an anaconda docker container with pandas until I can find a 
    // lightweight container and/or a singularity one.
    // if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
    //     container "https://depot.galaxyproject.org/singularity/python:3.8.3"
    // } else {
        container "continuumio/anaconda3"
    // }

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