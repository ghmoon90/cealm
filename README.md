# CEALM
coevolutionary augmented Lagrangian method is designed by Prof. Tahk, Min-Jea, KAIST (Korea Advanced Instutute of Science and Technology). 
He started his carrer at ADD(Agency for defense development, Korea), and dedicated for professor of aerospace engineering department at KAIST form 1998, and retired in 2019.

CEALM is kind of meta heuristic global optimization algorithm. It solves a dual problem of constrainied nonlinear optimization problem using augmented Lagrangian method (ALM). By ALM the dual problem is convex, so the duality gap vanishs. 
CEALM utilizes two groups of player, Group X for the state, and the other Group Y for the co-state. Each group evolve seperately. Goal of group X is to minimize the augmented cost function $f_a(x)$ , while Goal of group Y is to maximize $f_a(x)$.

# Programing Lanugage
The cealm solver is designed to operate on following languages
- matlab 
- python3
- C++ 

# Background 
## Problem definition 

<img src="https://render.githubusercontent.com/render/math?math=min J = f(x)">
subject to 

<img src="https://render.githubusercontent.com/render/math?math=g(x)<0">
<img src="https://render.githubusercontent.com/render/math?math=h(x) = 0">
<img src="https://render.githubusercontent.com/render/math?math=lb < x < ub">

## Dual Problem 


## Augmented Largrangian Method 

## Game Theory - Nash Equalibrium


## Evolutionary Strategy 


# Algorithm 
## Overview 


## 


# Reference 
[1] Min-Jea Tahk and Byung-Chan Sun, "Coevolutionary augmented Lagrangian methods for constrained optimization," in IEEE Transactions on Evolutionary Computation, vol. 4, no. 2, pp. 114-124, July 2000, doi: 10.1109/4235.850652.
