# nf-core/llrnaseq: Installation

1. Installing it directly and moving the created executable `nextflow` to a
   folder accessible by `$PATH`:
   
   ```console
   # Load java module if on the LIMS-HPCC
   module load java/1.8.0_66

   wget -qO- https://get.nextflow.io | bash
   ```
2. Installing it with `conda`:

   ```console
   conda install nextflow
   ```

## Troubleshooting

1. `Cannot find Java or it's a wrong version`

    - Make sure [Java 8 or
      later](https://www.nextflow.io/docs/latest/getstarted.html#requirements)
      is installed.
    - If on the LIMS-HPCC, load the java module:

      ```console
      module load java/1.8.0_66
      ```
2. `nextflow: command not found`
    - make sure the `nextflow` executable is located in a folder accessible by
      $PATH. Here is a
      [tutorial](https://linuxize.com/post/how-to-add-directory-to-path-in-linux/)
      on how to make a folder accessible by $PATH.

3. Conda won't install `nextflow` without updating (which requires sudo
   permissions)
   - Disable conda update notifications:
     ```console
     conda config --set notify_outdated_conda False
     ```