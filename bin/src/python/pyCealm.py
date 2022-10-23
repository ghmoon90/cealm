from logging import warning
import numpy as np

class Cealm_:

    X_dim                     =  0
    Y_dim                     =  0

    X_lower                   = np.array([])
    X_upper                   = np.array([])
    Y_lower                   = np.array([])
    Y_upper                   = np.array([])

    num_parent_X              = 0
    num_offspring_X           = 0
    num_parent_Y              = 0
    num_offspring_Y           = 0

    range_X                   = np.array([])
    range_Y                   = np.array([]) 
    obj                       = []

cealm                      = Cealm_()
parent_Costate            = np.array([])
parent_Costate_sdv        = np.array([])
parent_State              = np.array([])
parent_State_sdv          = np.array([])

offsp_State               = np.array([])
offsp_Costate             = np.array([])
offsp_State_sdv           = np.array([])
offsp_Costate_sdv         = np.array([])

# 
def set_prob ( X_lower, X_upper, Y_lower, Y_upper,  num_parent_X, num_parent_Y , num_offspring_X, num_offspring_Y , obj_fnc ):
    
    #set_prob ( [ 1 2], [3 4], Y_lower, Y_upper,  num_parent_X, num_parent_Y , num_offspring_X, num_offspring_Y , obj_fnc )
    global cealm

    # search variable bound
    cealm.X_lower               = np.array(X_lower)
    cealm.X_upper               = np.array(X_upper) 
    cealm.Y_lower               = np.array(Y_lower)  
    cealm.Y_upper               = np.array(Y_upper)  

    cealm.X_dim                 = len(X_lower)
    cealm.Y_dim                 = len(Y_lower)  

    if (len(X_lower) != len(X_upper)): 
        ValueError('X bound is incorrect')
    if (len(Y_lower) != len(Y_upper)): 
        ValueError('Y bound is incorrect')

    cealm.range_X               = cealm.X_upper - cealm.X_lower 
    cealm.range_Y               = cealm.Y_upper - cealm.Y_lower 

    
    cealm.num_parent_X          = num_parent_X
    cealm.num_offspring_X       = num_offspring_X
    cealm.num_parent_Y          = num_parent_Y
    cealm.num_offspring_Y       = num_offspring_Y

    cealm.obj                   = obj_fnc


    return 1


def init_pop():

    global parent_Costate, parent_Costate_sdv, parent_State, parent_State_sdv
    global offsp_State, offsp_Costate, offsp_State_sdv, offsp_Costate_sdv

    try:

        parent_State          = np.zeros(cealm.X_dim , cealm.num_parent_X) 
        parent_Costate        = np.zeros(cealm.Y_dim , cealm.num_parent_Y) 

        parent_State_sdv      = np.zeros(cealm.X_dim , cealm.num_parent_X) 
        parent_Costate_sdv    = np.zeros(cealm.Y_dim , cealm.num_parent_X) 

        offsp_State           = np.zeros(cealm.X_dim , cealm.num_offspring_X)
        offsp_Costate         = np.zeros(cealm.Y_dim , cealm.num_offspring_Y)

        offsp_State_sdv       = np.zeros(cealm.X_dim , cealm.num_offspring_X)
        offsp_Costate_sdv     = np.zeros(cealm.Y_dim , cealm.num_offspring_Y)  


        for idx in range(0,cealm.num_parent_X):
            for k in range(0,cealm.X_dim):
                parent_State[k][idx]          = ( np.random.rand(1 , 1) ) * cealm.range_X[k] + cealm.X_lower[k]
                parent_State_sdv[k][idx]      = ( np.random.rand(1 , 1) ) * cealm.range_X[k] 

        for idy in range(0,cealm.num_parent_Y):
            for k in range(0,cealm.Y_dim):
                parent_Costate[k][idy]        = ( np.random.rand(1 , 1) ) * cealm.range_Y[k] + cealm.Y_lower[k]
                parent_Costate_sdv[k][idy]    = ( np.random.rand(1 , 1) ) * cealm.range_Y[k] 
        
        # popmulation initialized 
        print('popmulation initialized')

    except:
        ValueError('population initialization failed.')

    return 1

def evolve():

    global cealm
    global parent_Costate, parent_Costate_sdv, parent_State, parent_State_sdv
    global offsp_State, offsp_Costate, offsp_State_sdv, offsp_Costate_sdv

    # mutation
    for idx in range(0,cealm.num_parent_X):
        idp1 = np.random.randint(0,cealm.num_parent_X)

        for k in range(0,cealm.X_dim):


            offsp_State[k][idx]          = parent_State[k][idp1] 
            offsp_State_sdv[k][idx]      = parent_State_sdv[k][idp1] 


    for idy in range(0,cealm.num_parent_Y):
        idp1 = np.random.randint(0,cealm.num_parent_Y)
        for k in range(0,cealm.Y_dim):


            offsp_Costate[k][idy]        = parent_Costate[k][idp1] 
            offsp_Costate_sdv[k][idy]    = parent_Costate_sdv[k][idp1] 
    
    # annealing 


    



    offsp_State           = np.random.rand(cealm.dim_X , cealm.num_offspring_X)
    offsp_Costate         = np.random.rand(cealm.dim_Y , cealm.num_offspring_Y)

    offsp_State_sdv       = np.random.rand(cealm.dim_X , cealm.num_offspring_X)
    offsp_Costate_sdv     = np.random.rand(cealm.dim_Y , cealm.num_offspring_Y)  

    return 1

def eval_game( gen_count ):

    global cealm

    # ALM Evaluation
    Cost_Mat = np.array( cealm.num_offspring_X , cealm.num_offspring_Y  )
    for idx in cealm.num_offspring_X:
        for idy in cealm.num_offspring_Y:
            stateX = offsp_State [:][idx]
            stateY = offsp_Costate [:][idy]
            Cost_Mat =  [idx][idy] =  ALM( stateX, stateY )


    # safety-strategy 
    # best among worst ; mitigate worst case 
    # X goal minimizing Augmented Largrangian : Safety Strategy of X ; for each X, choose candidates for some Y which lead maximum ALF, Then sort these X asending order. 
    # Y goal maximizing Augmented Largrangian :


    


    return 1

def ALM( X , Y ):

    global cealm 

    v1 = eval( cealm.obj + '(X)' )
    v2 = 0
    v3 = 0

    

    return v1 + v2 + v3

