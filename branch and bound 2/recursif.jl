#retourne l'indice de la première variable non fixe
function rechercheBranch(solduale::solutionrelache, data::instance)
	res = 0
	flag = false
	while (res < data.nbDepos + data.nbClients) && (!flag)
		res += 1

		if (res < data.nbDepos)
			flag = (getvalue(solduale.x[res]) > 0.0001) && (getvalue(solduale.x[res]) < 0.9999) #la variable n'est pas fixe
		else
			j = 1
			#si l'une d'elle est a 1 alors elle est fixé donc on s'arette
			while (j <= data.nbDepos) && (!flag) && (getvalue(solduale.y[res-data.nbDepos,j]) < 0.9999)
				flag = (getvalue(solduale.y[res-data.nbDepos,j]) > 0.0001) #la variable n'est pas fixe
			end
		end

	end
	return res
end

function branchandbound(mSSCFLP::Model, sol::solution, solduale::solutionrelache, data::instance, k::Int64, best::solution, lowerbound::tabConstaint, upperbound::tabConstaint)

end
