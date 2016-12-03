type solution
	x #facilite ouvertes
	capacite #capacite restantes des depos, 0 si non ouvert mettre a jour la constructionsi utilise
	y #services associe, tableau d'entier car SS, -1 si pas associe
	z::Int64 #valeur de la solution
end

type solutionrelache
    x #facilite ouvertes, variable du modele
    y #services associe, variable du modele
    e #variable d'ecart des contraites
    z::Float64 #valeur de la solution
end

type instance
	nbClients::Int64
	nbDepos::Int64
	association
	demande
	ouverture
	capacite
	delta
    ordre
end

function initialise(data::instance, sol::solution)
	sol.y = [ -1 for i=1:data.nbClients ]
	sol.x = [0 for j=1:data.nbDepos]
	sol.capacite = [0 for j=1:data.nbDepos]
	sol.z = 0
end

function lecteur(nomfile::String, data::instance)
    f = open(nomfile)::IOStream
    tmp = split(readline(f)," ")::Array
    data.nbClients = parse(Int64, tmp[1] )::Int64
    data.nbDepos = parse(Int64, tmp[2])::Int64

    data.association = collect(reshape(1:data.nbDepos*data.nbClients, data.nbClients, data.nbDepos))::Array #cout d'association
    for i = 1:data.nbClients
        tmp = split(readline(f)," ")::Array
        for j = 1:data.nbDepos
            data.association[i,j] = parse(Int64, tmp[j])::Int64
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

    tmp = split(readline(f)," ")::Array
    data.demande = []::Array
    for i = 1:data.nbClients
        push!(data.demande, parse(Int64, tmp[i]))
    end

    tmp = split(readline(f)," ")::Array
    data.ouverture = []
    for j = 1:data.nbDepos
        push!(data.ouverture, parse(Int64, tmp[j]))
    end

    tmp = split(readline(f)," ")::Array
    data.capacite =[]::Array
    for j = 1:data.nbDepos
        push!(data.capacite, parse(Int64, tmp[j]))
    end

    data.ordre = collect(reshape(1:data.nbDepos*data.nbClients, data.nbDepos, data.nbClients))::Array
    for j =1:data.nbDepos
        for i=1:data.nbClients
            data.ordre[j,i] = i
        end
    end
    data.ordre = triDelta(data.delta, data.ordre)     #tri des clients par delta pour les facilite
end

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

#recopie une solution (les deux doivent etre initialise)
function recopie(sol1::solution, sol2::solution)
	for j=1:size(sol1.x)[1]
		sol2.x[j] = sol1.x[j]
		sol2.capacite[j] = sol1.capacite[j]
	end
	for i=1:size(sol1.y)[1]
		sol2.y[i] = sol1.y[i]
	end
	sol2.z = sol1.z
end
