#!/usr/bin/env python3

import sys
from pathlib import Path

import pandas as pd


def collate_tpm(tpm_paths):
    """
    Given a list of StringTie 'abundance.txt' paths, return a matrix of
    gene_id, gene_name and Transcripts per Million (TPM) per sample.
    """

    tpm_df = None

    # Loop through files, concatenating tpm columns
    for path in tpm_paths:
        sample_name = path.stem.rstrip("_pass_2.gene.abundance")

        df = pd.read_csv(
            path,
            sep="\t",
            index_col=[0, 1],
            usecols=["Gene ID", "Gene Name", "TPM"],
        )
        df.rename(columns={"TPM": sample_name}, inplace=True)

        if tpm_df is None:
            tpm_df = df.copy()

        else:
            tpm_df = pd.concat([tpm_df, df], axis="columns")

    # Provide machine-friendly index names
    tpm_df.index.set_names(["gene_id", "gene_name"], inplace=True)

    return tpm_df


if __name__ == "__main__":
    tpm_paths = [Path(path) for path in sys.argv[1:]]
    tpm_df = collate_tpm(tpm_paths)
    tpm_df.to_csv("tpm.tsv", sep="\t")
