function contruit()

#fichier a utiliser
nomfile = [#=50,=#51#=0,1,2,3,6,7,9,10,13,26,30,31,33=#] #nom des fichiers d'instances
#valeur des solutions optimale (sauf pour 0)
zopt = Dict{Integer,Integer}(0 => 1, 1 => 2014, 2 => 4251, 3 => 6051, 6 => 2269, 7 => 4366, 9 => 2480, 10 => 23112, 13 => 3760, 26 => 4448, 30 => 10816, 31 => 4466, 33 => 39463, 50 => 360, 51 => 360)

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
    y = collect(reshape(1:nbDepos*nbClients, nbClients, nbDepos))::Array
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
    ordre = triDelta(delta, ordre)#tri des clients par delta pour les facilite
tic()
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

println("capacite : ",capacite)
println("ouverture : ",ouverture)
println("ordre : ",ordre)
println("demande : ",demande)
println("delta : ",delta)
println("\n\n");

    while ((O != totO) && (C != totC))
        #calcule le nombre de clients qui peut etre assigne a chaque service restant selon l'orde et les clients restant
        #calcule les valeur de phi
        for j in Orest
            capaciterestante = capacite[j]
            clients[j] = []
            phi[j] = ouverture[j]
            for i in 1:nbClients
                if ( (! isempty(find( x-> x==ordre[j,i] , Crest))) && (capaciterestante >= demande[ordre[j,i]]) ) #si le client ordre[i,j] n'a pas ete asigne et il rentre
                    push!(clients[j], ordre[j,i])
                    capaciterestante = capaciterestante - demande[ordre[j,i]]
                    phi[j] = phi[j] + delta[ordre[j,i],j]
                end
            end
            phi[j] = phi[j] / size(clients[j])[1]
        end
println("phi : ",phi)
println("client : ",clients)
println("Orest : ",Orest)
        #recherche du phimin
        jphimin = first(Orest)
        for j in Orest
            if phi[jphimin] > phi[j]
                jphimin = j
            end
        end

println("depos ouvert : ",jphimin)
print("ordre : ");
for i=1:nbClients
    print(ordre[jphimin,i]," ")
end
print("\n")
        #ajout dans la solution
        Orest = setdiff(Orest,Set{Int64}([jphimin])) #depos jphimin traite
        O = union(O, Set{Int64}([jphimin])) #depos jphimin traite
        x[jphimin] = 1 #on ouvre le depos jphimin
        for i = 1:size(clients[jphimin])[1]
            Crest = setdiff(Crest,Set{Int64}(clients[jphimin][i])) #client jphimin traite
            C = union(C, Set{Int64}(clients[jphimin][i])) #client jphimin traite
            y[clients[jphimin][i],jphimin] = 1 #on associe le client i au depos jphimin
println("client ",clients[jphimin][i]," ajoute, demande ",demande[clients[jphimin][i]])
        end
println("\n")
    end

    #calcul de la valeur de la solution
    println(toc())
    z = sum(ouverture[j] * x[j] + sum( y[i,j] * association[i,j] for i=1:nbClients ) for j=1:nbDepos)
    println("z = : ", z)
    println("différence proportionelle avec la solution optimale : ", ((z*100)/zopt[nom]) -100 )
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
    compteur = [];
    push!(compteur,0);
    return function (tab::Array{Int64})
            compteur[1] = compteur[1] +1
            sort!(tab, by=x->delta[x,compteur[1]])
        end
end
function triDelta(delta::Array{Int64,2}, ordre::Array{Int64,2})
    mapslices( triDeltaRec(delta) , ordre, [2])
end

contruit()
