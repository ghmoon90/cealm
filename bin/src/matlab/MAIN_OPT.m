Prob = CEALM 

Prob.fobj  = 'example001';
self.title = 'example001_test';
Prob.lb     = zeros(13,1);
Prob.ub     = ones(13,1);
Prob.ub(10:12) = [100; 100; 100]; 
Prob.max_gen = 500

Prob.numoffspring_X = 30;
Prob.numparent_X = 5;
Prob.numoffspring_Y = 30;
Prob.numparent_Y = 5;


Prob = Prob.initOPT();
Prob = Prob.run();

% 
% while(Prob.count_gen < Prob.max_gen)
%     Prob = Prob.recombination();
%     Prob = Prob.mutation();
%     Game = Prob.ALM();
%     [score_X  , score_Y] = Prob.fitness( Game );
%     [sorted_score_X , sorted_index_X] = sort(score_X);
%     [sorted_score_Y , sorted_index_Y] = sort(score_Y);
%     Prob.parent_X   =   Prob.offspring_X(:, sorted_index_X(1:Prob.numparent_X));
%     Prob.parent_Y   =   Prob.offspring_Y(:, sorted_index_Y(1:Prob.numparent_Y));
%     Prob.count_gen  = Prob.count_gen  +1;
% 
% end

%%
f_parent    =   zeros(1, Prob.numparent_X);
C_parent    =   zeros(Prob.numineqcnst, Prob.numparent_X);
Ceq_parent  =   zeros(Prob.numeqcnst, Prob.numparent_X);
for i = 1 : Prob.numparent_X
   
    [f , C , Ceq]  =   feval(Prob.fobj,Prob.parent_X(:,i));
    f_parent(i)    =   f;
    C_parent(:,i)    =   C;
    Ceq_parent(:,i)  =   Ceq;
    
end