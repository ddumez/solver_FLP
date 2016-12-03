include("relaxation.jl")
include("construction.jl")

function branchandbound(mSSCFLP::Model, sol::solution, solduale::solutionrelache, data::instance, k::Int64, best::solution, lowerbound, upperbound)
#println("k = ",k)
	if (k > data.nbDepos + data.nbClients)
		if (sol.z < best.z)
			recopie(sol, best) #on sauvegarde la solution comme meilleure actuelle
		end
	elseif (k > data.nbDepos)
		#on branche sur les clients
			#on cherche l'ensemble des depos ouvert auquel on peu associer ce clients
			possible = Set{Int64}();
			for j=1:data.nbDepos
				if (data.demande[k-data.nbDepos] <= sol.capacite[j])
					push!(possible, j)
				end
			end

		#on teste toutes les association possibles
			for j in possible
				sol.y[k-data.nbDepos] = j
				sol.capacite[j] = sol.capacite[j] - data.demande[k-data.nbDepos]
				sol.z = sol.z + data.association[k-data.nbDepos,j]
				if completeRelax(mSSCFLP, data, solduale, sol, k, lowerbound, upperbound) < best.z
					branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound)
				end
				sol.capacite[j] = sol.capacite[j] + data.demande[k-data.nbDepos]
				sol.z = sol.z - data.association[k-data.nbDepos, j]
			end
	else
		#on branche sur les depos

		sol.x[k] = 0
		if completeRelax(mSSCFLP, data, solduale, sol, k, lowerbound, upperbound) < best.z
			branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound)
		end

		sol.x[k] = 1
		sol.capacite[k] = data.capacite[k]
		sol.z = sol.z + data.ouverture[k]
		if completeRelax(mSSCFLP, data, solduale, sol, k, lowerbound, upperbound) < best.z
			branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound)
		end
		sol.z = sol.z - data.ouverture[k]
		sol.capacite[k] = 0
	end
end
