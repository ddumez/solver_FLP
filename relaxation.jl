include("./branch and bound/utilitaires.jl")

using JuMP

#pour résoudre avec GLPK
#using GLPKMathProgInterface
#using GLPK

#pour resoudre avec CPLEX
# export LD_LIBRARY_PATH="/usr/local/opt/cplex/cplex/bin/x86-64_linux":$LD_LIBRARY_PATH
using CPLEX

#pour resoudre avec Mosek
#using Mosek

function relaxe()

#fichier a utiliser
nomfile = [0,1,2,3,6,7,9,10,13,26,30,31,33]
#valeur des solutions optimale (sauf pour 0)
zopt = Dict{Integer,Integer}(0 => 1, 1 => 2014, 2 => 4251, 3 => 6051, 6 => 2269, 7 => 4366, 9 => 2480, 10 => 23112, 13 => 3760, 26 => 4448, 30 => 10816, 31 => 4466, 33 => 39463)


for nom in nomfile
    data = instance(0, 0, [], [], [], [], [], [])

    nomfile = String("./instances/p$(nom).txt")
    #nomfile = String("./instances2/cap101")

    lecteur(nomfile, data) #on lit le fichier de donne
    #lecteur2(nomfile, data)

    #declaration
    #mSSCFLP = Model(solver=GLPKSolverLP())::Model #pour resoudre avec GLPK
    #mSSCFLP = Model(solver=GLPKSolverMIP())::Model #pour resoudre avec GLPK le CFLP et UFLP
    mSSCFLP = Model(solver=CplexSolver())::Model #pour resoudre avec CPLEX
    #mSSCFLP = Model(solver=MosekSolver())::Model #pour resoudre avec Mosek

    #variables
    @variable(mSSCFLP, x[1:data.nbDepos] >= 0)
    #@variable(mSSCFLP, x[1:nbDepos], Bin) #type pour le CFLP et UFLP
    @variable(mSSCFLP, y[1:data.nbClients,1:data.nbDepos] >= 0)

    for j=1:data.nbDepos
        for i=1:data.nbClients
            setupperbound(y[i,j], 1)
        end
        setupperbound(x[j], 1)
    end

    #fonction eco relaxe
    @objective(mSSCFLP, Min, sum(data.ouverture[j] * x[j] + sum( y[i,j] * data.association[i,j] * data.demande[i] for i=1:data.nbClients ) for j=1:data.nbDepos))

    #contraintes relaxe
    for j = 1:data.nbDepos
        @constraint(mSSCFLP, sum(y[i,j] * data.demande[i] for i=1:data.nbClients) <= data.capacite[j]*x[j])
        for i = 1:data.nbClients #pour le UFLP ou la contrainte redondante de Holmberg
            @constraint(mSSCFLP, y[i,j] <= x[j])
        end
    end
    for i = 1:data.nbClients
        @constraint(mSSCFLP, sum(y[i,j] for j=1:data.nbDepos) == 1)
    end


#test : affichage du modele
#println(mSSCFLP)

#resolution et affichage du temps de calcul
    @time solve(mSSCFLP; suppress_warnings=true, relaxation=false)

    #extraction des résultats
    println(nomfile," : ")
    println("z = : ", getobjectivevalue(mSSCFLP))
    println("différence proportionelle avec la solution optimale : ", 100 - ((getobjectivevalue(mSSCFLP)*100)/zopt[nom]) )
    for i = 1:data.nbClients
        for j = 1:data.nbDepos
            print(getvalue(y[i,j])," ")
        end
        print("\n")
    end
    println("\n")
    for j = 1:data.nbDepos
        print(getvalue(x[j])," ")
    end
    println("\n\n")

end

end #de relaxe()

relaxe()
