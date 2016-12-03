function relaxinit(mSSCFLP::Model, data::instance, solduale::solutionrelache)
	#variables
    solduale.x = @variable(mSSCFLP, 1 >= x[1:data.nbDepos] >= 0)
    solduale.y = @variable(mSSCFLP, 1 >= y[1:data.nbClients,1:data.nbDepos] >= 0)
    #solduale.e = @variable(mSSCFLP, 1 >= y[1:data.nbClients,1:data.nbDepos] >= 0)

    #fonction eco relaxe
    @objective(mSSCFLP, Min, sum(data.ouverture[j] * x[j] + sum( y[i,j] * data.association[i,j] for i=1:data.nbClients ) for j=1:data.nbDepos))

    #contraintes relaxe
    for j = 1:data.nbDepos
        @constraint(mSSCFLP, sum(y[i,j] * data.demande[i] for i=1:data.nbClients) <= data.capacite[j]*x[j])
        for i = 1:data.nbClients #contrainte redondante de Holmberg
            @constraint(mSSCFLP, y[i,j] <= x[j])
        end
    end
    for i = 1:data.nbClients
        @constraint(mSSCFLP, sum(y[i,j] for j=1:data.nbDepos) == 1)
    end

	#resolution
    solve(mSSCFLP; suppress_warnings=true, relaxation=false)

    #extraction des resultats
    solduale.z = getobjectivevalue(mSSCFLP)

end

function completeRelax(mSSCFLP::Model, data::instance, solduale::solutionrelache, sol::solution, k::Int64)

	if (k >= data.nbDepos)
		#on force l'ouverture/fermueture des depos
		for j=1:data.nbDepos
			setlowerbound(solduale.x[j], sol.x[j])
			setupperbound(solduale.x[j], sol.x[j])
		end

		#on force les association que l'on a deja choisis
		i = 1
		while (i <= k - data.nbDepos)
			for j=1:data.nbDepos
				if (j == sol.y[i])
					setlowerbound(solduale.y[i,j], 1)
					setupperbound(solduale.y[i,j], 1)
				else
					setlowerbound(solduale.y[i,j], 0)
					setupperbound(solduale.y[i,j], 0)
				end
			end
			i = i+1
		end

		#on laisse les autres libre
		while (i <= data.nbDepos)
			for j=1:data.nbDepos
				setupperbound(solduale.y[i,j], 1)
				setlowerbound(solduale.y[i,j], 0)
			end
			i = i+1
		end		
	else 
		#on force les depos choisis
		for j=1:k
			setlowerbound(solduale.x[j], sol.x[j])
			setupperbound(solduale.x[j], sol.x[j])
		end

		#on laisse les autres libre
		for j=(k+1):data.nbDepos
			setupperbound(solduale.x[j], 1)
			setlowerbound(solduale.x[j], 0)
		end

		#toutes les variables sont libres
		for i = 1:data.nbClients
			for j = 1:data.nbDepos
				setupperbound(solduale.y[i,j], 1)
				setlowerbound(solduale.y[i,j], 0)
			end
		end
	end

	#resolution
    solve(mSSCFLP; suppress_warnings=true, relaxation=false)

    #extraction des resultats
    solduale.z = getobjectivevalue(mSSCFLP)
	
end