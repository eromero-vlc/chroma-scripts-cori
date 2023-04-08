# chroma-scripts

Scripts to manage the chroma's workflow on SLURM

```           
  lime --> *chroma* --> eigs.mod --> *chroma* +-> meson.mod   -+-> *redstar*
                                              |                |
                                              +-> baryon.mod  -+
                                              |                |
                                              +-> prop.mod    -+
                                              |                |
                                              +-> genprop.mod -+
```
## Basic characteristics

- Idempotent: it is safe to call twice the same script

- Group similar tasks into a single SLURM job

## Basic script usage

1. Modify `ensembles.sh`, which centralizes most of the options

2. If using globus, check credentials with `globus_chech.sh`

3. Run `create.sh` to create jobs

4. Run `launch.sh` to submit jobs that haven't been submitted yet
   or failed

5. Run `check.sh` to start globus transfers to jlab from
   successful jobs and mark failed jobs to relaunch
