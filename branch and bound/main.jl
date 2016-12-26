using JuMP

#pour résoudre avec GLPK
#using GLPKMathProgInterface
#using GLPK

#pour resoudre avec CPLEX
# export LD_LIBRARY_PATH="/usr/local/opt/cplex/cplex/bin/x86-64_linux":$LD_LIBRARY_PATH
#using CPLEX

#pour resoudre avec Mosek
using Mosek

function solverMip()
    #return Model(solver=GLPKSolverMIP())::Model
    #return Model(solver=CplexSolver())::Model
    return Model(solver=MosekSolver())::Model
end

function solverLP()
	#return Model(solver=GLPKSolverLP())::Model
    #return Model(solver=CplexSolver())::Model
    return Model(solver=MosekSolver())::Model
end

include("utilitaires.jl")
include("relaxation.jl")
include("construction.jl")
include("recursif.jl")


data = instance(0, 0, [], [], [], [], [], [])
sol = solution([], [], [], 0)
best = solution([], [], [], 0)

solduale = solutionrelache([], [], [], 0.0)
nomfile = String("./../instances/p1.txt")
mSSCFLP = solverLP()
lowerbound = [] #pour les constrainte de borne sur les variables du LP
upperbound = []


lecteur(nomfile, data) #on lit le fichier de donne
initialise(data, sol) #on initialise la solution a une solution vide
initialise(data, best)
conctuctinitsol(best, data) #on construit une premiere solution initiale avec l'heuristique de homberg
recopie(best, sol) #on recopie la solution touve pour la descente rapide
relaxinit(mSSCFLP, data, solduale, lowerbound, upperbound) #on calcule la relaxation continue


println("Valeur de la solution construite : ", best.z)
print("Facilites ouvertes : ")
for j=1:data.nbDepos
	print(best.x[j]," ");
end
print("\nCapacite restantes : ")
for j=1:data.nbDepos
	print(best.capacite[j]," ");
end
print("\nAssociation client/depos : ")
for i=1:data.nbClients
	print(best.y[i]," ")
end
print("\n\n")

branchandbound(mSSCFLP, sol, solduale, data, 1, best, lowerbound, upperbound, true)

println("Valeur de la solution : ",best.z)
print("Facilites ouvertes : ")
for j=1:data.nbDepos
	print(best.x[j]," ");
end
print("\nAssociation client/depos : ")
for i=1:data.nbClients
	print(best.y[i]," ")
end
print("\n\n")
