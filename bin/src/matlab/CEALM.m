classdef CEALM
	% Co-Evolutionary Augmented Largrangian Methods source code 
	% written by G-H Moon.
	% ref M. J. Tahk, and B. C, Sun, Coevolutionary Augmented Largrangian Methods for constrained optimization, IEEE Transaction on evolutionary computation, vol. 4, no. 2, July 2000
	

	properties (Access =public)

		title = []
		fobj = []; % fobj argument [J, C, Ceq]= fobj(x)

		ub = []
		lb = [];

		ub_Y = [];
 		lb_Y  = [];

		dimX 	= [];
 		dimY 	= [];

		numeqcnst 	=  0;
		numineqcnst 	=  0;

		numoffspring_X 	= 100;
		numparent_X 	= 20;
		numoffspring_Y 	= 100;
		numparent_Y 	= 5;

		offspring_X 	= [];
		offspring_Y 	= [];
		parent_X 		= [];
		parent_Y 		= [];
 		rho_param 	= 100;

		max_gen 		= 	1000; % maximum generation
		count_gen 	= 	1;

		elite_val 		= 10E16;
		elite_X 		= [];
		elite_Y 	 	= [];

		parent_sdv_X 	= [];		
		parent_sdv_Y 	= [];
		parent_cov_X 	= [];
		parent_cov_Y 	= [];

		offspring_sdv_X     = [];
		offspring_sdv_Y 	= [];
		offspring_cov_X     = [];
		offspring_cov_Y 	= [];

		taupX 		= 0;
		tauX 		= 0;
		taupY 		= 0;
		tauY 		= 0;
	
		Deci_Gen 	= 300;   % annealing parameter (input)
		alpha 		= 0.02; % annealing parameter automatically updated
		beta 		= 0.01; % covariance mutation std

		Tol 		= 10E-9;
		RelTol 		= 10E-6;

		szlog 		= [];
		seed 		= 1010;
	
		game_strategy 	= 1;
		% 1 X:security Y: security 
		% 2 X:man to man Y : security 
        
        
		Temp_X 	= 0.2
		Temp_X_f 	= 0.1E-12
		Temp_Y 	= 0.2
		Temp_Y_f 	= 0.1E-12
        
        sdv_X_lb = []; % standard deviation lower bound
        sdv_Y_lb = [];
        sdv_X_ub = [];  % standard deviation upper bound
        sdv_Y_ub = [];
        
        intervalX = [];
        intervalY = [];
        

	end

	methods( Access = public ) 

		function self = initOPT (self) 
	
			self.count_gen 	= 1; 
			self.dimX 	= length(self.ub);

			rng(self.seed)

			x_Temp 		= .5*(self.ub + self.lb );
			[ J, C, Ceq ] 	= feval(self.fobj,x_Temp);
			
			self.numineqcnst 	= length(C);
			self.numeqcnst 	= length(Ceq);
			self.dimY 	= self.numineqcnst+self.numeqcnst;

			% .. initial boundary of Largrange Mulitpiler 
			self.ub_Y = zeros(self.dimY, 1 );
			self.lb_Y = zeros(self.dimY, 1 );
			
			if(self.numineqcnst ~= 0 ) 
				for k = 1 : self.numineqcnst 
					self.ub_Y(k) 	= 	100;
					self.lb_Y(k) 	= 	0;
				end

			end
			if(self.numeqcnst  ~= 0 ) 
				for k = 1:self.numeqcnst 
					self.ub_Y(self.numineqcnst+k) = 100;
					self.lb_Y(self.numineqcnst+k) = -100;
				end 
			end

			nX_nY 		= self.dimX + self.dimY;
			self.taupX 	= 1 /sqrt( 2 * nX_nY  );
			self.tauX 		= 1 / sqrt( 2 * sqrt(nX_nY));

			self.taupY 	= 1 /sqrt( 2 * nX_nY  );
			self.tauY 		= 1 / sqrt( 2 * sqrt(nX_nY));

			self.Temp_X 	= 0.2*ones(self.dimX,1);
			self.Temp_X_f 	= 0.1E-12*ones(self.dimX,1);
			self.Temp_Y 	= 0.2*ones(self.dimY,1);
			self.Temp_Y_f 	= 0.1E-12*ones(self.dimY,1);

			% .. inital parent distribution 
			self.parent_sdv_X 	= 	(self.ub - self.lb) * ones( 1 , self.numparent_X) ;
			self.parent_X 	= 	self.parent_sdv_X .* rand(self.dimX, self.numparent_X )  + self.lb * ones(1,self.numparent_X);
			
			self.parent_sdv_Y 	= 	(self.ub_Y - self.lb_Y) * ones( 1 , self.numparent_Y);
			self.parent_Y 	= 	self.parent_sdv_Y  .* rand(self.dimY, self.numparent_Y ) + self.lb_Y * ones(1,self.numparent_Y);
			
			if self.dimX > 1
				self.parent_cov_X  	= 	rand( .5 * self.dimX* (self.dimX-1) , self.numparent_X);
			else
				self.parent_cov_X  	= 	zeros( 1  , self.numparent_X) ;
			end
			
			
			if self.dimY > 1
				self.parent_cov_Y  	= 	rand( .5 * self.dimY* (self.dimY-1) ,self.numparent_Y);
			else
				self.parent_cov_Y 	= 	zeros( 1  , self.numparent_Y ) ;
			end

			self.alpha 	= 	10^(-1/self.Deci_Gen );
            
            self.intervalX = self.ub - self.lb;
            self.intervalY = self.ub_Y - self.lb_Y;
			
		end

		function Game = ALM (self)

			f = 0 ;
			Game = zeros(self.numoffspring_X, self.numoffspring_Y);
			rho = self.rho_param;
            
			for i = 1 : self.numoffspring_X 
				x = self.offspring_X(:,1); 
				[f , g , h] = feval(self.fobj, x );
				for j = 1 : self.numoffspring_Y
                    
					Mu 	= self.offspring_Y(1:self.numineqcnst,i);
					lambda = self.offspring_Y(self.numineqcnst+1 : end,i);
					gk_sum = 0;
                    
					for k = 1 : length(g) 
						if ( g(k) * rho * 2 + Mu(k) >= 0 ) 
							temp = ( Mu(k) * g(k) + rho * g(k) ^2 ) ;
						else
							temp = - Mu(k)^2 /4 / rho ; 
						end
						gk_sum = gk_sum+temp ;

                    end
                    
                    if isempty( h )
                      Game(i,j) = f+gk_sum ;
                       
                    else 
                       Game(i,j) = f+gk_sum + h * lambda + rho * sum( h.^2 );
                    end



				end
			end 	

		end

		function self = recombination(self)
			% recombination 

			ID_SX 	= randi([1 , self.numparent_X] , 1 ,self.numoffspring_X  );
			ID_TX 	= randi([1 , self.numparent_X] , 1 ,self.numoffspring_X  );
			ID_SY 	= randi([1 , self.numparent_Y] , 1 ,self.numoffspring_Y  );
			ID_TY 	= randi([1 , self.numparent_Y] , 1 ,self.numoffspring_Y  );


			self.offspring_sdv_X  = .5 * ( self.parent_sdv_X( : , ID_SX ) + self.parent_sdv_X( : , ID_TX ) ) ;
			self.offspring_sdv_Y  = .5 * ( self.parent_sdv_Y( : , ID_SY ) + self.parent_sdv_Y( : , ID_TY ) ) ;

			self.offspring_X = self.parent_X( : , ID_SX );
			self.offspring_Y = self.parent_Y( : , ID_SY ); 
				
			self.offspring_cov_X  = .5 * ( self.parent_cov_X(: , ID_SX )+ self.parent_cov_X(: , ID_TX )); 
			self.offspring_cov_Y  = .5 * ( self.parent_cov_Y(: , ID_SY )+ self.parent_cov_Y(: , ID_TY )); 

		end

		function self = mutation(self)
			% mutation  and annealing feature 

			self.offspring_sdv_X   = self.offspring_sdv_X .* exp( self.taupX  * randn( self.dimX , self.numoffspring_X  ) + self.tauX* randn );			
			self.offspring_sdv_Y   = self.offspring_sdv_Y .* exp( self.taupY * randn( self.dimY , self.numoffspring_Y ) + self.tauY  * randn );
			
			% annealing
			for i_dim = 1 : self.dimX 
				if self.Temp_X(i_dim) > self.Temp_X_f(i_dim)
					self.Temp_X(i_dim) = self.alpha	* self.Temp_X(i_dim) ;
				else
					self.Temp_X(i_dim) = self.Temp_X_f(i_dim);
				end
 				self.sdv_X_lb(i_dim) = self.Temp_X(i_dim) * (self.intervalX(i_dim));
			end

			for i_dim = 1 : self.dimY 
				if self.Temp_Y(i_dim) > self.Temp_Y_f(i_dim)
					self.Temp_Y(i_dim) = self.alpha	* self.Temp_X(i_dim) ;
				else
					self.Temp_Y(i_dim) = self.Temp_Y_f(i_dim);
				end
 				self.sdv_Y_lb(i_dim) = self.Temp_Y(i_dim) * (self.intervalY(i_dim));
			end

			

			% mutation 
			for i  = 1 : self.numoffspring_X
				
				Sigma_X = zeros( self.dimX , self.dimX );
			
				if self.dimX > 1

					id_cov  	= 	0;
			
					for i_row  =  1 : self.dimX 
	
						for j_col = i_row + 1 : self.dimX
						
							id_cov = id_cov + 1 ;
                            self.offspring_cov_X ( id_cov , i ) = self.offspring_cov_X ( id_cov , i ) + self.beta * randn;
							Sigma_X( i_row , j_col ) = self.offspring_cov_X ( id_cov , i ) ; 
							Sigma_X( j_col , i_row ) = Sigma_X( i_row , j_col ) ;
											

						end
					end
                end
                
                for i_dim = 1 : self.dimX 
                   if  self.offspring_sdv_X ( i_dim , i ) < 	self.sdv_X_lb(i_dim) 
                       self.offspring_sdv_X ( i_dim , i ) = self.sdv_X_lb(i_dim) ;
                   elseif  self.offspring_sdv_X ( i_dim , i ) > 	self.intervalX(i_dim) 
                       self.offspring_sdv_X ( i_dim , i ) = self.intervalX(i_dim) ;
                   end
                end
			
				Sigma_X 	= diag( self.offspring_sdv_X ( : , i ) );  %+ Sigma_X ;  
				self.offspring_X(:,i) = self.offspring_X(:,i) + Sigma_X  * randn( self.dimX , 1 );

				% when offspring occurs out of boundary, simply reset by uniform distribution 
				ub_wall = ( self.offspring_X(:,i) - self.ub  );
				lb_wall =  ( self.lb -  self.offspring_X(:,i)  );

				for i_dim= 1 : self.dimX 
					if ub_wall( i_dim ) >0
                        sdv                       = min(self.intervalX( i_dim ) , ub_wall(i_dim) );
                        self.offspring_X(i_dim,i) = -rand * sdv + self.ub( i_dim )   ; 
                    end
                    if lb_wall( i_dim ) >0
                        sdv                       = min( self.intervalX( i_dim ) , lb_wall(i_dim) );
						self.offspring_X(i_dim,i) = rand * sdv + self.lb( i_dim )   ; 
					end
				end
				
			end 

			for j = 1 : self.numoffspring_Y

				Sigma_Y = zeros( self.dimY , self.dimY );
			
				if self.dimY > 1

					id_cov  	= 	0;
			
					for i_row  =  1 : self.dimY 
	
						for j_col = i_row + 1 : self.dimY
						
							id_cov = id_cov + 1; 
                            self.offspring_cov_Y ( id_cov , i ) = self.offspring_cov_Y ( id_cov , i ) + self.beta * randn; 
							Sigma_Y( i_row , j_col ) = self.offspring_cov_Y ( id_cov , i ) + self.beta * randn; 
							Sigma_Y( j_col , i_row ) = Sigma_Y( i_row , j_col ) ;
											

						end
					end
                end
                
                for i_dim = 1 : self.dimY 
                   if  self.offspring_sdv_Y ( i_dim , i ) < 	self.sdv_Y_lb(i_dim) 
                       self.offspring_sdv_Y ( i_dim , i ) = self.sdv_Y_lb(i_dim) ;
                   elseif  self.offspring_sdv_Y ( i_dim , i ) > 	self.intervalY(i_dim) 
                       self.offspring_sdv_Y ( i_dim , i ) = self.intervalY(i_dim) ;
                   end
                end

				Sigma_Y  = diag( self.offspring_sdv_Y ( : , j ) ); %+ Sigma_Y ;
				self.offspring_Y(:,j) = self.offspring_Y(:,j) + Sigma_Y  * randn( self.dimY , 1 );
				
				% when offspring occurs out of boundary, simply reset by uniform distribution 
				ub_wall = ( self.offspring_Y(:,j) - self.ub_Y  );
				lb_wall =  ( self.lb_Y -  self.offspring_Y(:,j)  );

                

				for i_dim= 1 : self.dimY 
					if ub_wall( i_dim ) >0
                        sdv                       = min(self.intervalY( i_dim ) , ub_wall(i_dim) );
                        self.offspring_Y(i_dim,i) = -rand * sdv + self.ub_Y( i_dim )   ; 
                    end
                    if lb_wall( i_dim ) >0
                        sdv                       = min( self.intervalY( i_dim ) , lb_wall(i_dim) );
						self.offspring_Y(i_dim,i) = rand * sdv + self.lb_Y( i_dim )   ; 
					end
				end
			end

		end 

		function [score_X  , score_Y] = fitness( self, Game )

		
			[nX, nY] = size(Game);
			score_X= zeros( 1 , nX );
			score_Y= zeros( 1 , nY );

			switch self.game_strategy

				case 1 % 1. X:securtiy Y:security 

					for i = 1: nX	
						score_X(i) =    max(Game(i, :));
					end
	
					for j = 1: nY	
						score_Y(j) =     min(Game(:, j));
					end


				case 2 % 2. X:man to man Y:security 
					
					for i = 1: nX	
						score_X(i) =    max(Game(i, :));
					end

			end
			
			

		
		end


		function self = run(self)
            
            self = self.initOPT();

            while(self.count_gen < self.max_gen)
                self = self.recombination();
                self = self.mutation();
                Game = self.ALM();
                [score_X  , score_Y] = self.fitness( Game );
                [sorted_score_X , sorted_index_X] = sort(score_X);
                [sorted_score_Y , sorted_index_Y] = sort(-score_Y);
                self.parent_X   =   self.offspring_X(:, sorted_index_X(1:self.numparent_X));
                self.parent_Y   =   self.offspring_Y(:, sorted_index_Y(1:self.numparent_Y));
                self.parent_sdv_X   =   self.offspring_sdv_X(:, sorted_index_X(1:self.numparent_X));
                self.parent_sdv_Y   =   self.offspring_sdv_Y(:, sorted_index_Y(1:self.numparent_Y));                
                self.parent_cov_X   =   self.offspring_cov_X(:, sorted_index_X(1:self.numparent_X));
                self.parent_cov_Y   =   self.offspring_cov_Y(:, sorted_index_Y(1:self.numparent_Y));
                self.count_gen  = self.count_gen  +1;
                
                elite_candi = self.parent_X(: , 1);
                Flag_C = 0;
                Flag_Ceq = 1;
                [f, C, Ceq] = feval(self.fobj, elite_candi);
                if all ( C - self.Tol < 0 )  
                    Flag_C = 1;
                    
                end
                
                if ~isempty( Ceq ) && all ( abs(Ceq) > self.Tol )
                   Flag_Ceq  =0;
                end
                
                
                if Flag_C && Flag_Ceq && self.elite_val > f 
                    self.elite_val = f;
                    self.elite_X = elite_candi; 
                    self.elite_Y = self.parent_Y(: , 1);
                end
                
                disp(self.count_gen)

            end
		end

	end

end
