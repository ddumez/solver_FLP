function conctuctinitsol(sol::solution, data::instance)
    #initialisation des ensembles
    Orest = Set{Int64}(); #facilite restantes
    Crest = Set{Int64}(); #clients restant
    O = Set{Int64}(); #facilite ouverte
    C = Set{Int64}(); #client satisfait
    totO = Set{Int64}(); #ensemble des sites
    totC = Set{Int64}(); #ensemble des clients
    for j=1:data.nbDepos
        push!(Orest, j)
        push!(totO, j)
    end
    for i=1:data.nbClients
        push!(Crest, i)
        push!(totC, i)
    end

    #initialisation des tableau
    clients = []
    phi = []
    for j=1:data.nbDepos
        push!(clients, [])
        push!(phi, 0.0)
    end

    while ((O != totO) && (C != totC))
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
        O = union(O, Set{Int64}([jphimin])) #depos jphimin traite
        sol.x[jphimin] = 1 #on ouvre le depos jphimin
        sol.z = sol.z + data.ouverture[jphimin] #on compte le cout d'ouverture
        for i = 1:size(clients[jphimin])[1]
            Crest = setdiff(Crest,Set{Int64}(clients[jphimin][i])) #client jphimin traite
            C = union(C, Set{Int64}(clients[jphimin][i])) #client jphimin traite
            sol.y[clients[jphimin][i]] = jphimin #on associe le client i au depos jphimin
            sol.z = sol.z + data.association[clients[jphimin][i], jphimin] #on compte le cout de connexion
        end
    end

end