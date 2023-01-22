# Peel-and-Bound
This repository contains the code used to perform comparisons of the peel-and-bound method and the branch-and-bound method. Details about both algorithms and their implementations can be found in the paper: *Peel-and-Bound: Generating Stronger Relaxed Bounds with Multivalued Decision Diagrams*

## Getting ready to use this repository
1. Install Julia by following the instructions [here](https://julialang.org/downloads/). In theory any up-to-date version of Julia should work, but if not, reverting to v1.6.1 will fix any deprecation issues.
2. Clone this repository by following the instructions [here](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository)
3. Open the terminal on a Mac or the command shell on a Windows. Navigate to the cloned repository and then into the *src* folder. If you are not sure how to navigate within the temrinal/shell I suggest using a search engine with the phrase *"navigating folders in terminal/shell"*. I am refraining from linking a specific article in case it is removed or edited. 
4. Type `julia` and hit *Enter* to start the julia REPL. It should look like this after a few seconds:<img width="781" alt="Image1" src="https://user-images.githubusercontent.com/65783146/160921840-4259962b-21c4-4a29-8447-532b5112dde8.png">

5. Type `include("DDForDP,jl")` into the REPL and hit *Enter*. This will load the code.
6. Once the code is loaded it needs to be compiled. To test that the code is working, and compile it in the process, type `solveSOPPeel(8,64, loggingOn=true)` into the REPL and hit *Enter*. After the code is done running, it should have found an optimal solution with a cost of 55. The time and specific solution may vary from computer to computer.<img width="855" alt="Image2" src="https://user-images.githubusercontent.com/65783146/160921880-c86f7060-3e02-481e-baaa-8e7b9d44c9ec.png">


## Using this repository
Now that the REPL is running and the code is compiled, there are a few methods available to you. All of the benchmark SOP problems from [TSPLIB](http://comopt.ifi.uni-heidelberg.de/software/TSPLIB95/sop/) are already loaded for you. The only function you need to be familiar with is `benchmarkSOPs()`, but there are several options that can be adjusted. Take note that every time `benchmarkSOPs()` runs, it starts by solving a small problem to make sure the code has compiled. The results of this run are not saved, only written to the terminal.

### Required Parameters.
* `width` must be the first input value and it must be an integer. This determines the maximum width decision diagram constructed while the solver is working. A minimum of 2 is required.
* `fileName` must be the second input value and it must be a string (surrounded by quotation marks). This determines the location of the output file.
* `timeLimit` must be the third input value and it must be an integer. This determines how long each problem is allowed to run for in seconds. 

For example, running `benchmarkSOPs(64,"outputFiles/peel_64.txt", 60)` will run the solver on all of the benchmark problems for a maximum of 60 seconds, with a maximum decision diagram width of 64, create a file in the *outputFiles* folder called *peel_64*, and write all of the results to that file. 

### Optional Parameters
The first two optional parameters select the problems to run. Each benchmark problem has an assigned index; the indices are listed in the table at the bottom of this document.

* `numStart` must be a valid index and determines the first problem to solve. The default value is `1`.
* `numEnd` must be a valid index greater than `numStart` and determines the last problem to solve. The default value is `41`. 

For example, running `benchmarkSOPs(64,"outputFiles/peel_64.txt", 60, numStart=8,numEnd=9)` will limit the solver so it only runs problems br17.10 and br17.12.

* `usePeel` must be either `true` or `false`. If true, the solver will use peel-and-bound. If false, the solver will use branch-and-bound. The default value is `true`.
* `peelSetting` must be either `peellen` or `peelf`. The default is `peellen`, changing it to `peelf` will change the way nodes are selected during peel-and-bound to the *frontier method* from the *last exact node* method. The difference is discussed in the paper, and will not be repreated here. 

A command using all of the optional parameters may look like this:

`benchmarkSOPs(64, "example.txt", 60;numStart=3,numEnd=3,usePeel=false, peelSetting=peelf)`



| Index | Problem Name |
| ------------- | ------------- |
| 1  | ESC07 |
| 2  | ESC11 |
| 3  | ESC12 |
| 4  | ESC25 |
| 5  | ESC47 |
| 6  | ESC63 |
| 7  | ESC78 |
| 8 | br17.10 |
| 9 | br17.12 |
| 10 | ft53.1 |
| 11 | ft53.2 |
| 12 | ft53.3 |
| 13 | ft53.4 |
| 14 | ft70.1 |
| 15 | ft70.2 |
| 16 | ft70.3 |
| 17 | ft70.4 |
| 18 | kro124p.1 |
| 19 | kro124p.2 |
| 20 | kro124p.3 |
| 21 | kro124p.4 |
| 22 | p43.1 |
| 23 | p43.2 |
| 24 | p43.3 |
| 25 | p43.4 |
| 26 | prob.42 |
| 27 | prob.100 |
| 28 | rbg048a |
| 29 | rbg050c |
| 30 | rbg109a |
| 31 | rbg150a |
| 32 | rbg174a |
| 33 | rbg253a |
| 34 | rbg323a |
| 35 | rbg341a |
| 36 | rbg358a |
| 37 | rbg378a |
| 38 | ry48p.1 |
| 39 | ry48p.2 |
| 40 | ry48p.3 |
| 41 | ry48p.4 |

