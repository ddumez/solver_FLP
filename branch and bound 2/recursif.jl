#retourne l'indice de la première variable non binaire
#=function rechercheBranch(solduale::solutionrelache, data::instance)
	possible = Array{Int64,1}()
	res = 1
	for res = 1:(data.nbDepos + data.nbClients)

		if (res <= data.nbDepos)
			if (getvalue(solduale.x[res]) > 0.0001) && (getvalue(solduale.x[res]) < 0.9999)
				push!(possible, res)
			end
		else
			j = 1
			flag = false
			#si l'une d'elle est a 1 alors elle est fixé donc on s'arette
			while (j <= data.nbDepos) && (!flag) && (getvalue(solduale.y[res-data.nbDepos,j]) < 0.9999)
				flag = (getvalue(solduale.y[res-data.nbDepos,j]) > 0.0001) #la variable n'est pas fixe
				j += 1
			end

			if flag
				push!(possible, res)
			end
		end

		res += 1
	end

	if 0 != size(possible)[1]
		triebranch(possible, solduale, data)
		return possible[1]
	else
		return -1
	end

end=#
function rechercheBranch(solduale::solutionrelache, data::instance)
	flag = false
	res = 1
	while !flag && (res <= data.nbDepos + data.nbClients)

		if (res <= data.nbDepos)
			flag = (getvalue(solduale.x[res]) > 0.0001) && (getvalue(solduale.x[res]) < 0.9999)
		else
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

function branchandbound(mSSCFLP::Model, sol::solution, solduale::solutionrelache, data::instance, k::Int64, best::solution, lowerbound::tabConstaint, upperbound::tabConstaint)
println("k = ",k," ",sol)
	if -1 == k #plus de variable non binaire
		asignvalrelax(best, solduale, sol, data)
println("new best : ", best)
	elseif (k <= data.nbDepos) #on branche sur un depos
		if (getvalue(solduale.x[k]) < 0.5) #on commence par le mettre à 0

			sol.x[k] = 0
			if completeRelax(mSSCFLP, data, solduale, sol, lowerbound, upperbound) < best.z
				branchandbound(mSSCFLP, sol, solduale, data, rechercheBranch(solduale, data), best, lowerbound, upperbound)
			end

			#ensuite on le met a 1
			sol.x[k] = 1
			sol.capacite[k] = data.capacite[k]
			sol.z = sol.z + data.ouverture[k]
			if completeRelax(mSSCFLP, data, solduale, sol, lowerbound, upperbound) < best.z
				branchandbound(mSSCFLP, sol, solduale, data, rechercheBranch(solduale, data), best, lowerbound, upperbound)
			end

			#remise en etat par defaut
			sol.x[k] = -1
			sol.z = sol.z - data.ouverture[k]
			sol.capacite[k] = 0
		else #ou a 1
			sol.x[k] = 1
			sol.capacite[k] = data.capacite[k]
			sol.z = sol.z + data.ouverture[k]
			if completeRelax(mSSCFLP, data, solduale, sol, lowerbound, upperbound) < best.z
				branchandbound(mSSCFLP, sol, solduale, data, rechercheBranch(solduale, data), best, lowerbound, upperbound)
			end

			#ensuite on le met a 0
			sol.x[k] = 0
			sol.z = sol.z - data.ouverture[k]
			sol.capacite[k] = 0
			if completeRelax(mSSCFLP, data, solduale, sol, lowerbound, upperbound) < best.z
				branchandbound(mSSCFLP, sol, solduale, data, rechercheBranch(solduale, data), best, lowerbound, upperbound)
			end

			#remise en etat par defaut
			sol.x[k] = -1
		end

	else #on branche sur un client
		#deja teste
		dejatest = Array{Int64,1}()

		#on cherche l'ensemble des depos ouvert auquel on peu associer ce clients
		possible = Array{Int64,1}()
		for j=1:data.nbDepos
			if (data.demande[k-data.nbDepos] <= sol.capacite[j]) && (getvalue(solduale.y[k-data.nbDepos, j]) > 0.0001)
				push!(possible, j)
			end
		end

		while ! isempty(possible)
			#triPos(possible, data.association, k-data.nbDepos)
			#triRelache(possible, solduale, k-data.nbDepos)

			#on teste toutes les association possibles
			for j in possible
				sol.y[k-data.nbDepos] = j
				sol.capacite[j] = sol.capacite[j] - data.demande[k-data.nbDepos]
				sol.z = sol.z + data.association[k-data.nbDepos,j]
				if completeRelax(mSSCFLP, data, solduale, sol, lowerbound, upperbound) < best.z
					branchandbound(mSSCFLP, sol, solduale, data, rechercheBranch(solduale, data), best, lowerbound, upperbound)
				end
				sol.y[k-data.nbDepos] = -1
				sol.capacite[j] = sol.capacite[j] + data.demande[k-data.nbDepos]
				sol.z = sol.z - data.association[k-data.nbDepos, j]

				#sauvegarde de ce que l'on vien de tester
				push!(dejatest, j)
			end

			#relaxation avec interdiction de ce qui a deja ete tester
			completeRelaxClient(mSSCFLP, data, solduale, sol, lowerbound, upperbound, dejatest, k)

			#on cherche l'ensemble des depos ouvert auquel on peu associer ce clients
			possible = Array{Int64,1}()
			for j=1:data.nbDepos
				if (data.demande[k-data.nbDepos] <= sol.capacite[j]) && (getvalue(solduale.y[k-data.nbDepos, j]) > 0.0001)
					push!(possible, j)
				end
			end

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
