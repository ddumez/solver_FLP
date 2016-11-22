using JuMP

#pour résoudre avec GLPK
using GLPKMathProgInterface
using GLPK

#pour resoudre avec CPLEX
#using CPLEX

#pour resoudre avec Mosek
#using Mosek

function relaxe()

#fichier a utiliser
nomfile = [0,1,2,3,6,7,9,10,13,26,30,31,33]

for nom in nomfile
    #lecture des donnees
    f = open("./instances/p$(nom).txt")::IOStream
    tmp = split(readline(f)," ")::Array
    nbClients = parse(Int64, tmp[1])::Int64
    nbDepos = parse(Int64, tmp[2])::Int64
println("(",nbClients,";",nbDepos,") : p$(nom)")
    association = fill(1.0, (nbClients,nbDepos)) #cout d'association
    
    for i = 1:nbClients
        tmp = split(readline(f)," ")::Array
        for j = 1:nbDepos
            association[i,j] = (Float64)(parse(Int64, tmp[j]))
        end
    end

    tmp = split(readline(f)," ")::Array
    demande = []::Array
    for i = 1:nbClients
        push!(demande, parse(Int64, tmp[i]))
    end

    #passage des couts en cout par unité
    for i = 1:nbClients
        for j = 1:nbDepos
            association[i,j] = association[i,j] / demande[i];
        end
    end

    tmp = split(readline(f)," ")::Array
    ouverture = []
    for j = 1:nbDepos
        push!(ouverture, parse(Int64, tmp[j]))
    end

    tmp = split(readline(f)," ")::Array
    capacite =[]::Array
    for j = 1:nbDepos
        push!(capacite, parse(Int64, tmp[j]))
    end

#= test de la lecture des donnees
    println(nbClients)
    println(nbDepos)
    for i = 1:nbClients
        for j = 1:nbDepos
            print(association2[i,j]," ")
        end
        print("\n")
    end
    println(demande)
    println(ouverture)
    println(capacite)
=#

    #declaration
    mSSCFLP = Model(solver=GLPKSolverLP())::Model #pour resoudre avec GLPK
    #mSSCFLP = Model(solver=CplexSolver())::Model #pour resoudre avec CPLEX
    #mSSCFLP = Model(solver=MosekSolver())::Model #pour resoudre avec Mosek

    #variables
    @variable(mSSCFLP, x[1:nbDepos] >= 0)
    @variable(mSSCFLP, y[1:nbClients,1:nbDepos] >= 0)

    for j=1:nbDepos
        for i=1:nbClients
            setupperbound(y[i,j], 1)
        end
        setupperbound(x[j], 1)
    end

    #fonction eco relaxe
    @objective(mSSCFLP, Min, sum(ouverture[j] * x[j] + sum( y[i,j] * association[i,j] * demande[i] for i=1:nbClients ) for j=1:nbDepos))

    #contraintes relaxe
    for j = 1:nbDepos
        @constraint(mSSCFLP, sum(y[i,j] * demande[i] for i=1:nbClients) <= capacite[j]*x[j])
    end
    for i = 1:nbClients
        @constraint(mSSCFLP, sum(y[i,j] for j=1:nbDepos) == 1)
    end

#test : affichage du modele
#println(mSSCFLP)

#resolution et affichage du temps de calcul
    @time solve(mSSCFLP; suppress_warnings=true, relaxation=false)

    #extraction des résultats
    println("z = : ", getobjectivevalue(mSSCFLP))
#=    for i = 1:nbClients
        for j = 1:nbDepos
            print(getvalue(y[i,j])," ")
        end
        print("\n")
    end
    println("\n")
    for j = 1:nbDepos
        print(getvalue(x[j])," ")
    end =#
    println("\n\n")

end

end #de relaxe()

relaxe()
