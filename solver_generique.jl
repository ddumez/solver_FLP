using JuMP
using GLPKMathProgInterface
using GLPK

#fichier a utiliser
nomfile = [0,1#=,2,3,6,7,9,10,13,26,30,31,33=#]

for nom in nomfile
    #lecture des donnees
    f = open("./instances/p$(nom).txt")
    tmp = split(readline(f)," ")
    nbClients = parse(Int64, tmp[1])
    nbDepos = parse(Int64, tmp[2])

    association = collect(reshape(1:nbDepos*nbClients, nbClients, nbDepos)) #cout d'association
    for i = 1:nbClients
        tmp = split(readline(f)," ")
        for j = 1:nbDepos
            association[i,j] = parse(Int64, tmp[j])
        end
    end

    tmp = split(readline(f)," ")
    demande = []
    for i = 1:nbClients
        push!(demande, parse(Int64, tmp[i]))
    end

    tmp = split(readline(f)," ")
    ouverture = []
    for j = 1:nbDepos
        push!(ouverture, parse(Int64, tmp[j]))
    end

    tmp = split(readline(f)," ")
    capacite =[]
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
    mSSCFLP = Model(solver=GLPKSolverMIP())

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

print(mSSCFLP)

    tic()
    status = solve(mSSCFLP)
    time = toq();

    #extraction des résultats
    println("z = : ", getobjectivevalue(mSSCFLP))
    for i = 1:nbClients
        for j = 1:nbDepos
            print(getvalue(y[i,j])," ")
        end
        print("\n")
    end
    println("\n")
    for j = 1:nbDepos
        print(getvalue(x[j])," ")
    end
    println("\n\n temps : ",time)
    println("\n\n")

end
