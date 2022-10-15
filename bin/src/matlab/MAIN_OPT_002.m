clc; clear all;

Prob = cealmobj;

Prob.fobj  = 'example002';
Prob.title = 'G7';
Prob.lb     = -10 * ones(10,1);
Prob.ub     = 10 * ones(10,1);
Prob.max_gen = 500;
Prob.Tol     = 0.000001;
Prob.Deci_Gen = 10;

Prob.numoffspring_X = 100;
Prob.numparent_X    = 10;
Prob.numoffspring_Y = 100;
Prob.numparent_Y    = 10;

Prob.game_strategy = 1;
Prob

nrun = 5;
for i_run = 1: nrun
    tic
    sol = cealm_solver(Prob);
    % cealm_solver
    toc
    disp(sol);
end