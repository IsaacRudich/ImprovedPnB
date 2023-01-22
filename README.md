# Improved Peel-and-Bound
This repository contains the code used to perform comparisons of the peel-and-bound method and the branch-and-bound method. Details about both algorithms and their implementations can be found in the paper: *Improved Peel-and-Bound: Methods for Generating Dual Bounds with Multivalued Decision Diagrams*

## Getting ready to use this repository
1. Install Julia by following the instructions [here](https://julialang.org/downloads/). In theory any up-to-date version of Julia should work, but if not, reverting to v1.6.1 will fix any deprecation issues.
2. Clone this repository by following the instructions [here](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository)
3. Open the terminal on a Mac or the command shell on a Windows. Navigate to the cloned repository and then into the *src* folder. If you are not sure how to navigate within the temrinal/shell I suggest using a search engine with the phrase *"navigating folders in terminal/shell"*. I am refraining from linking a specific article in case it is removed or edited. 
4. Type `julia` and hit *Enter* to start the julia REPL. It should look like this after a few seconds:<img width="781" alt="Image1" src="https://user-images.githubusercontent.com/65783146/160921840-4259962b-21c4-4a29-8447-532b5112dde8.png">

5. Type `include("PeelAndBound.jl")` into the REPL and hit *Enter*. This will load the code.

## Using this repository
Now that the REPL is running and the code is loaded, there are a few methods available to you. All of the benchmark SOP problems from [TSPLIB](http://comopt.ifi.uni-heidelberg.de/software/TSPLIB95/sop/)  and TSPTW and Makespan problems from [this](https://lopez-ibanez.eu/tsptw-instances) library, are already loaded for you. To run them you will need to use the and `solve_sop` and `solve_tsptw` functions. The parameters available are detailed below. Please be aware that if you turn on parallel processing you must start Julia with parallel threads [see here](https://docs.julialang.org/en/v1/manual/multi-threading/). Take note that every time this runs, it starts by solving a small problem to make sure the code has compiled. The results of this run are not saved, only written to the terminal. There are similar functions for 

### Required Parameter Only for `solve_tsptw`
* `makespan` If this value is `true` then the solver will model the makespan variant of the problem, and if it is `false` it will model the TSPTW variant of the problem. 

### Optional Parameters Only for `solve_tsptw`
* `set` must be an integer. This determines which benchmark set to pull from. There are 7: {1=>AFG, 2=>GendreauDumas, 3=>Langevin, 4=>OhlmannThomas, 5=>SolomonPesant, 6=>SolomonPotvinBengio, 7=>Dumas}. The default is 1.
* `num` must be an integer. This determines which instance from the benchmark set to pull. It will pull the instance whose file name is at that index in alphabetical order according to Julia. There are too many to list but for each set the number of files (and hence the max valid input) is {1=>50, 2=>130, 3=>70, 4=>25, 5=>27, 6=>30, 7=>135}. The default is 1.

### Optional Parameters Only for `solve_sop`
* `num` must be an integer. This determines which instance from the benchmark set to pull. There are 41 available, and the options are listed at the bottom of this documentation.

### Optional Parameters for Both Functions
* `max_width` must be an integer. This determines the maximum width decision diagram constructed while the solver is working. A minimum of 2 is required. The default is 128 (which is very small).
* `widthofsearch` must be an integer. This determines the width of the diversified search used at the beginning of the run. The default is 100 (which is very large).
* `peel_setting` must be either `frontier`, `lastexactnode`, or `maximal`. The default is `maximal`, changing it will change the way nodes are selected during peel-and-bound. The differences are discussed in the paper, and will not be repreated here. 
* `run_parallel` If this is `true`, and Julia has been correctly started with multiple threads [see here](https://docs.julialang.org/en/v1/manual/multi-threading/), then parallel processing will be used to speed up the solver. The default is `false`.
* `file_name` must be a string (surrounded by quotation marks) or `nothing`. This determines the location of the output file, or tells the solver not to make one if it is `nothing` (the solver will still print the results to the terminal). The default is `nothing`.
* `time_limit` must be an integer or `nothing`. This determines how long each problem is allowed to run for in seconds, or tells the solver not to use a time limit if it is `nothing`. The default is `nothing`.
* `bestknownvalue` must be a number or `nothing`. If this is a number, the solver will skip the initial search for feasible solutions, and will use the vallue as a trimming heuristic when improving relaxed bounds. 


A command using all of the optional parameters may look like this:
`solve_tsptw(false,set=7,num=135,max_width=2048, widthofsearch=5,peel_setting=maximal, run_parallel=false, file_name="./example.txt", time_limit=1800,bestknownvalue=100000)`

If you want to get under the hood and play around with the solver more directy, you will find the setup code for TSPTW and SOP in the `user_files` folder. All of the code specific to those problems is located there. The generic code for the solver is in the `solver` folder. The frameworks for modeling DD nodes and problems are in the `model` folder. All of the code for the solver is self-documenting. That means that after loading the code you can call the julia help function on any function and see the documentation for it without having to go to it directly. 


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

