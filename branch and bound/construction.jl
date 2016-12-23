function conctuctinitsol(sol::solution, data::instance)
    #initialisation des ensembles
    Orest = Set{Int64}(1:data.nbDepos); #facilite restantes
    Crest = Set{Int64}(1:data.nbClients); #clients restants

    #initialisation des tableau
    clients = []
    phi = []
    for j=1:data.nbDepos
        push!(clients, [])
        push!(phi, 0.0)
    end

    while ((Orest != Set{Int64}()) && (Crest != Set{Int64}()))
        #calcule le nombre de clients qui peut etre assigne a chaque service restant selon l'orde et les clients restant
        #calcule les valeur de phi
        for j in Orest
            capaciterestante = data.capacite[j]
            clients[j] = []
            phi[j] = data.ouverture[j]
            for i in 1:data.nbClients
                if ( (! isempty(find( x-> x==data.ordre[j,i] , Crest))) && (capaciterestante >= data.demande[data.ordre[j,i]]) ) #si le client ordre[i,j] n'a pas ete asigne et il rentre
                    push!(clients[j], data.ordre[j,i])
                    capaciterestante = capaciterestante - data.demande[data.ordre[j,i]]
                    phi[j] = phi[j] + data.association[data.ordre[j,i],j]
                end
            end
            phi[j] = phi[j] / size(clients[j])[1]
        end

        #recherche du phimin
        jphimin = first(Orest)
        for j in Orest
            if phi[jphimin] > phi[j]
                jphimin = j
            end
        end

        #ajout dans la solution
        Orest = setdiff(Orest,Set{Int64}([jphimin])) #depos jphimin traite
        sol.x[jphimin] = 1 #on ouvre le depos jphimin
        sol.z = sol.z + data.ouverture[jphimin] #on compte le cout d'ouverture
        sol.capacite[jphimin] = data.capacite[jphimin]
        for i = 1:size(clients[jphimin])[1]
            Crest = setdiff(Crest,Set{Int64}(clients[jphimin][i])) #client jphimin traite
            sol.y[clients[jphimin][i]] = jphimin #on associe le client i au depos jphimin
            sol.capacite[jphimin] = sol.capacite[jphimin] - data.demande[clients[jphimin][i]]
            sol.z = sol.z + data.association[clients[jphimin][i], jphimin] #on compte le cout de connexion
        end
    end

    return Crest == Set{Int64}() #si on a reussi s a construire une solution admissible
end

function completesol(sol::solution, dataP::instance, k::Int64)
println("solution initiale : ",sol)
    #initialisation des ensembles
    Orest = Set{Int64}(); #facilite restantes
    Crest = Set{Int64}( (max(k + 1 - dataP.nbDepos , 1)):dataP.nbClients) #clients restant

    #creation de l'ensemble de donne du sous-probleme
    data = instance(dataP.nbClients, dataP.nbDepos, [], dataP.demande, [], [], [], [])
    for j=1:min(k, dataP.nbDepos)
        if (1 == sol.x[j])
            push!(data.ouverture, 0) #il est deja ouvert donc deja paye
            push!(data.capacite, sol.capacite[j])
            push!(Orest, j)
        else
            push!(data.ouverture,  2^55 - 1) #on s'interdit de l'ouvrir
            push!(data.capacite, 0)
        end
    end
    for j=(k+1):data.nbDepos
        push!(data.ouverture, dataP.ouverture[j])
        push!(data.capacite, dataP.capacite[j])
        push!(Orest, j)
    end
    data.association = collect(reshape(1:data.nbDepos*data.nbClients, data.nbClients, data.nbDepos))::Array #cout d'association
    for i = 1:data.nbClients
        for j = 1:data.nbDepos
            if (j in Orest)
                data.association[i,j] = dataP.association[i,j]
            else
                data.association[i,j] = 2^55 - 1
            end
        end
    end
    data.delta = collect(reshape(1:data.nbDepos*data.nbClients, data.nbClients, data.nbDepos))::Array #cout d'association
    for i = 1:data.nbClients
        #recherche de cmini
        cmini = data.association[i,1]
        for j = 1:data.nbDepos
            if(data.association[i,j] < cmini)
                cmini = data.association[i,j]
            end
        end
        #calcul des delta
        for j = 1:data.nbDepos
            data.delta[i,j] = data.association[i,j] - cmini
        end
    end
    data.ordre = collect(reshape(1:data.nbDepos*data.nbClients, data.nbDepos, data.nbClients))::Array
    for j =1:data.nbDepos
        for i=1:data.nbClients
            data.ordre[j,i] = i
        end
    end
    data.ordre = triDelta(data.delta, data.ordre)

println("data.nbClients : ",data.nbClients)
println("data.nbDepos : ",data.nbDepos)
println("data.association : ",data.association)
println("data.delta : ",data.delta)
println("data.ordre :")
for j=1:data.nbDepos
    print(j," : ")
    for i=1:data.nbClients
        print(data.ordre[j,i]," ")
    end
    print("\n")
end
println("data.ouverture : ",data.ouverture)
println("data.capacite : ",data.capacite)
println("Orest : ",Orest)
println("Crest : ",Crest)
println("\n")
println(data.nbClients," ",data.nbDepos)
for i=1:data.nbClients
    for j=1:data.nbDepos
        print(data.association[i,j]," ")
    end
    print("\n")
end
for i=1:data.nbClients
    print(data.demande[i]," ")
end
print("\n")
for j=1:data.nbDepos
    print(data.ouverture[j]," ")
end
print("\n")
for j=1:data.nbDepos
    print(data.capacite[j]," ")
end
print("\n\n")

    #initialisation des tableau
    clients = []
    phi = []
    for j=1:data.nbDepos
        push!(clients, [])
        push!(phi, 0.0)
    end

    #on utilise l'heuristique de la meme maniere mais avec un depart diferent
    while ((Orest != Set{Int64}()) && (Crest != Set{Int64}()))
        #calcule le nombre de clients qui peut etre assigne a chaque service restant selon l'orde et les clients restant
        #calcule les valeur de phi
        for j in Orest
            capaciterestante = data.capacite[j]
            clients[j] = []
            phi[j] = data.ouverture[j]
            for i in 1:data.nbClients
                if ( (! isempty(find( x-> x==data.ordre[j,i] , Crest))) && (capaciterestante >= data.demande[data.ordre[j,i]]) ) #si le client ordre[i,j] n'a pas ete asigne et il rentre
                    push!(clients[j], data.ordre[j,i])
                    capaciterestante = capaciterestante - data.demande[data.ordre[j,i]]
                    phi[j] = phi[j] + data.association[data.ordre[j,i],j]
                end
            end
            phi[j] = phi[j] / size(clients[j])[1]
        end

        #recherche du phimin
        jphimin = first(Orest)
        for j in Orest
            if phi[jphimin] > phi[j]
                jphimin = j
            end
        end

        #ajout dans la solution
        Orest = setdiff(Orest,Set{Int64}([jphimin])) #depos jphimin traite
        sol.x[jphimin] = 1 #on ouvre le depos jphimin
        sol.capacite[jphimin] = data.capacite[jphimin] #on ouvre le depos jphimin
        sol.z = sol.z + data.ouverture[jphimin] #on compte le cout d'ouverture
print("ouverture de ",jphimin," avec ",clients[jphimin])
        for i = 1:size(clients[jphimin])[1]
            Crest = setdiff(Crest,Set{Int64}(clients[jphimin][i])) #client jphimin traite
            sol.y[clients[jphimin][i]] = jphimin #on associe le client i au depos jphimin
            sol.capacite[jphimin] = sol.capacite[jphimin] - data.demande[clients[jphimin][i]] #on associe le client i au depos jphimin
            sol.z = sol.z + data.association[clients[jphimin][i], jphimin] #on compte le cout de connexion
        end
println(" reste ",sol.capacite[jphimin])
    end

println("solution complete : ",sol,"\n")

    return Crest == Set{Int64}() #si on a reussis a construire une solution admissible
end
