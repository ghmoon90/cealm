function [sol ]= cealm_solver( cealmobj_ )
%     cealmobj_ = Prob;
    % input parsing 
    max_gen        = cealmobj_.max_gen;
    ub             = cealmobj_.ub;
    lb             = cealmobj_.lb;
    fobj           = cealmobj_.fobj;
    Deci_Gen       = cealmobj_.Deci_Gen;
	numoffspring_X = cealmobj_.numoffspring_X;
	numparent_X    = cealmobj_.numparent_X;
	numoffspring_Y = cealmobj_.numoffspring_Y;
	numparent_Y    = cealmobj_.numparent_Y;
    game_strategy  = cealmobj_.game_strategy;
    rho            = cealmobj_.rho_val;
    Tol            = cealmobj_.Tol;
    Temp_X         = cealmobj_.Temp_X;
    Temp_X_f       = cealmobj_.Temp_X_f;
    Temp_Y         = cealmobj_.Temp_Y;
    Temp_Y_f       = cealmobj_.Temp_Y_f;
    % solver initialization 
    

    gencount     = 0;
    
    dimX        = length(ub);
    rng('default');
    rng('shuffle');
    
    x_Temp 		= .5*(ub + lb );
    [ J, C, Ceq ] 	= feval(fobj,x_Temp);

    numineqcnst 	= length(C);
    numeqcnst       = length(Ceq);
    dimY            = numineqcnst+numeqcnst;

    % .. initial boundary of Largrange Mulitpiler 
    ub_Y            = zeros(dimY, 1 );
    lb_Y            = zeros(dimY, 1 );

    if(numineqcnst ~= 0 ) 
        for kk = 1 : numineqcnst 
            ub_Y(kk) 	= 	10;
            lb_Y(kk) 	= 	0;
        end

    end
    if(numeqcnst  ~= 0 ) 
        for kk = 1:numeqcnst 
            ub_Y(numineqcnst+kk) = 10;
            lb_Y(numineqcnst+kk) = -10;
        end 
    end
    
    intervalX = ub - lb;
    intervalY = ub_Y - lb_Y;

    nX_nY 		= dimX + dimY;
    taupX       = 1 / sqrt( 2 * nX_nY  );
    tauX 		= 1 / sqrt( 2 * sqrt(nX_nY));

    taupY       = 1 / sqrt( 2 * nX_nY  );
    tauY 		= 1 / sqrt( 2 * sqrt(nX_nY));

    if Temp_X == 0 
        Temp_X 		= 0.2;
        Temp_X_f 	= 0.1E-12;
    
    end
    
    if Temp_Y == 0
        Temp_Y      = 0.2;
        Temp_Y_f 	= 0.1E-12;
    end
    
    % .. inital parent distribution 
    parent_sdv_X 	= 	intervalX * ones( 1 , numparent_X) ;
    parent_X 	= 	parent_sdv_X .* rand(dimX, numparent_X )  + lb * ones(1,numparent_X);

    parent_sdv_Y 	= 	intervalY * ones( 1 , numparent_Y);
    parent_Y 	= 	parent_sdv_Y .* rand(dimY, numparent_Y ) + lb_Y * ones(1,numparent_Y);

%     if dimX > 1
%         parent_cov_X  	= 	rand( .5 * dimX* (dimX-1) , numparent_X);
%     else
%         parent_cov_X  	= 	zeros( 1  , numparent_X) ;
%     end
% 
% 
%     if dimY > 1
%         parent_cov_Y  	= 	rand( .5 * dimY* (dimY-1) ,numparent_Y);
%     else
%         parent_cov_Y 	= 	zeros( 1  , numparent_Y ) ;
%     end

    alpha 	= 	10^(-1/Deci_Gen );
    beta    = 0.02;
    
    sdv_X_lb  = zeros( dimX , 1 );
    sdv_Y_lb  = zeros( dimY , 1 );
    sdv_X_ub  = Temp_X .* intervalX;
    sdv_Y_ub  = Temp_Y .* intervalY;
    elite_val = 10E12;
    elite_X   = zeros( dimX , 1 );
    elite_Y   = zeros( dimY , 1 );
    Mu        = zeros( numineqcnst , 1 );
    lambda    = zeros( numeqcnst , 1 );
    
    
    Game_    =  zeros(numoffspring_X,numoffspring_Y);
    score_X= zeros( 1 , numoffspring_X);
    score_Y= zeros( 1 , numoffspring_Y );
    status = 'not found';
    
    % optimization loop
        
    
    while( gencount < max_gen )
        
        %%%%%%%%%%%%%%%%%%%%%%%%
        % recombination
       
%         tic 
        ID_SX 	= randi([1 , numparent_X] , 1 ,numoffspring_X  );
        ID_TX 	= randi([1 , numparent_X] , 1 ,numoffspring_X  );
        ID_SY 	= randi([1 , numparent_Y] , 1 ,numoffspring_Y  );
        ID_TY 	= randi([1 , numparent_Y] , 1 ,numoffspring_Y  );
        
        offspring_X = parent_X( : , ID_SX );
        offspring_Y = parent_Y( : , ID_SY ); 

        offspring_sdv_X  = .5 * ( parent_sdv_X( : , ID_SX ) + parent_sdv_X( : , ID_TX ) ) ;
        offspring_sdv_Y  = .5 * ( parent_sdv_Y( : , ID_SY ) + parent_sdv_Y( : , ID_TY ) ) ;

%         offspring_cov_X  = .5 * ( parent_cov_X(: , ID_SX )+ parent_cov_X(: , ID_TX )); 
%         offspring_cov_Y  = .5 * ( parent_cov_Y(: , ID_SY )+ parent_cov_Y(: , ID_TY )); 
        

        offspring_sdv_X   = offspring_sdv_X .* exp( ones(dimX,1) * taupX * randn( 1 , numoffspring_X) + tauX * randn( dimX , numoffspring_X ) );			
        offspring_sdv_Y   = offspring_sdv_Y .* exp( ones(dimY,1) * taupY * randn( 1 , numoffspring_Y) + tauY * randn( dimY , numoffspring_Y ) );
        
        %%%%%%%%%%%%%%%%%%%%
        % annealing
        if Temp_X > Temp_X_f
            Temp_X = alpha	* Temp_X ;
        else
            Temp_X = Temp_X_f;
        end
                   
        sdv_X_lb = Temp_X .* (intervalX);
        
        if Temp_Y > Temp_Y_f
            Temp_Y = alpha	* Temp_X ;
        else
            Temp_Y = Temp_Y_f;
        end

        sdv_Y_lb = Temp_Y.* intervalY;
%         toc
			
%         tic
        %%%%%%%%%%%%%%%%%%%%%%%%
        % mutation 
        for ii  = 1 : numoffspring_X

            Sigma_X = zeros( dimX , dimX );
% 
%             if dimX > 1
% 
%                 id_cov  	= 	0;
% 
%                 for i_row  =  1 : dimX 
% 
%                     for j_col = i_row + 1 : dimX
% 
%                         id_cov = id_cov + 1 ;
%                         offspring_cov_X ( id_cov , i ) = offspring_cov_X ( id_cov , i ) + beta * randn;
%                         Sigma_X( i_row , j_col ) = offspring_cov_X ( id_cov , i ) ; 
%                         Sigma_X( j_col , i_row ) = Sigma_X( i_row , j_col ) ;
% 
% 
%                     end
%                 end
%             end
                
            for i_dim = 1 : dimX 
               if  offspring_sdv_X ( i_dim , ii ) < 	sdv_X_lb(i_dim) 
                   offspring_sdv_X ( i_dim , ii ) = sdv_X_lb(i_dim) ;
               elseif  offspring_sdv_X ( i_dim , ii ) > 	sdv_X_ub(i_dim) 
                   offspring_sdv_X ( i_dim , ii ) = sdv_X_ub(i_dim) ;
               end
            end
			
            Sigma_X 	= offspring_sdv_X ( : , ii ) ;  %+ Sigma_X ;  
            offspring_X(:,ii) = offspring_X(:,ii) + Sigma_X  .* randn( dimX , 1 );

			% when offspring occurs out of boundary, simply reset by uniform distribution 
            ub_wall = ( offspring_X(:,ii) - ub  );
            lb_wall =  ( lb -  offspring_X(:,ii)  );

            for i_dim= 1 : dimX 
                if ub_wall( i_dim ) >=0
                    sdv                       = min( intervalX( i_dim ) , ub_wall(i_dim) );
                    offspring_X(i_dim,ii) = -rand * sdv + ub( i_dim )   ; 
                elseif lb_wall( i_dim ) >=0
                    sdv                       = min( intervalX( i_dim ) , lb_wall(i_dim) );
                    offspring_X(i_dim,ii) = rand * sdv + lb( i_dim )   ; 
                end
            end
            
            
        end
        
        

        for jj = 1 : numoffspring_Y

            Sigma_Y = zeros( dimY , dimY );
% 
%             if dimY > 1
% 
%                 id_cov  	= 	0;
% 
%                 for i_row  =  1 : dimY 
% 
%                     for j_col = i_row + 1 : dimY
% 
%                         id_cov = id_cov + 1; 
%                         offspring_cov_Y ( id_cov , i ) = offspring_cov_Y ( id_cov , i ) + beta * randn; 
%                         Sigma_Y( i_row , j_col ) = offspring_cov_Y ( id_cov , i ) + beta * randn; 
%                         Sigma_Y( j_col , i_row ) = Sigma_Y( i_row , j_col ) ;
% 
% 
%                     end
%                 end
%             end

            for i_dim = 1 : dimY 
               if  offspring_sdv_Y ( i_dim , jj ) < 	sdv_Y_lb(i_dim) 
                   offspring_sdv_Y ( i_dim , jj ) = sdv_Y_lb(i_dim) ;
               elseif  offspring_sdv_Y ( i_dim , jj ) > 	sdv_Y_ub(i_dim) 
                   offspring_sdv_Y ( i_dim , jj ) = sdv_Y_ub(i_dim) ;
               end
            end

            Sigma_Y  =offspring_sdv_Y ( : , jj ) ; %+ Sigma_Y ;
            offspring_Y(:,jj) = offspring_Y(:,jj) + Sigma_Y  .* randn( dimY , 1 );

            % when offspring occurs out of boundary, simply reset by uniform distribution 
            ub_wall = ( offspring_Y(:,jj) - ub_Y  );
            lb_wall =  ( lb_Y -  offspring_Y(:,jj)  );

            for i_dim= 1 : dimY 
% %                 if ub_wall( i_dim ) >0
% %                     sdv                       = min(intervalY( i_dim ) , ub_wall(i_dim) );
% %                     offspring_Y(i_dim,j_offspringY) = -rand * sdv + ub_Y( i_dim )   ; 
% %                 elseif
                if lb_wall( i_dim ) >=0
                    sdv                       = min( intervalY( i_dim ) , lb_wall(i_dim) );
                    offspring_Y(i_dim,jj) = rand * sdv + lb_Y( i_dim )   ; 
                end
            end
        end
%         toc
        
%         tic
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % cost evaluation 
%         Game = zeros(numoffspring_X, numoffspring_Y);
%  
        for ii = 1 : numoffspring_X 
            x_i = offspring_X(:,ii); 
            [f , g , h] = feval(fobj, x_i );
            for jj = 1 : numoffspring_Y

%                 Mu 	= offspring_Y(1:numineqcnst,jj);
%                 lambda = offspring_Y(numineqcnst+1 : end,jj);
                ALM_ineq = 0;

                for kk = 1 : numineqcnst
                    Mu_kk = offspring_Y(kk,jj);
             
                    if ( g(kk) * rho * 2 + Mu_kk >= 0 ) 
                        temp = ( Mu_kk * g(kk) + rho * g(kk) ^2 ) ;
                    else
                        temp = - Mu_kk^2 /4 / rho ; 
                    end
                    ALM_ineq = ALM_ineq+temp ;

                end

                if isempty( h )
                  Game_(ii,jj) = f+ALM_ineq ;

                else 
                    ALM_eq = 0;
                    for qq = 1 : numeqcnst 
                       lambda_qq = offspring_Y(qq ,jj);
                       ALM_eq = h(qq) * lambda_qq + rho * lambda_qq^2; 
                    end
                    
                   Game_(ii,jj) = f+ALM_ineq  + ALM_eq ;
                end



            end
        end 
        
        
%         Game= zeros(numoffspring_X ,numoffspring_Y);
%         h = [];
%         offspring_Y_ = offspring_Y';
%         offspring_X_ = offspring_X';
% tic
%         for ii = 1 : numoffspring_X
%            x_i = offspring_X(:,ii);
%            [f, g, h] = feval(fobj,x_i);
% %              [f, g] = feval(fobj,x_i);
%              
%         
% 
%            for jj = 1 : numoffspring_Y
%                 AL1 = 0;
%                 AL2 = 0;
%                 AL3 = 0;
% %                 Mu 	= offspring_Y(1:numineqcnst,j_offspringY);
% %                 lambda = offspring_Y(numineqcnst+1 : end,j_offspringY);
%                 
%                 if(numineqcnst ~= 0)
% %                     Mu(:,1) 	= offspring_Y(1:numineqcnst,jj);
%                     for k=1:numineqcnst
%                        AL1 = AL1 + (max(g(k)+0.5*offspring_Y(k,jj)/rho, 0))^2;
%                        AL2 = AL2 + offspring_Y(k,jj)^2;
%                     end
%                     AL1 = rho*AL1;
%                     AL2 = - 0.25*AL2/rho; 
%                 end
%                 if(numeqcnst ~= 0)
% %                     lambda(:,1) = offspring_Y(numineqcnst+1 : end,jj);
%                     for k=1:numeqcnst
%                        AL3 = AL3 + offspring_Y(numineqcnst+k,jj)*h(k) + rho*offspring_Y(numineqcnst+k,jj)^2;  
%                     end
%                 end
%                 ALV = f + AL1 + AL2 + AL3;
%                 Game_(ii, jj) = ALV;
%            end
%            
%         end
%         toc
        
        
        
%         tic
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % finess evaluation 

        switch game_strategy

            case 1 % 1. X:securtiy Y:security 

                for ii = 1: numoffspring_X	
                    score_X(ii) =    max(Game_(ii, :));
                end

                for jj = 1: numoffspring_Y	
                    score_Y(jj) =     min(Game_(:, jj));
                end
                
                        
                [sorted_score_X , sorted_index_X] = sort(score_X,'ascend');
                [sorted_score_Y , sorted_index_Y] = sort(score_Y,'descend');
                [BestCost, BestParamIndex ] = min(score_X);

            case 2 % 2. X:man to man Y:security 


                for jj = 1: numoffspring_Y	
                    score_Y(jj) =     min(Game_(:, jj));
                end
                
            case 3 % Greedy 
                
                for ii = 1: numoffspring_X	
                    score_X(ii) =    min(Game_(ii, :));
                end

                for jj = 1: numoffspring_Y	
                    score_Y(jj) =    max(Game_(:, jj));
                end   
                
                        
                [sorted_score_X , sorted_index_X] = sort(score_X,'ascend');
                [sorted_score_Y , sorted_index_Y] = sort(score_Y,'descend');
                [BestCost, BestParamIndex ] = min(score_X);
        end

%         toc
        %%%%%%%%%%%%%%%%%%%%%%%
        % selection 

        parent_X       =   offspring_X(:, sorted_index_X(1:numparent_X));
        parent_Y       =   offspring_Y(:, sorted_index_Y(1:numparent_Y));
        parent_sdv_X   =   offspring_sdv_X(:, sorted_index_X(1:numparent_X));
        parent_sdv_Y   =   offspring_sdv_Y(:, sorted_index_Y(1:numparent_Y));   


        elite_candi = offspring_X(: , BestParamIndex );
        is_C = 0;
        is_Ceq = 0;
        isimproved = 0;
        [f, C, Ceq] = feval(fobj, elite_candi);
        if all ( C - Tol < 0 )  
            is_C = 1;
        end

        if isempty( Ceq )
           is_Ceq = 1; 
        elseif all ( (Ceq).^2 - Tol < 0.0 )
           is_Ceq  =1;
        end
        
        if elite_val > f
            isimproved = 1 ;
        end

        if is_C && is_Ceq && isimproved 
            status = 'found';
            elite_val = f;
            elite_X = elite_candi; 
            elite_Y = parent_Y(: , 1);
        end
        
        
        gencount = gencount + 1;
        
    end
    
    
%     cealmobj_.gencount = gencount      ;
%     cealmobj_.elite_val = elite_val;
%     cealmobj_.elite_X = elite_X;
% 
%     cealmobj_.elite_Y = elite_Y;
%     

    sol.cost = elite_val;
    sol.X = elite_X;
    sol.Y = elite_Y;
    sol.status = status;
    
% end

% function initsolver( fobj, ub, lb )
% 
% 
% end
% 
% function alm= ALM( f, C, Ceq, mu, rho ) 
% 
%     if 
%     alm = f + 
%     
%     
% 
% end