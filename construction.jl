function contruit()

#fichier a utiliser
nomfile = [0,1,2,3,6,7,9,10,13,26,30,31,33]

for nom in nomfile
#lecture des donnees
    f = open("./instances/p$(nom).txt")::IOStream
    tmp = split(readline(f)," ")::Array
    nbClients = parse(Int64, tmp[1])::Int64
    nbDepos = parse(Int64, tmp[2])::Int64
println("(",nbClients,";",nbDepos,") : p$(nom)")

    association = collect(reshape(1:nbDepos*nbClients, nbClients, nbDepos))::Array #cout d'association
    for i = 1:nbClients
        tmp = split(readline(f)," ")::Array
        for j = 1:nbDepos
            association[i,j] = parse(Int64, tmp[j])::Int64
        end
    end
    delta = collect(reshape(1:nbDepos*nbClients, nbClients, nbDepos))::Array #cout d'association
    for i = 1:nbClients
        #recherche de cmini
        cmini = association[i,1]
        for j = 1:nbDepos
            if(association[i,j] < cmini)
                cmini = association[i,j]
            end
        end
        #calcul des delta
        for j = 1:nbDepos
            delta[i,j] = association[i,j] - cmini
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

    #variable du resultat
    x = []
    for i=1:nbDepos
        push!(x, 0)
    end
    y = association = collect(reshape(1:nbDepos*nbClients, nbClients, nbDepos))::Array
    for i = 1:nbClients
        for j = 1:nbDepos
            y[i,j] = 0;
        end
    end

    #initialisation du tabeau d'ordre
    ordre = collect(reshape(1:nbDepos*nbClients, nbDepos, nbClients))::Array
    for j =1:nbDepos
        for i=1:nbClients
            ordre[j,i] = i
        end
    end

    #tri des clients par delta pour les facilite
    ordre = collect(reshape(1:nbDepos*nbClients, nbDepos, nbClients))::Array
    for j =1:nbDepos
        for i=1:nbClients
            ordre[j,i] = i
        end
    end
    triDelta(delta, ordre)

    #initialisation des ensembles
    Orest = Set{Int64}(); #facilite restantes 
    Crest = Set{Int64}(); #clients restant
    O = Set{Int64}(); #facilite ouverte
    C = Set{Int64}(); #client satisfait
    totO = Set{Int64}(); #ensemble des sites
    totC = Set{Int64}(); #ensemble des clients
    for j=1:nbDepos
        push!(Orest, j)
        push!(totO, j)
    end
    for i=1:nbClients
        push!(Crest, i)
        push!(totC, i)
    end

    #initialisation des tableau
    clients = []
    phi = []
    for j=1:nbDepos
        push!(clients, [])
        push!(phi, 0.0)
    end

    while ((O != totO) && (C != totC))
        #calcule le nombre de clients qui peut etre assigne a chaque service restant selon l'orde et les clients restant
        #calcule les valeur de phi
        for j in Orest
            capaciterestante = capacite[j]
            clients[j] = []
            phi[j] = ouverture[j]
            for i in 1:nbClients
                if ( (! isempty(find( x-> x==ordre[j,i] , Crest))) && (capaciterestante >= demande[ordre[j,i]]) ) #si le client ordre[i,j] n'a pas ete asigne et il rentre
                    push!(clients[j], i)
                    capaciterestante = capaciterestante - demande[ordre[j,i]]
                    phi[j] = phi[j] + association[ordre[j,i],j]
                end
            end
            phi[j] = phi[j] / size(clients[j])[1]
        end

        #recherche du phimin
        jphimin = first(Orest)
        for j in Orest
            if phi[jphimin] < phi[j]
                jphimin = j
            end
        end

        #ajout dans la solution
        Orest = setdiff(Orest,Set{Int64}([jphimin])) #depos jphimin traite
        O = union(O, Set{Int64}([jphimin])) #depos jphimin traite
        x[jphimin] = 1 #on ouvre le depos jphimin
        for i = 1:size(clients[jphimin])[1]
            Crest = setdiff(Crest,Set{Int64}(clients[jphimin][i])) #client jphimin traite
            C = union(C, Set{Int64}(clients[jphimin][i])) #client jphimin traite
            y[i,jphimin] = 1 #on associe le client i au depos jphimin
        end
    end

    #calcul de la valeur de la solution
    z = sum(ouverture[j] * x[j] + sum( y[i,j] * association[i,j] * demande[i] for i=1:nbClients ) for j=1:nbDepos)
    println("z = : ", z)
    for i = 1:nbClients
        for j = 1:nbDepos
            print(y[i,j]," ")
        end
        print("\n")
    end
    println("\n")
    for j = 1:nbDepos
        print(x[j]," ")
    end
    println("\n\n")
end
end #de contruit()

# trie chaque ligne j par ordre croissant de delta[i,j] ou i est le client corespondant
function triDeltaRec(delta::Array{Int64,2})
    compteur = 0;
    return function (tab::Array{Int64})
            compteur = compteur +1 
            sort!(tab, by=x->delta[x,compteur[1]])
        end
end
function triDelta(delta::Array{Int64,2}, ordre::Array{Int64,2})
    mapslices( triDeltaRec(delta) , ordre, [2])
end

contruit()