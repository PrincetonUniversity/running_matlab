# Running MATLAB on the HPC Clusters

This guide presents an overview of running MATLAB on the HPC clusters at Princeton.

## Run MATLAB in Your Web Browser

If you are new to high-performance computing then you will find that the simplest way to use MATLAB on the HPC clusters is through the Open OnDemand web interface. If you have an account on Adroit or Della
then browse to [https://myadroit.princeton.edu](https://myadroit.princeton.edu) or [https://mydella.princeton.edu](https://mydella.princeton.edu). If you need an account on Adroit then complete [this form](https://forms.rc.princeton.edu/registration/?q=adroit). Note that you will need to use a [VPN](https://princeton.service-now.com/snap?id=kb_article&sys_id=ce2a27064f9ca20018ddd48e5210c745) to connect from off-campus.

To begin a session, click on "Interactive Apps" and then "MATLAB". You will need to choose the "MATLAB version", "Number of hours" and "Number of cores". Set "Number of cores" to 1 unless you are sure that your script has been explicitly
parallelized using, for example, the Parallel Computing Toolbox (see below). Click "Launch" and then when your session is ready click "Launch MATLAB". Note that the more resources you request, the more you will have to wait for your session to become available.

![jupyter](https://tigress-web.princeton.edu/~jdh4/matlab_two_frames.png)

## Submitting Batch Jobs to the Slurm Scheduler

Intermediate and advanced MATLAB users prefer submitting jobs to the Slurm scheduler over using the web interface (described above). This applies to Adroit, Della, Perseus and TigerGPU. A job consists of two pieces: (1) a MATLAB script and (2) a Slurm script that specifies the needed resources, sets the environment and lists the commands to be run.

### Running a Serial MATLAB Job

A serial MATLAB job is one that requires only a single CPU-core. Here is an example of a trivial, one-line serial MATLAB script (`hello_world.m`):

```
fprintf('Hello world.\n')
```

The Slurm script (`job.slurm`) below can be used for serial jobs:

```bash
#!/bin/bash
#SBATCH --job-name=matlab        # create a short name for your job
#SBATCH --nodes=1                # node count
#SBATCH --ntasks=1               # total number of tasks across all nodes
#SBATCH --cpus-per-task=1        # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --mem-per-cpu=4G         # memory per cpu-core (4G per cpu-core is default)
#SBATCH --time=00:01:00          # total run time limit (HH:MM:SS)
#SBATCH --mail-type=all          # send email on job start, end and fault
#SBATCH --mail-user=<YourNetID>@princeton.edu

module purge
module load matlab/R2019a

matlab -singleCompThread -nodisplay -nosplash -r hello_world
```

By invoking MATLAB with `-singleCompThread -nodisplay -nosplash`, the the GUI is suppressed as is the creation of multiple threads.

If you are new to cluster computing then consider reading [this explanation](https://oncomputingwell.princeton.edu/2017/03/your-first-slurm-script-to-run-matlab/) of running a serial MATLAB job. To run the MATLAB script, simply submit the job to the cluster with the following command:

```
$ sbatch job.slurm
```

After the job completes, view the output with `cat slurm-*`:

```
...
Hello world.
```

Use `squeue -u $USER` to monitor the progress of queued jobs.

### Choosing a MATLAB version

Run the command below to see the available MATLAB versions. For example, on Della:

```
$ module avail matlab
----------------------------- /usr/licensed/Module s/modulefiles -----------------------------
matlab/R2010a      matlab/R2012a      matlab/R2014b      matlab/R2016b            matlab/R2018b
matlab/R2010b      matlab/R2013a      matlab/R2015a      matlab/R2017a            matlab/R2019a
matlab/R2011a      matlab/R2013b      matlab/R2015b      matlab/R2017b(default)   matlab/R2019b
matlab/R2011b      matlab/R2014a      matlab/R2016a      matlab/R2018a
```

In your Slurm script, you can either take the default version with `module load matlab` or choose a specific version, for example: `module load matlab/R2019b`.

### Running a Multi-threaded MATLAB Job with the Parallel Computing Toolbox

Most of the time, running MATLAB in single-threaded mode (as described above) will meet your needs. However, if your code makes use of the Parallel Computing Toolbox (e.g., `parfor`) or you have intense computations that can benefit from the built-in multi-threading provided by MATLAB's BLAS implementation, then you can run in multi-threaded mode. One can use up to all the CPU-cores on a single node in this mode. **Multi-node jobs are not possible with the version of MATLAB that we have so your Slurm script should always use `#SBATCH --nodes=1`.**

Here is an [example](https://www.mathworks.com/help/parallel-computing/interactively-run-a-loop-in-parallel.html) from MathWorks of using multiple cores (`for_loop.m`):

```matlab
poolobj = parpool;
fprintf('Number of workers: %g\n', poolobj.NumWorkers);

tic
n = 200;
A = 500;
a = zeros(n);
parfor i = 1:n
    a(i) = max(abs(eig(rand(A))));
end
toc
```

The Slurm script (`job.slurm`) below can be used for this case:

```bash
#!/bin/bash
#SBATCH --job-name=parfor        # create a short name for your job
#SBATCH --nodes=1                # node count
#SBATCH --ntasks=1               # total number of tasks across all nodes
#SBATCH --cpus-per-task=4        # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --mem-per-cpu=4G         # memory per cpu-core (4G is default)
#SBATCH --time=00:00:30          # total run time limit (HH:MM:SS)
#SBATCH --mail-type=all          # send email on job start, end and fault
#SBATCH --mail-user=<YourNetID>@princeton.edu

module purge
module load matlab/R2019a

srun matlab -nodisplay -nosplash -r for_loop
```

Note that `-singleCompThread` does not appear in the Slurm script in contrast to the serial case. One must tune the value of `--cpus-per-task` for optimum performance. Use the smallest value that gives you a significant performance boost because the more resources you request the longer your queue time will be.

### How do I know if my MATLAB code is Parallelized?

There are two common ways to answer this question without knowing anything about the code. The first to is run the code using 1 CPU-core and then do a second run using, say, 4 CPU-cores. Look to see if there is a significant difference in the execution time of the two codes. The second method is to launch the job using, say, 4 CPU-cores then `ssh` to the compute node where the job is running and use `htop -u $USER` to inspect the CPU usage. To get the name of the compute node where your jobs is running use the following command:

```
$ squeue -u $USER
```

The rightmost column labeled "NODELIST(REASON)" gives the name of the node where your job is running. SSH to this node, for example:

```
$ ssh della-r3c1n14
```

Once on the compute node, run `htop -u $USER`. If your job is running in parallel you should see a process using much more than 100% in the `%CPU` column. For 4 CPU-cores this number would be ideally be 400%.

## Running MATLAB on Nobel

The Nobel cluster is a shared system without a job scheduler. Because of this, users are not allowed to run MATLAB in multi-threaded mode. The first step in using MATLAB on Nobel is choosing the version. Run `module avail matlab` to see the choices. Load a module with, e.g., `module load matlab/R2019b`.

After loading a MATLAB module, to run MATLAB interactively with its GUI on the script `myscript.m`:

```
$ matlab -singleCompThread -r myscript
```

To run MATLAB without its GUI in command-line mode:

```
$ matlab -singleCompThread -nodisplay -nosplash -r myscript
```

## Using the MATLAB GUI on Tigressdata

In addition to the web interfaces on MyAdroit and MyDella, one can also launch MATLAB with its GUI on Tigressdata. Tigressdata is ideal for data post-processing and visualization. You can access your files on the different filesystems using these paths: `/tiger/scratch/gpfs/<YourNetID>`, `/della/scratch/gpfs/<YourNetID>`, `/perseus/scratch/gpfs/<YourNetID>`, `/tigress` and `/projects`.

Mac users will need to have [XQuartz](https://www.xquartz.org/) installed while Windows users should install [MobaXterm](https://mobaxterm.mobatek.net/download.html) (Home Edition). Visit the [OIT Tech Clinic](https://princeton.service-now.com/snap/?id=kb_article&sys_id=ea2a27064f9ca20018ddd48e5210c771) for assistance with installing, configuring and using these tools.

To run MATLAB interactively with its graphical user interface:

```
$ ssh -X <YourNetID>@tigressdata.princeton.edu
$ module load matlab/R2019a
$ matlab
```

It can take a minute or more for the GUI to appear and for initialization to complete.

To work interactively without the GUI:

```
$ ssh <YourNetID>@tigressdata.princeton.edu
$ module load matlab/R2019a
$ matlab
>>
```

Note that one can use the procedures above on the HPC clusters (e.g., Della) but only for non-intensive work since the head node is shared by all users of the cluster.

## MATLAB is Not Allowed on TigerCPU

TigerCPU is designed for large multi-node parallel jobs. MATLAB cannot be used across multiple nodes so it is not allowed.
If you try to run a MATLAB job on TigerCPU you will encounter the following error message:

```
License checkout failed.
License Manager Error -15
MATLAB is unable to connect to the license server. 
Check that the license manager has been started, and that the MATLAB client machine can communicate
with the license server.

Troubleshoot this issue by visiting: 
https://www.mathworks.com/support/lme/R2018b/15

Diagnostic Information:
Feature: MATLAB 
License path: /home/jdh4/.matlab/R2018b_licenses:/usr/licensed/matlab-R2018b/licenses/license.dat:/usr/licensed/ma
tlab-R2018b/licenses/network.lic 
Licensing error: -15,570. System Error: 115
```

You will need to carry out the work on another cluster such as Della or if your script can be written to use a GPU then you
can use TigerGPU. To get started with MATLAB and GPUs see below.

## MATLAB is Not Available on Traverse

MathWorks does not produce a version of MATLAB that is compatible with the PowerPC architecture of Traverse.

## Running MATLAB on GPUs

Many routines in MATLAB have been written to run on a GPU. Below is a MATLAB script (`svd_matlab.m`) that performs a matrix decomposition using a GPU:

```matlab
gpu = gpuDevice();
fprintf('Using a %s GPU.\n', gpu.Name);
disp(gpuDevice);

X = gpuArray([1 0 2; -1 5 0; 0 3 -9]);
whos X;
[U,S,V] = svd(X)
fprintf('trace(S): %f\n', trace(S))
quit;
```

The Slurm script (`job.slurm`) below can be used for this case:

```bash
#!/bin/bash
#SBATCH --job-name=matlab-svd    # create a short name for your job
#SBATCH --nodes=1                # node count
#SBATCH --ntasks=1               # total number of tasks across all nodes
#SBATCH --cpus-per-task=1        # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --mem-per-cpu=1G         # memory per cpu-core (4G is default)
#SBATCH --time=00:00:30          # total run time limit (HH:MM:SS)
#SBATCH --gres=gpu:1             # number of gpus per node

module purge
module load matlab/R2019a

matlab -singleCompThread -nodisplay -nosplash -r svd_matlab
```

In the above Slurm script, notice the new line: `#SBATCH --gres=gpu:1`. The job can be submitted to the scheduler with:

```
sbatch job.slurm
```

Be sure that your MATLAB code is able to use a GPU before submitting your job to TigerGPU. See this [getting started](https://www.mathworks.com/solutions/gpu-computing/getting-started.html) guide on MATLAB and GPUs.

## MATLAB and Java

MATLAB uses some functionality from Java. To see which implementation of Java it is using:

```
>> version -java
ans = 'Java 1.8.0_181-b13 with Oracle Corporation Java HotSpot(TM) 64-Bit Server VM mixed mode'
```

Additional information can be obtained by running: `javaclasspath()`

To directly import code: `import java.util.ArrayList`

If you are using Java functionality in MATLAB be sure to eliminate `-nojvm` in your Slurm script.

## Where to Store Your Files

You should run your jobs out of `/scratch/gpfs/<NetID>` on the HPC clusters. These filesystems are very fast and provide vast amounts of storage. **Do not run jobs out of `/tigress` or `/projects`. That is, you should never be writing the output of actively running jobs to these filesystems.** `/tigress` and `/projects` are slow and should only be used for backing up the files that you produce on `/scratch/gpfs`. Your `/home` directory on all clusters is small and it should only be used for storing source code and executables.

The commands below give you an idea of how to properly run a MATLAB job:

```bash
$ ssh <NetID>@della.princeton.edu
$ cd /scratch/gpfs/<NetID>
$ mkdir myjob && cd myjob
# put MATLAB script and Slurm script in myjob
$ sbatch job.slurm
```

If the run produces data that you want to backup then copy or move it to `/tigress`:

```
$ cp -r /scratch/gpfs/<NetID>/myjob /tigress/<NetID>
```

For large transfers consider using `rsync` instead of `cp`. Most users only do back-ups to `/tigress` every week or so. While `/scratch/gpfs` is not backed-up, files are never removed. However, important results should be transferred to `/tigress` or `/projects`.

The diagram below gives an overview of the filesystems:

![tigress](https://tigress-web.princeton.edu/~jdh4/hpc_princeton_filesystems.png)

## FAQ

### 1. How to pass arguments to a MATLAB function within a SLURM script?

View the [original post](https://askrc.princeton.edu/question/286/how-to-pass-arguments-to-a-matlab-function-within-a-slurm-script/) by D. Luet.

Let us use the following MATLAB script as a example:

```matlab
function print_values(array, a, b)
array
a
b
```

It simply prints the value of the 3 arguments to the screen. Let us save this MATLAB
function in a file called print_values.m.

Now here is a SLURM script that shows you how to run using a SLURM script that uses a SLURM job array:

```bash
#!/bin/bash
#SBATCH --job-name=matlab        # create a short name for your job
#SBATCH --nodes=1                # node count
#SBATCH --ntasks=1               # total number of tasks across all nodes
#SBATCH --cpus-per-task=1        # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --mem-per-cpu=1G         # memory per cpu-core (4G is default)
#SBATCH --time=00:00:30          # total run time limit (HH:MM:SS)
#SBATCH --array=0-4              # job array with index values 0, 1, 2, 3, 4
#SBATCH -o matlab%a.out          # stdout is redirected to that file
#SBATCH -e matlab%a.err          # stderr is redirected to that file
#SBATCH --mail-type=all
#SBATCH --mail-user=<YourNetID>@princeton.edu

STRING="'I am a string'"
GOLDEN=1.618033988749895

module purge
module load matlab

matlab -nodesktop -nosplash -r "print_values($SLURM_ARRAY_TASK_ID, $STRING, $GOLDEN)"
```

Note that this simple scripts demonstrates how to pass three types of arguments:

1. A string, STRING, note that the double quotes (") are part of the bash syntax and the single quotes ( ' ) are part of the MATLAB syntax.

2. A real number, GOLDEN,

3. A SLURM environment variable, SLURM_ARRAY_TASK_ID, which happens to be an integer.
Assuming that this script is saved in a file called batch.sh, we submit to the scheduler with the command:

The job can be submitted to the scheduler with:

```
sbatch batch.sh
```

Once the script is executed, 8 files should be created in your directory: `matlabN.out` and `matlabN.err` where N=0,...,3 because we asked for a job array of 4 elements.

### 2. Why do my MATLAB jobs using the Parallel Computing Toolbox fail on launch?

I have submitted multiple job where the MATLAB script contains this snippet:

```matlab
if isempty(gcp('nocreate'))
pc = parcluster('local');
parpool(pc,10)
end
```

Some of the jobs finish successfully but others fail with:

Error using parallel.internal.pool.InteractiveClient>iThrowWithCause (line 676) Failed to start pool. Error using parallel.Job/preSubmit (line 581) Unable to read MAT-file $HOME/.matlab/local_cluster_jobs/R2018a/Job376.in.mat. File might be corrupt.

It appears that two jobs are launching simultaneously and attempting to create this .mat file at the same time. How do I avoid this?

D. Luet provided [the original solution](https://askrc.princeton.edu/question/370/matlab-jobs-using-the-parallel-computing-toolbox-fail-on-launch/) to this as:

The solution is to set the output to /tmp. Every job has a private /tmp directory when running so you can redirect this file to there. The code snippet becomes:

```matlab
if isempty(gcp('nocreate'))
  pc = parcluster('local');
  pc.JobStorageLocation = '/tmp/';
  parpool(pc,10)
end
```

### 3. How can I run MATLAB when I don't have internet access?

D. Luet's [original solution](https://askrc.princeton.edu/question/294/offline-matlab/) is to install a local license. Here is how to do it for macOS:

http://www.princeton.edu/software/licenses/software/matlab/R2017a_LocalLicM.xml

For other operating systems, see:

http://www.princeton.edu/software/licenses/software/matlab/

### 4. Why do I get an error about licensing when I try to run MATLAB on TigerCPU?

TigerCPU is reserved for large parallel jobs. MATLAB jobs can only use a single node so they are not allowed to run on TigerCPU. You will either need to run the job on another cluster or if your code can make use of a GPU then TigerGPU can be used.

### 5. I installed MATLAB through the university on my laptop. How do I update the license?

Please see this [SNAP](https://princeton.service-now.com/snap/?id=kb_article&sys_id=7eca80c8db645384249b7b6b8c9619be) page.

## Getting Help

If you encounter any difficulties while running MATLAB on the HPC clusters then please send
an email to <a href="mailto:cses@princeton.edu">cses@princeton.edu</a> or attend
a <a href="https://researchcomputing.princeton.edu/education/help-sessions">help session</a>.
