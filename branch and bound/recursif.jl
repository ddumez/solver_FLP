#= deja inclu par le main
include("relaxation.jl")
include("construction.jl")
include("utilitaires.jl")=#

function branchandbound(mSSCFLP::Model, sol::solution, solduale::solutionrelache, data::instance, k::Int64, best::solution, lowerbound, upperbound)
for i=1:k-1
	print("\t")
end
println("k = ",k," sol : ",sol)

	if (k > data.nbDepos + data.nbClients)
		if (sol.z < best.z)
			recopie(sol, best) #on sauvegarde la solution comme meilleure actuelle
		end
	elseif (k > data.nbDepos)
		#on branche sur les clients
		#descente rapide avec la solution construite
		branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound)

		#on cherche l'ensemble des depos ouvert auquel on peu associer ce clients
		possible = Set{Int64}();
		for j=1:data.nbDepos
			if (data.demande[k-data.nbDepos] <= sol.capacite[j]) && (j != sol.y[k-data.nbDepos])
				push!(possible, j)
			end
		end

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
print("k = ",k," : ")
					if completesol(sol, data, k) && (sol.z < best.z)
						branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound)
					else
						reinit(sol, k+1, data)
					end
				end
				sol.y[k-data.nbDepos] = -1
				sol.capacite[j] = sol.capacite[j] + data.demande[k-data.nbDepos]
				sol.z = sol.z - data.association[k-data.nbDepos, j]
			end
	else #k < data.nbDepos
		#on branche sur les depos
		#descente rapide avec la solution construite
		branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound)

		#exploration de l'autre possibilite
		if (0 == sol.x[k])
			sol.x[k] = 1
			sol.capacite[k] = data.capacite[k]
			sol.z = sol.z + data.ouverture[k]
			if completeRelax(mSSCFLP, data, solduale, sol, k, lowerbound, upperbound) < best.z
print("k = ",k," : ")
				if completesol(sol, data, k) && (sol.z < best.z)
					branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound)
				else
					reinit(sol, k+1, data)
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
print("k = ",k," : ")
				if completesol(sol, data, k) && (sol.z < best.z)
					branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound)
				else
					reinit(sol, k+1, data)
				end
			end
		end
	end
end
