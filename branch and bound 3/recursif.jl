#= deja inclu par le main
include("relaxation.jl")
include("construction.jl")
include("utilitaires.jl")=#

function branchandbound(mSSCFLP::Model, sol::solution, solduale::solutionrelache, data::instance, k::Int64, best::solution, lowerbound::tabConstaint, upperbound::tabConstaint, etat::Bool)
for i=1:k-1
	print("\t")
end
println("k = ",k," sol : ",sol.x," ",sol.y," ",sol.z)

	if (k > data.nbDepos + data.nbClients) #solution complete
		if (sol.z < best.z)
			recopie(sol, best) #on sauvegarde la solution comme meilleure actuelle
			println("new best : ", best)
		end
	elseif (k > data.nbDepos) #on branche sur les clients
		#deja teste
		dejatest = Array{Int64,1}()

		if (etat)#descente rapide avec la solution construite
			branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, true)

			#enregistrement de ce que l'on vien de tester
			push!(dejatest, sol.y[k-data.nbDepos])

			#remise a l'etat par defaut
			sol.capacite[sol.y[k-data.nbDepos]] = sol.capacite[sol.y[k-data.nbDepos]] + data.demande[k-data.nbDepos]
			sol.z = sol.z - data.association[k-data.nbDepos, sol.y[k-data.nbDepos]]
			sol.y[k-data.nbDepos] = -1
		end

		#on cherche l'ensemble des depos ouvert auquel on peu associer ce clients
		possible = Array{Int64,1}()
		if (:Optimal == completeRelaxClient(mSSCFLP, data, solduale, sol, lowerbound, upperbound, dejatest, k))
			for j=1:data.nbDepos
				if (data.demande[k-data.nbDepos] <= sol.capacite[j]) && (getvalue(solduale.y[k-data.nbDepos, j]) > 0.0001) && (sol.z + data.association[k-data.nbDepos,j] < best.z)
					push!(possible, j)
				end
			end
		end

		while ! isempty(possible)
			#triPos(possible, data.association, k-data.nbDepos)
			#triRelache(possible, solduale, k-data.nbDepos)

			#on teste toutes les association possibles interesante
			for j in possible
				sol.y[k-data.nbDepos] = j
				sol.capacite[j] = sol.capacite[j] - data.demande[k-data.nbDepos]
				sol.z = sol.z + data.association[k-data.nbDepos,j]
				if completeRelax(mSSCFLP, data, solduale, sol, k, lowerbound, upperbound) < best.z
					if completesol(sol, data, k)
						branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, true)
					else
						reinit(sol, k+1, data)
						branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, false)
					end
				end
				sol.y[k-data.nbDepos] = -1
				sol.capacite[j] = sol.capacite[j] + data.demande[k-data.nbDepos]
				sol.z = sol.z - data.association[k-data.nbDepos, j]

				#sauvegarde de ce que l'on vien de tester
				push!(dejatest, j)
			end

			#on cherche l'ensemble des depos ouvert auquel on peu associer ce clients
			possible = Array{Int64,1}()

			#relaxation avec interdiction de ce qui a deja ete tester
			if (:Optimal == completeRelaxClient(mSSCFLP, data, solduale, sol, lowerbound, upperbound, dejatest, k))
				for j=1:data.nbDepos
					if (data.demande[k-data.nbDepos] <= sol.capacite[j]) && (getvalue(solduale.y[k-data.nbDepos, j]) > 0.0001) && (sol.z + data.association[k-data.nbDepos,j] < best.z)
						push!(possible, j)
					end
				end
			end

		end

	else #k < data.nbDepos
		#on branche sur les depos
		if (etat)#descente rapide avec la solution construite
			branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, true)
		else
			#on regarde quelle importance la relaxation donne a cette facilite
			completeRelaxDepos(mSSCFLP, data, solduale, sol, lowerbound, upperbound, k)

			if (getvalue(solduale.x[k]) < 0.5)
				sol.x[k] = 0
				sol.capacite[k] = 0
				if completeRelax(mSSCFLP, data, solduale, sol, k, lowerbound, upperbound) < best.z
					if completesol(sol, data, k)
						branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, true)
					else
						reinit(sol, k+1, data)
						branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, false)
					end
				end
			else
				sol.x[k] = 1
				sol.capacite[k] = data.capacite[k]
				sol.z = sol.z + data.ouverture[k]
				if completeRelax(mSSCFLP, data, solduale, sol, k, lowerbound, upperbound) < best.z
					if completesol(sol, data, k)
						branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, true)
					else
						reinit(sol, k+1, data)
						branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, false)
					end
				end
			end
		end

		#exploration de l'autre possibilite
		if (0 == sol.x[k])
			sol.x[k] = 1
			sol.capacite[k] = data.capacite[k]
			sol.z = sol.z + data.ouverture[k]
			if completeRelax(mSSCFLP, data, solduale, sol, k, lowerbound, upperbound) < best.z
				if completesol(sol, data, k)
					branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, true)
				else
					reinit(sol, k+1, data)
					branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, false)
				end
			end
			sol.x[k] = 0 #remise en etat : par defaut une facilite est ferme
			sol.z = sol.z - data.ouverture[k]
			sol.capacite[k] = 0
		else#if (1 == sol.x[k])
			sol.x[k] = 0
			sol.capacite[k] = 0
			sol.z = sol.z - data.ouverture[k]
			if completeRelax(mSSCFLP, data, solduale, sol, k, lowerbound, upperbound) < best.z
				if completesol(sol, data, k)
					branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, true)
				else
					reinit(sol, k+1, data)
					branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, false)
				end
			end
		end
	end
end
