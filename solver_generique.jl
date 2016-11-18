using JuMP
using GLPKMathProgInterface
using GLPK

mSSCFLP = Model(solver=GLPKSolverMIP())

# --- Indices, donnees, variables ---
x = []; y = [];
@variable(mSSCFLP, x[1:7], Bin) #ouverture facilité
@variable(mSSCFLP, y[1:20][1:7], Bin) #association

ouverture = [1,2,3,4,5,6,7]
association[20][7]
for i = 1:20
    for j = 1:7
        association[i][j] = 1
    end
end
capacite = [5,5,5,5,5,5,5]
demande = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]

# --- Modèle à résoudre, résolution ---

function doubleSomme(y, association, nbclient, nbdepos)
    sum = 0
    for i = 1:nbclient
        for j = 1:nbdepos
            sum = sum + y[i][j]*association[i][j]
        end
    end
    return sum
end

function demandeDepos(y, demande, nbclient, numDepos)
    sum = 0
    for i = 1:nbclient
        sum = sum + y[i][j]*demande[i][j]
    end
    return sum
end

function demandeClient(y, nbdepos, numClient)
    sum = 0
    for j = 1:nbdepos
        sum = sum + y[i][j]
    end
    return sum
end

@objective(mSSCFLP, Min, dot(ouverture, x) + doubleSomme(y, association, 20, 7))

for j = 1:7
    @constraint(mSSCFLP, demandeDepos(y, demande, 20, j) <= x[j]*capacite[j])
end

for i = 1:20
    @constraint(mSSCFLP, demandeClient(y, 7, i) == 1)
end

status = solve(mSSCFLP)

# Extraction des résultats ---
println("z = : ", getobjectivevalue(mSSCFLP))
for i = 1:20
    for j = 1:7
        print("$i ", getvalue(y[i][j]))
    end
    print("\n")
end
println("\n")
for j = 1:7
    print("$i ", getvalue(x[j]))
end
