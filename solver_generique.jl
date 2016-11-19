using JuMP
using GLPKMathProgInterface
using CPLEX

function main()

#fichier a utiliser
nomfile = [0,1,2,3,6,7,9,10,13,26,30,31,33]

for nom in nomfile
    #lecture des donnees
    f = open("./instances/p$(nom).txt")::IOStream
    tmp = split(readline(f)," ")::Array
    nbClients = parse(Int64, tmp[1])::Int64
    nbDepos = parse(Int64, tmp[2])::Int64
println("(",nbClients,";",nbDepos,")")
    association = collect(reshape(1:nbDepos*nbClients, nbClients, nbDepos))::Array #cout d'association
    for i = 1:nbClients
        tmp = split(readline(f)," ")::Array
        for j = 1:nbDepos
            association[i,j] = parse(Int64, tmp[j])::Int64
        end
    end

    tmp = split(readline(f)," ")::Array
    demande = []::Array
    for i = 1:nbClients
        push!(demande, parse(Int64, tmp[i]))
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

    println(nbClients)
    println(nbDepos)
    for i = 1:nbClients
        for j = 1:nbDepos
            print(association[i,j]," ")
        end
        print("\n")
    end
    println(demande)
    println(ouverture)
    println(capacite)


    #declaration
    mSSCFLP = Model(solver=CplexSolver())::Model
    #variables
    @variable(mSSCFLP, x[1:nbDepos], Bin)
    @variable(mSSCFLP, y[1:nbClients,1:nbDepos], Bin)

    @objective(mSSCFLP, Min, sum(ouverture[j] * x[j] + sum( y[i,j] * association[i,j] for i=1:nbClients ) for j=1:nbDepos))

    for j = 1:nbDepos
        @constraint(mSSCFLP, sum(y[i,j] * demande[i] for i=1:nbClients) <= capacite[j]*x[j])
    end
    for i = 1:nbClients
        @constraint(mSSCFLP, sum(y[i,j] for j=1:nbDepos) == 1)
    end

#println(mSSCFLP)

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
    end=#
    println("\n\n")

end

end #du main

main()
