function rechercheBranch(solduale::solutionrelache, data::instance)
	flag = false #indique si on a trouve une variable non binaire
	res = 1 #parcour des indices
	while !flag && (res <= data.nbDepos + data.nbClients)

		if (res <= data.nbDepos) #si cet indice est un depos
			flag = (getvalue(solduale.x[res]) > 0.0001) && (getvalue(solduale.x[res]) < 0.9999)
		else #si c'est un client
			j = 1
			#si l'une d'elle est a 1 alors elle est fixé donc on s'arette
			while (j <= data.nbDepos) && (!flag) && (getvalue(solduale.y[res-data.nbDepos,j]) < 0.9999)
				flag = (getvalue(solduale.y[res-data.nbDepos,j]) > 0.0001) #la variable n'est pas fixe
				j += 1
			end

		end

		res += 1
	end

	if flag
		return res -1
	else
		return -1
	end

end

function branchandbound(mSSCFLP::Model, sol::solution, solduale::solutionrelache, data::instance, k::Int64, best::solution, lowerbound::tabConstaint, upperbound::tabConstaint, etat::Bool)
#println("k = ",k," sol : ",sol.x," ",sol.y," ",sol.z," ",sol.capacite," ",etat)
copie = solution([], [], [], 0)
initialise(data, copie)
	if (k > data.nbDepos + data.nbClients) #on a fini de descendre
		completeRelax(mSSCFLP, data, solduale, sol, lowerbound, upperbound)
		branchandbound(mSSCFLP, sol, solduale, data, rechercheBranch(solduale, data), best, lowerbound, upperbound, false)
	elseif (-1 == k) #plus de variable non binaire
		completeRelax(mSSCFLP, data, solduale, sol, lowerbound, upperbound)
		asignvalrelax(copie, solduale, sol, data)
		if (copie.z < best.z)
			recopie(copie, best)
println("new best : ",best)
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
				if completeRelax(mSSCFLP, data, solduale, sol, lowerbound, upperbound) < best.z
					recopie(sol, copie)
					if completesol(copie, data, k)
						branchandbound(mSSCFLP, copie, solduale, data, k+1, best, lowerbound, upperbound, true)
					else
						branchandbound(mSSCFLP, sol, solduale, data, rechercheBranch(solduale, data), best, lowerbound, upperbound, false)
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
			#completeRelaxDepos(mSSCFLP, data, solduale, sol, lowerbound, upperbound, k)

			#si on souhaite commencer par la solution la plus probable
			#if (getvalue(solduale.x[k]) < 0.5)
				sol.x[k] = 0
				sol.capacite[k] = 0
				if completeRelax(mSSCFLP, data, solduale, sol, lowerbound, upperbound) < best.z
					recopie(sol, copie)
					if completesol(copie, data, k)
						branchandbound(mSSCFLP, copie, solduale, data, k+1, best, lowerbound, upperbound, true)
					else
						branchandbound(mSSCFLP, sol, solduale, data, rechercheBranch(solduale, data), best, lowerbound, upperbound, false)
					end
				end
			#=else
				sol.x[k] = 1
				sol.capacite[k] = data.capacite[k]
				sol.z = sol.z + data.ouverture[k]
				if completeRelax(mSSCFLP, data, solduale, sol, lowerbound, upperbound) < best.z
					if completesol(sol, data, k)
						branchandbound(mSSCFLP, sol, solduale, data, k+1, best, lowerbound, upperbound, true)
					else
						branchandbound(mSSCFLP, sol, solduale, data, rechercheBranch(solduale, data), best, lowerbound, upperbound, false)
					end
				end
			end=#
		end

		#exploration de l'autre possibilite
		if (0 == sol.x[k])
			sol.x[k] = 1
			sol.capacite[k] = data.capacite[k]
			sol.z = sol.z + data.ouverture[k]
			if completeRelax(mSSCFLP, data, solduale, sol, lowerbound, upperbound) < best.z
				recopie(sol, copie)
				if completesol(copie, data, k)
					branchandbound(mSSCFLP, copie, solduale, data, k+1, best, lowerbound, upperbound, true)
				else
					branchandbound(mSSCFLP, sol, solduale, data, rechercheBranch(solduale, data), best, lowerbound, upperbound, false)
				end
			end
			sol.x[k] = -1 #remise en etat par defaut
			sol.z = sol.z - data.ouverture[k]
			sol.capacite[k] = 0
		else#if (1 == sol.x[k])
			sol.x[k] = 0
			sol.capacite[k] = 0
			sol.z = sol.z - data.ouverture[k]
			if completeRelax(mSSCFLP, data, solduale, sol, lowerbound, upperbound) < best.z
				recopie(sol, copie)
				if completesol(copie, data, k)
					branchandbound(mSSCFLP, copie, solduale, data, k+1, best, lowerbound, upperbound, true)
				else
					branchandbound(mSSCFLP, sol, solduale, data, rechercheBranch(solduale, data), best, lowerbound, upperbound, false)
				end
			end
			sol.x[k] = -1 #remise en etat par defaut
		end
	end
end



function asignvalrelax(best::solution, solduale::solutionrelache, sol::solution, data::instance)
	best.z = sol.z

	for j = 1:data.nbDepos
		if (-1 == sol.x[j])
		    if (getvalue(solduale.x[j]) < 0.0001)
		        best.x[j] = 0
		    else#if (getvalue(solduale.x[j]) > 0.9999)
		        best.x[j] = 1
				best.z += data.ouverture[j]
				best.capacite = data.capacite[j]
		    end
		else
			best.x[j] = sol.x[j]
			best.capacite[j] = sol.capacite[j]
		end
	end

	for i = 1:data.nbClients
		if (-1 == sol.y[i])
		    for j = 1:data.nbDepos
		        if (getvalue(solduale.y[i,j]) > 0.9999)
		            best.y[i] = j
					best.z += data.association[i,j]
					best.capacite[j] -= data.demande[i]
				end
		    end
		else
			best.y[i] = sol.y[i]
		end
	end
end
