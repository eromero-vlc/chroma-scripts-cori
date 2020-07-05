# chroma-scripts-cori

Scripts to manage the chroma's workflow on [NERSC's cori](https://docs.nersc.gov/systems/cori/).

```           
  lime --->  *laplace_eigs*  --> eigs.mod ---> *harom* ---> baryon.mod -\
                                     \                                   )-> *redstar*
                                      \------> *chroma* ---> prop.mod --/
```
## Basic characteristics

- Idempotent: it is safe to call twice the same script

- Group similar tasks into a single SLURM job

- Mark dependencies between SLURM jobs
  
## Basic script usage

1. Modify the variables at the beginning of each script
   (*FIXME* factorize out the common configuration into a single file)

2. Run `create_eigs.sh`, `create_props.sh` ... to create jobs

3. Run `create_eigs_launch.sh`, `create_props_launch.sh` ...
   to submit jobs that haven't been submitted already

4. Run `create_eigs_check.sh`, `create_props_check.sh` ...
   to remove the submitted mark on unsuccessfully finished jobs


