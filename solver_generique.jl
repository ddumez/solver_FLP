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

function generique()

#fichier a utiliser
nomfile = [50,51,0,1,2,3,6,7,9,10,13,26,30,31,33]

for nom in nomfile
    data = instance(0, 0, [], [], [], [], [], [])

    nomfile = String("./instances/p$(nom).txt")
    #nomfile = String("./instances2/cap61")

    lecteur(nomfile, data) #on lit le fichier de donne
    #lecteur2(nomfile, data)

 #test de la lecture des donnees
#=    println(data.nbClients)
    println(data.nbDepos)
    for i = 1:data.nbClients
        for j = 1:data.nbDepos
            print(data.association[i,j]," ")
        end
        print("\n")
    end
    println(data.demande)
    println(data.ouverture)
    println(data.capacite)
=#

    #declaration
    #mSSCFLP = Model(solver=GLPKSolverMIP())::Model #pour resoudre avec GLPK
    mSSCFLP = Model(solver=CplexSolver())::Model #pour resoudre avec CPLEX
    #mSSCFLP = Model(solver=MosekSolver())::Model #pour resoudre avec Mosek

    #variables
    @variable(mSSCFLP, x[1:data.nbDepos], Bin) #x[i] = 1 ssi le depos i est ouvert
    @variable(mSSCFLP, y[1:data.nbClients,1:data.nbDepos], Bin) #y[i,j] =1 ssi le client i est aprovisionne par le depos j

    #fonction eco
    @objective(mSSCFLP, Min, sum(data.ouverture[j] * x[j] + sum( y[i,j] * data.association[i,j] for i=1:data.nbClients ) for j=1:data.nbDepos))

    #contraintes
    for j = 1:data.nbDepos
        @constraint(mSSCFLP, sum(y[i,j] * data.demande[i] for i=1:data.nbClients) <= data.capacite[j]*x[j])
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
    for i = 1:data.nbClients
        for j = 1:data.nbDepos
            if ( 0.5 <= getvalue(y[i,j]))
                print("1 ")
            else
                print("0 ")
            end
        end
        print("\n")
    end
    println("\n")
    for j = 1:data.nbDepos
        if (0.5 <= getvalue(x[j]))
            print("1 ")
        else
            print("0 ")
        end
    end
    println("\n\n")

end

end #de generique()

generique()
