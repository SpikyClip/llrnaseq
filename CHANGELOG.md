<!-- 
Script from https://stackoverflow.com/questions/40865597/generate-changelog-from-commit-and-tag

#!/usr/bin/env bash
previous_tag=0
for current_tag in $(git tag --sort=-creatordate)
do

if [ "$previous_tag" != 0 ];then
    tag_date=$(git log -1 --pretty=format:'%ad' --date=short ${previous_tag})
    printf "## ${previous_tag} (${tag_date})\n\n"
    git log ${current_tag}...${previous_tag} --pretty=format:'*  %s' --reverse | grep -v Merge
    printf "\n\n"
fi
previous_tag=${current_tag}
done
 -->

# SpikyClip/llrnaseq: Changelog

## 0.4.0-dev (2022-11-09)

*  Updated changelog
*  Split lims profile and added new cluster support.
*  Tweaked config settings so unlabelled processes get 'day' queue.
*  Amended 'short*' partition name to 'short'.
*  Moved profiles to separate config file.
*  Added singularity cache directory.
*  Moved workdir to /tmp.
*  Added includeconfig statement.
*  Added missing profile statement.
*  Set workDir directly.
*  Can't set -work-dir in profile.
*  Amended singularity cache to point to home directory.
*  Added braces to /c/Users/Vikesh call.
*  Changed path to proper quotations to correct substitution.
*  Added pandas biocontainer to collate_tpm process.
*  Toggled scratch directive.
*  Testing scratch directory and higher queue size and lower pollinterval.
*  Clean up comments.
*  Disabled modules until all packages added to cluster.
*  Updated README.md now that singularity works on cluster.


## 0.3.3-dev (2021-11-08)

*  Fixed an issue caused by Stringtie producing duplicate genes, affecting TPM collation.
*  Added collate_tpm.log file to stringtie results folder.
*  Added collate_tpm.log file to stringtie results folder.


## 0.3.2-dev (2021-10-28)

*  removed


## 0.3.1-dev (2021-10-04)

*  Corrected executor settings.
*  Tweaked slurm settings.
*  Tweaked to always get absolute path for csv.
*  Formatting.
*  Added link to use of -resume in usage.md.
*  Bumped version.


## 0.3.0-dev (2021-10-04)

*  Corrected link.
*  Added version numbers.
*  Removed 2 pass stringtie, made compatible with version 1.3.5 on HPCC.


## 0.2.1-dev (2021-09-22)

*  Bumped version.
*  Reduced index to gene_id only.
*  Bumped version number.


## 0.2.0-dev (2021-09-21)

*  Added stringtie, working on local.
*  Added tpm collate and cleaned up code.
*  Added STRINGTIE_MERGE module load.
*  Simplified StringTie module selector.
*  Cleaned up readme's and lint.
*  Fixed manifest.
*  Added correct version number extraction for Hisat2.
*  Finalised TODOs.
*  Fixed double version issue for hisat2.
*  Bumped version.


## 0.1.1-dev (2021-09-06)

*  added python3 to py script shebang to stop python2 conflicts with f-strings. Switch DAG format to .png
*  Bumped version


## 0.1.0-dev (2021-08-31)

*  Alignment works on hpcc
*  Fixed bug where strandedness was not carried by meta, and added featurecounts
*  Corrected typo
*  General linting
*  Bumped version
*  Removed .view() used for debugging