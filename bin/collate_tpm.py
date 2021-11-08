#!/usr/bin/env python3

import sys
import logging
from pathlib import Path

import pandas as pd


# Create logger
logger = logging.getLogger("collate_tpm.py")
fmt = logging.Formatter(
    fmt="%(asctime)s [%(name)s] %(levelname)s: %(msg)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
# Create handlers for logger
file_hdlr = logging.FileHandler(f"collate_tpm.log")
console_hdlr = logging.StreamHandler()

# Configure logger
logger.setLevel(logging.INFO)
for hdlr in [file_hdlr, console_hdlr]:
    hdlr.setFormatter(fmt)
    logger.addHandler(hdlr)


def collate_tpm(tpm_paths):
    """
    Given a list of StringTie 'abundance.txt' paths, return a matrix of
    gene_id, gene_name and Transcripts per Million (TPM) per sample.
    """

    tpm_df = None

    # Loop through files, concatenating tpm columns
    for path in tpm_paths:
        sample_name = path.stem.rstrip(".gene.abundance")

        logger.info(f"Processing sample {sample_name}.")

        df = pd.read_csv(
            path,
            sep="\t",
            index_col=0,
            usecols=[
                "Gene ID",
                "Gene Name",
                "Reference",
                "Strand",
                "Start",
                "End",
                "TPM",
            ],
        )
        df.rename(columns={"TPM": sample_name}, inplace=True)

        # If df has duplicates due to a gene being in multiple areas (see
        # https://github.com/gpertea/stringtie/issues/192#issuecomment-411964560)
        # duplicates are logged, and the first of all gene information is used
        # (which is only relevant if the first sample has duplicates, as subsequent
        # samples only have their tpm information appended) while the TPM mean
        # is used.
        if df.index.has_duplicates:
            dupes = df[df.index.duplicated(keep=False)]

            logger.warning(
                f'The following duplicates were found in sample "{sample_name}:'
            )
            for row in dupes.to_string().split(sep="\n"):
                logger.warning(row)

            df = df.groupby(df.index).agg(
                {
                    "Gene Name": "first",
                    "Reference": "first",
                    "Strand": "first",
                    "Start": "first",
                    "End": "first",
                    sample_name: "mean",
                }
            )
            logger.warning("Merged duplicates.")

        if tpm_df is None:
            tpm_df = df.copy()
        else:
            # tpm_df = pd.concat([tpm_df, df[["TPM"]]], axis="columns")
            tpm_df = tpm_df.join(df[[sample_name]], how="outer")

    # Provide machine-friendly index names
    tpm_df.index.set_names(["gene_id"], inplace=True)

    # Seems redundant to keep the other column information and then drop it
    # (which is true). I did this because otherwise, I'd have to modify
    # rna-features to make sure it was compatible with the extra information.
    # I kept the information up to now so someone could choose to keep it in
    # the future if they wanted to, and modify rna-features to be compatible.
    tpm_df = tpm_df.drop(
        columns=["Gene Name", "Reference", "Strand", "Start", "End"]
    )

    logger.info("Collation completed.")
    return tpm_df


if __name__ == "__main__":
    tpm_paths = [Path(path) for path in sys.argv[1:]]
    tpm_df = collate_tpm(tpm_paths)
    tpm_df.to_csv("tpm.tsv", sep="\t")
