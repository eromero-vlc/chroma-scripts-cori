# chroma-scripts

Scripts to manage the chroma's workflow on SLURM

```           
  lime --> *chroma* --> eigs.mod --> *chroma* +-> meson.sdb   -+-> *redstar*
                                              |                |
                                              +-> baryon.sdb  -+
                                              |                |
                                              +-> prop.sdb    -+
                                              |                |
                                              +-> genprop.sdb -+
                                              |                |
                                              +-> disco.sdb   -+
```
## Basic characteristics

- Idempotent: it is safe to call twice `create.sh`, `launch.sh`, and `check.sh`

- Group similar tasks into a single SLURM job

## Basic script usage

1. Modify `ensembles.sh`, which centralizes most of the options

2. If using globus, check credentials with `globus_check.sh`

3. If bringing files from jlab, set `lime_transfer_from_jlab` to `yes` 
   (or `eigs_` or `prop_` or `gprop_` ...) in `ensemble.sh`  and run
   `bring-from-jlab.sh` to annotate the transfers and run `check.sh`
   to execute them

4. Run `create.sh` to create jobs

5. Run `launch.sh` to submit jobs that haven't been submitted yet
   or failed

5. Run `check.sh` to start globus transfers to jlab from
   successful jobs and mark failed jobs to relaunch
