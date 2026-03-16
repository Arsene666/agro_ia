import numpy as np
from pymoo.core.problem import Problem
from pymoo.algorithms.moo.nsga2 import NSGA2
from pymoo.optimize import minimize
from predictionReelTime import predictionReelTime

class TomatoProblem(Problem):

    def __init__(self, tomatoState : int):
        super().__init__(
            n_var=2,
            n_obj=2,
            n_constr=0,
            xl=np.array([0,40]),
            xu=np.array([35,95])
        )
        self.tomatoState = tomatoState

    def _evaluate(self, x, out, *args, **kwargs):

        results = []

        for i in range(len(x)):

            T = x[i,0]
            H = x[i,1] / 100

            Dbio, Dgout = predictionReelTime(T, H, self.tomatoState)

            results.append([-Dbio, -Dgout])

        out["F"] = np.array(results)

def optimisation(tomatoState : int) : 
    algorithm = NSGA2(pop_size=100)
    w = 0.5

    res = minimize(
        TomatoProblem(tomatoState),
        algorithm,
        ('n_gen',200),
        verbose=False
    )

    X = res.X
    F = res.F

    Dbio = -F[:,0]
    Dgout = -F[:,1]

    score = w*Dbio + (1-w)*Dgout
    best = np.argmax(score)

    T_best = X[best,0]
    H_best = X[best,1]

    return H_best, T_best, Dbio[best], Dgout[best]
"""
    print("Meilleure solution :")
    print("Température :", T_best)
    print("Humidité :", H_best)
    print("Durée biologique :", Dbio[best])
    print("Durée gustative :", Dgout[best])
"""
    


if __name__ == "__main__":

    stadeTomate = 30
    optimisation(stadeTomate)