#!/usr/bin/env nextflow
/*
========================================================================================
    nf-core/llrnaseq
========================================================================================
    Github : https://github.com/nf-core/llrnaseq
    Website: https://nf-co.re/llrnaseq
    Slack  : https://nfcore.slack.com/channels/llrnaseq
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
========================================================================================
    GENOME PARAMETER VALUES
========================================================================================
*/

params.fasta = WorkflowMain.getGenomeAttribute(params, 'fasta')
params.gtf   = WorkflowMain.getGenomeAttribute(params, 'gtf')
params.hisat2_index = WorkflowMain.getGenomeAttribute(params, 'hisat2')

/*
========================================================================================
    VALIDATE & PRINT PARAMETER SUMMARY
========================================================================================
*/

WorkflowMain.initialise(workflow, params, log)

/*
========================================================================================
    NAMED WORKFLOW FOR PIPELINE
========================================================================================
*/

include { LLRNASEQ } from './workflows/llrnaseq'

//
// WORKFLOW: Run main nf-core/llrnaseq analysis pipeline
//
workflow NFCORE_LLRNASEQ {
    LLRNASEQ ()
}

/*
========================================================================================
    RUN ALL WORKFLOWS
========================================================================================
*/

//
// WORKFLOW: Execute a single named workflow for the pipeline
// See: https://github.com/nf-core/rnaseq/issues/619
//
workflow {
    NFCORE_LLRNASEQ ()
}

/*
========================================================================================
    THE END
========================================================================================
*/
