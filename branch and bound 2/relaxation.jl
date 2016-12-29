function relaxinit(mSSCFLP::Model, data::instance, solduale::solutionrelache, lowerbound::tabConstaint, upperbound::tabConstaint)
	#variables
    solduale.x = @variable(mSSCFLP, x[1:data.nbDepos])
    solduale.y = @variable(mSSCFLP, y[1:data.nbClients,1:data.nbDepos])
    #solduale.e = @variable(mSSCFLP, 1 >= y[1:data.nbClients,1:data.nbDepos] >= 0)

    #fonction eco relaxe
    @objective(mSSCFLP, Min, sum(data.ouverture[j] * x[j] + sum( y[i,j] * data.association[i,j] for i=1:data.nbClients ) for j=1:data.nbDepos))

    #contraites de borne, ecrite à la main pour pouvoir les modifier
    for j=1:data.nbDepos
        push!(lowerbound, @constraint(mSSCFLP, x[j] >= 0) )
        push!(upperbound, @constraint(mSSCFLP, x[j] <= 1) )
    end
    for i=1:data.nbClients
        for j=1:data.nbDepos
            push!(lowerbound, @constraint(mSSCFLP, y[i,j] >= 0) )
            push!(upperbound, @constraint(mSSCFLP, y[i,j] <= 1) )
        end
    end

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

    return solduale.z
end

function completeRelax(mSSCFLP::Model, data::instance, solduale::solutionrelache, sol::solution, lowerbound, upperbound)
    compt = 1 #pour sovoir ou l'on en est dans les tableaux de contraintes

    #ouverture/fermueture des depos
	for j=1:data.nbDepos
        if (-1 != sol.x[j]) #depos fixe
            JuMP.setRHS(lowerbound[compt], sol.x[j])
            JuMP.setRHS(upperbound[compt], sol.x[j])
        else #ou pas
            JuMP.setRHS(lowerbound[compt], 0)
            JuMP.setRHS(upperbound[compt], 1)
        end
        compt = compt +1
	end

	#association des clients
	for i=1:data.nbClients
		for j=1:data.nbDepos
            if (-1 != sol.y[i]) #depos fixe pour ce client
    			if (j == sol.y[i])
                    JuMP.setRHS(lowerbound[compt], 1)
                    JuMP.setRHS(upperbound[compt], 1)
    			else
                    JuMP.setRHS(lowerbound[compt], 0)
                    JuMP.setRHS(upperbound[compt], 0)
    			end
            else #ou pas
                JuMP.setRHS(lowerbound[compt], 0)
                JuMP.setRHS(upperbound[compt], 1)
            end
            compt = compt +1
		end
	end

	#resolution
    solve(mSSCFLP; suppress_warnings=true, relaxation=true)

    #extraction des resultats
    solduale.z = getobjectivevalue(mSSCFLP)



    return solduale.z
end
