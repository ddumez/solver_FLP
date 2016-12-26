#= deja inclu par le main
include("relaxation.jl")
include("construction.jl")
include("utilitaires.jl")=#

function branchandbound(mSSCFLP::Model, sol::solution, solduale::solutionrelache, data::instance, k::Int64, best::solution, lowerbound, upperbound, etat::Bool)
for i=1:k-1
	print("\t")
end
println("k = ",k," sol : ",sol)

	if (k > data.nbDepos + data.nbClients) #solution complete
		if (sol.z < best.z)
			recopie(sol, best) #on sauvegarde la solution comme meilleure actuelle
		end
	elseif (k > data.nbDepos) #on branche sur les clients
		j = 1 #le depos auquelle clients a été associé si non etat, sinon il faut l'initialiser pour la suite

		if (etat)#descente rapide avec la solution construite
			branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, true)
		else #pas de solution construite pour la descente
			#on cherche un depos ouvert auquel on peu associer ce clients
		 	while (j<=data.nbDepos) && (data.demande[k-data.nbDepos] > sol.capacite[j])
				j += 1
			end

			#on effectue cette association
			if (j<= data.nbDepos)
				sol.y[k-data.nbDepos] = j
				sol.capacite[j] = sol.capacite[j] - data.demande[k-data.nbDepos]
				sol.z = sol.z + data.association[k-data.nbDepos,j]
				if completeRelax(mSSCFLP, data, solduale, sol, k, lowerbound, upperbound) < best.z
					if completesol(sol, data, k) && (sol.z < best.z)
						branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, true)
					else
						reinit(sol, k+1, data)
						branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, false)
					end
				end
			end
		end

		#test des autres association
		if (j< data.nbDepos) #si il peu en exister
			#on cherche l'ensemble des depos ouvert auquel on peu associer ce clients
			possible = Set{Int64}();
			for j=1:data.nbDepos
				if (data.demande[k-data.nbDepos] <= sol.capacite[j]) && (j != sol.y[k-data.nbDepos])
					push!(possible, j)
				end
			end

println("possible : ",possible)

			#remise a l'etat par defaut
			sol.capacite[sol.y[k-data.nbDepos]] = sol.capacite[sol.y[k-data.nbDepos]] + data.demande[k-data.nbDepos]
			sol.z = sol.z - data.association[k-data.nbDepos, sol.y[k-data.nbDepos]]
			sol.y[k-data.nbDepos] = -1

			#on teste toutes les association possibles
			for j in possible
				sol.y[k-data.nbDepos] = j
				sol.capacite[j] = sol.capacite[j] - data.demande[k-data.nbDepos]
				sol.z = sol.z + data.association[k-data.nbDepos,j]
				if completeRelax(mSSCFLP, data, solduale, sol, k, lowerbound, upperbound) < best.z
#print("k = ",k," : ")
					if completesol(sol, data, k) && (sol.z < best.z)
						branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, true)
					else
						reinit(sol, k+1, data)
						branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, false)
					end
				end
				sol.y[k-data.nbDepos] = -1
				sol.capacite[j] = sol.capacite[j] + data.demande[k-data.nbDepos]
				sol.z = sol.z - data.association[k-data.nbDepos, j]
			end
		elseif(j == data.nbDepos)  #il faut tout de meme elever l'association si elle avait été faite au dernier depos
			#remise a l'etat par defaut
			sol.capacite[sol.y[k-data.nbDepos]] = sol.capacite[sol.y[k-data.nbDepos]] + data.demande[k-data.nbDepos]
			sol.z = sol.z - data.association[k-data.nbDepos, sol.y[k-data.nbDepos]]
			sol.y[k-data.nbDepos] = -1
		end
	else #k < data.nbDepos
		#on branche sur les depos
		if (etat)#descente rapide avec la solution construite
			branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, true)
		else #pas de solution construite pour la descente rapide
			#par defaut on ne l'ouvre pas
			sol.x[k] = 0
			sol.capacite[k] = 0
			if completeRelax(mSSCFLP, data, solduale, sol, k, lowerbound, upperbound) < best.z
				if completesol(sol, data, k) && (sol.z < best.z)
					branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, true)
				else
					reinit(sol, k+1, data)
					branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, false)
				end
			end
		end

		#exploration de l'autre possibilite
		if (0 == sol.x[k])
			sol.x[k] = 1
			sol.capacite[k] = data.capacite[k]
			sol.z = sol.z + data.ouverture[k]
			if completeRelax(mSSCFLP, data, solduale, sol, k, lowerbound, upperbound) < best.z
#print("k = ",k," : ")
				if completesol(sol, data, k) && (sol.z < best.z)
					branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, true)
				else
					reinit(sol, k+1, data)
					branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, false)
				end
			end
			sol.x[k] = 0 #remise en etat : par defaut une facilite est ferme
			sol.z = sol.z - data.ouverture[k]
			sol.capacite[k] = 0
		else #1 == sol.x[k]
			sol.x[k] = 0
			sol.capacite[k] = 0
			sol.z = sol.z - data.ouverture[k]
			if completeRelax(mSSCFLP, data, solduale, sol, k, lowerbound, upperbound) < best.z
#print("k = ",k," : ")
				if completesol(sol, data, k) && (sol.z < best.z)
					branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, true)
				else
					reinit(sol, k+1, data)
					branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, false)
				end
			end
		end
	end
end
