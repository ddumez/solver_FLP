using JuMP

#pour résoudre avec GLPK
using GLPKMathProgInterface
using GLPK

#pour resoudre avec CPLEX
# export LD_LIBRARY_PATH="/usr/local/opt/cplex/cplex/bin/x86-64_linux":$LD_LIBRARY_PATH
#using CPLEX

#pour resoudre avec Mosek
#using Mosek

function solverMip()
    return Model(solver=GLPKSolverMIP())::Model
    #return Model(solver=CplexSolver())::Model
    #return Model(solver=MosekSolver())::Model
end

function solverLP()
	return Model(solver=GLPKSolverLP())::Model
    #return Model(solver=CplexSolver())::Model
    #return Model(solver=MosekSolver())::Model
end

include("utilitaires.jl")
include("relaxation.jl")
include("construction.jl")


data = instance(0, 0, [], [], [], [], [], [])
sol = solution([], [], 0)
solduale = solutionrelache([], [], [], 0.0)
nomfile = String("./../instances/p0.txt")
mSSCFLP = solverLP()


lecteur(nomfile, data) #on lit le fichier de donne
initialise(data, sol) #on initialise la solution a une solution vide
conctuctinitsol(sol, data) #on construit une premiere solution initiale avec l'heuristique de homberg
relaxinit(mSSCFLP, data, solduale) #on calcule la relaxation continue

println("solution relaxe : ", solduale.z)
for j = 1:data.nbDepos
	print(getvalue(solduale.x[j]))
end
print("\n")
for i = 1:data.nbClients
	for j = 1:data.nbDepos
		print(getvalue(solduale.y[i,j]))
	end
	print("\n")
end

completeRelax(mSSCFLP, data, solduale, sol, data.nbDepos+2)

println("solution relaxe : ", solduale.z)
for j = 1:data.nbDepos
	print(getvalue(solduale.x[j]))
end
print("\n")
for i = 1:data.nbClients
	for j = 1:data.nbDepos
		print(getvalue(solduale.y[i,j]))
	end
	print("\n")
end