#retourne l'indice de la première variable non binaire
function rechercheBranch(solduale::solutionrelache, data::instance)
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

end

function branchandbound(mSSCFLP::Model, sol::solution, solduale::solutionrelache, data::instance, k::Int64, best::solution, lowerbound::tabConstaint, upperbound::tabConstaint)
if (k == 26)
println("\n\nk = ",k," : ",sol.x," ; ",sol.y," : ",sol.capacite)
println(mSSCFLP)
println("valeur de la relaxation = : ", getobjectivevalue(mSSCFLP))
for i = 1:data.nbClients
	for j = 1:data.nbDepos
		if (getvalue(solduale.y[i,j]) < 0.0001)
			print("0 ")
		elseif (getvalue(solduale.y[i,j]) > 0.9999)
			print("1 ")
		else
			print(getvalue(solduale.y[i,j])," ")
		end
	end
	print("\n")
end
println("\n")
for j = 1:data.nbDepos
	if (getvalue(solduale.x[j]) < 0.0001)
		print("0 ")
	elseif (getvalue(solduale.x[j]) > 0.9999)
		print("1 ")
	else
		print(getvalue(solduale.x[j])," ")
	end
end
println("")
end
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
		#on cherche l'ensemble des depos ouvert auquel on peu associer ce clients
		possible = Array{Int64,1}()
		for j=1:data.nbDepos
			if (data.demande[k-data.nbDepos] <= sol.capacite[j]) && (getvalue(solduale.y[k-data.nbDepos, j]) > 0.0001)
				push!(possible, j)
			end
		end
if k == 26
println("possible : ",possible)
end
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
