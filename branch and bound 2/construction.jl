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
                    phi[j] = phi[j] + data.delta[data.ordre[j,i],j]
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
