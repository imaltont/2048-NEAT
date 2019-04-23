-->TODO Better selection algorithm
-->TODO Several activation functions, maybe as a thing that can be mutated for each node
-->TODO Better speciation (barely used atm). Current implementation almost nonspeciated, which is mentioned as being a lot worse in the paper. 
-->TODO Crossover using speciation at all
-->TODO Less weight on stagnated species
-->TODO Fix Crossover error (commented out)
-->TODO Clean code
-->TODO Other elitism (top of each species atm)
-->TODO Fix potential bugs
dofile"2048.lua"
math.randomseed(os.time())
connect_gene = {
            new = function(self)
                o = {}
                setmetatable(o, self)
                self.__index = self
                return o
            end,
            init = function(self, inn, out, weight, enabled, innov)
                self.inn = inn
                self.out = out
                self.weight = weight
                self.enabled = enabled
                self.innov = innov
            end
}

node_gene = {
            new = function(self)
                o = {}
                setmetatable(o, self)
                self.__index = self
                return o
            end,
            init = function (self, id, ntype)
                --self.current_value = 0
                --self.previous_value = 0
                self.id = id
                self.ntype = ntype
            end
}

--> Class for the genotype of an individual
genotype = {
            new = function(self)
                o = {}
                setmetatable(o, self)
                self.__index = self
                return o
            end,
            init = function(self, nin, nout, init_func, ...)
            self.nodes = {}
            self.connections = {}
            for i = 1, nin do
               self.nodes[i] = node_gene:new()
               self.nodes[i]:init(i, 1)
            end
            for i = 1, nout do
               self.nodes[i+nin] = node_gene:new()
               self.nodes[i+nin]:init(i+nin, 2)
            end
            counter = 1
            for i = 1, nin do
               for j = 1, nout do
                  self.connections[counter] = connect_gene:new()
                  self.connections[counter]:init(i, j+nin, init_func(...), true, counter)
                  counter = counter +1
               end
            end
            end,
            add_connection = function(self, inn, out, innovation, weight_func, ...)
                for i = 1, #self.nodes do
                    if self.nodes[i].id == out and self.nodes[i].ntype == 1 then return false end
                end
                for i = 1, #self.connections do
                    if self.connections[i].inn == inn and self.connections[i].out == out then return false end
                end
                self.connections[#self.connections+1] = connect_gene:new()
                self.connections[#self.connections]:init(inn, out, weight_func(...), true, innovation+1)
                return true
            end,
            add_node = function(self, connection, innovation, weight_func, ...)
                connection.enabled = false
                self.nodes[#self.nodes+1] = node_gene:new()
                self.nodes[#self.nodes]:init(#self.nodes, 3)
                self.connections[#self.connections+1] = connect_gene:new()
                self.connections[#self.connections]:init(connection.inn, self.nodes[#self.nodes].id, weight_func(...), true, innovation+1)
                self.connections[#self.connections+1] = connect_gene:new()
                self.connections[#self.connections]:init(self.nodes[#self.nodes].id, connection.out, weight_func(...), true, innovation+2)
            end,
            print = function(self)
                io.write("Nodes: \n")
                for i = 1, #self.nodes do
                    io.write(string.format("ID: %d\t Type: %d\n", self.nodes[i].id, self.nodes[i].ntype))
                end
                io.write("Connections: \n")
                for i = 1, #self.connections do
                    io.write(string.format("Inn node: %d\t Out node: %d\t Weight: %f\t Enabled: %s\t Innovation: %d\n", self.connections[i].inn, self.connections[i].out, self.connections[i].weight, self.connections[i].enabled, self.connections[i].innov))
                end
            end
}

--> Class for the phenotype of an individual
phenotype = {  
        new = function(self)
            o = {}
            setmetatable(o, self)
            self.__index = self
            return o
        end,
        init = function(self, nodes, connections)
            local nodes = nodes
            local connections = connections
            local all_cons = {}
            self.in_cons = {}
            for i = 1, #nodes do
                self.in_cons[nodes[i].id] = {node=nodes[i], recurrent_connections = {}, requires={}, weights={}, current_value = 0, previous_value = 0}
            end
            for i = 1, #connections do
                if connections[i].enabled == true then
                    if not self:creates_cycle(all_cons, connections[i]) then 
                        self.in_cons[connections[i].out].requires[1 + #self.in_cons[connections[i].out].requires] = connections[i].inn
                        self.in_cons[connections[i].out].weights[1 + #self.in_cons[connections[i].out].weights] = connections[i].weight
                    else
                        self.in_cons[connections[i].out].recurrent_connections[#self.in_cons[connections[i].out].recurrent_connections + 1] = connections[i]
                    end
                    all_cons[#all_cons+1] = connections[i]
                end
            end

        end,
        inference = function(self, input)
            visited = {}
            output_nodes = {}
            for k, v in pairs(self.in_cons) do
                if self.in_cons[k].node.ntype == 1 then
                    self.in_cons[k].current_value = input[k]
                elseif self.in_cons[k].node.ntype == 2 then
                    output_nodes[#output_nodes+1] = self.in_cons[k].node.id
                end
                if next(self.in_cons[k].requires) == nil then
                    visited[k] = true
                end
                for j = 1, #self.in_cons[k].recurrent_connections do
                    self.in_cons[k].current_value = self.in_cons[k].current_value + self.in_cons[self.in_cons[k].recurrent_connections[j].inn].previous_value
                end
            end

            for i = 1, #output_nodes do
                self:single_inference(output_nodes[i], visited)
            end

            outputs = {}
            for k, v in pairs(self.in_cons) do
                if self.in_cons[k].node.ntype == 2 then
                    outputs[#outputs+1] = self.in_cons[k].current_value
                end
                self.in_cons[k].previous_value = self.in_cons[k].current_value
                self.in_cons[k].current_value = 0
            end
            return outputs

        end,
        single_inference = function(self, node, visited)
            for i = 1, #self.in_cons[node].requires do
                if visited[self.in_cons[node].requires[i]] then
                    self.in_cons[node].current_value = self.in_cons[node].current_value + self.in_cons[node].weights[i] * self.in_cons[self.in_cons[node].requires[i]].current_value
                else
                    self:single_inference(self.in_cons[node].requires[i], visited)
                    self.in_cons[node].current_value = self.in_cons[node].current_value + self.in_cons[node].weights[i] * self.in_cons[self.in_cons[node].requires[i]].current_value
                end
            end
            if self.in_cons[node].node.ntype ~= 1 then
                self.in_cons[node].current_value = 1 / ( 1 + math.exp(-self.in_cons[node].current_value) )
            end
            visited[node] = true
        end,
        creates_cycle = function (self, connections, con)
            if con.inn == con.out then return true end

            visited = {}
            visited[con.out] = true
            while(true) do
                num_added = 0
                for k, v in pairs(connections) do
                    if visited[v.inn] and not visited[v.out] then 
                        if con.inn == v.out then return true end

                        visited[v.out] = true
                        num_added = num_added + 1
                    end

                end
                if num_added == 0 then return false end
            end
        end
        }

--> Class for the individual
individual = {
            new = function(self, o)
            o = o or {}
            setmetatable(o, self)
            self.__index = self
            return o
            end, 
            init = function(self, nin, nout, init_func, ...)
                self.geno = genotype:new()
                self.geno:init(nin, nout, init_func, ...)
                self.pheno = phenotype:new()
                self.pheno:init(self.geno.nodes, self.geno.connections)
                self.fitness = 0
                self.species = 0
            end
}


--> Class for the population in the algorithm. Might be unnecessary and just have a normal table for this with no extra properties. 
population = {
            new = function(self, o)
            o = o or {}
            setmetatable(o, self)
            self.__index = self
            return o
            end,
            init = function(self, pop, nin, nout, init_func, ...)
            self.inds = {}
            for n = 1, pop do
                self.inds[n] = individual:new()
                self.inds[n]:init(nin, nout, init_func, ...)
            end
        end
}

species = {
            new = function(self)
                o = {}
                setmetatable(o, self)
                self.__index = self
                return o
            end,
            init = function(self)
                self.inds = {}
                self.representative = {}
                self.num_inds = 0
                self.total_fit = 0
            end,
            add_ind = function(self, fitness, ind)
                self.total_fit = self.total_fit + fitness
                self.num_inds = self.num_inds + 1
                self.inds[#self.inds+1] = ind
            end
}

function main_loop(generations, pop_size, crossover_rate, enabled_mutation_rate, connection_mutation_rate, node_mutation_rate, weight_mutation_rate, input_size, output_size, species_threshold)
    --> Generate initial population here:
    local pop = population:new()
    local species_list = {}
    local mutation_list = {}
    local innovation = 1
    pop:init(pop_size, input_size, output_size, function() return math.random()*2 - 1 end)
    innovation = #pop.inds[1].geno.connections
    species_list[1] = species:new()
    species_list[1]:init()
    species_list[1].inds = pop.inds
    species_list[1].num_inds = #pop.inds
    
    -->The main loop
    for g = 1, generations do
        for v, k in pairs(species_list) do
            species_list[v].representative = species_list[v].inds[math.random(1, #species_list[v].inds)]
        end
        local temp_species = {}
        local temp_pop = {}
        local total_species = 0
        -->evolutionary loop
        for i=1, #pop.inds do
            pop.inds[i].fitness = fitness(pop.inds[i])
            local has_species = false
            for v, k in pairs(species_list) do
                if species_threshold > species_compare(pop.inds[i], species_list[v].representative) then
                    pop.inds[i].species = v
                    has_species = true
                    break
                end
            end
            if not has_species then
                total_species = total_species + 1
                pop.inds[i].species = total_species
            end

            if not temp_species[pop.inds[i].species] then
                temp_species[pop.inds[i].species] = species:new()
                temp_species[pop.inds[i].species]:init()
            end
            temp_species[pop.inds[i].species]:add_ind(pop.inds[i].fitness, pop.inds[i])
        end
        local reproduction_population = {}
        local counter = 0
        for k, v in pairs(temp_species) do
            counter = counter +1 
        end
        io.write(string.format("Number of species %d\n", counter))
        for k, v in pairs(temp_species) do
            table.sort(temp_species[k].inds, function (a, b) return a.fitness > b.fitness end)
            temp_pop[#temp_pop+1] = copy_individual(temp_species[k].inds[1])
            temp_pop[#temp_pop].pheno = phenotype:new()
            temp_pop[#temp_pop].pheno:init(temp_pop[#temp_pop].geno.nodes, temp_pop[#temp_pop].geno.connections)
            local n
            if temp_species[k].num_inds == 1 then n = 1
            else n = math.floor(temp_species[k].num_inds/2)
            end
            for j = 1, n do
                reproduction_population[#reproduction_population+1] = {ind = temp_species[k].inds[j], fitness = temp_species[k].inds[j].fitness / temp_species[k].num_inds}
            end
        end
        while #temp_pop < pop_size do
            local child = {}
            if math.random() < crossover_rate then
                local parent1 = reproduction_population[math.random(1, #reproduction_population)]
                local parent2 = reproduction_population[math.random(1, #reproduction_population)]

                local pc1, pc2 = reproduction_population[math.random(1, #reproduction_population)], reproduction_population[math.random(1, #reproduction_population)]
                if pc1.fitness >= pc2.fitness then
                    parent1 = pc1
                else
                    parent1 = pc2
                end
                pc1, pc2 = reproduction_population[math.random(1, #reproduction_population)], reproduction_population[math.random(1, #reproduction_population)]

                if pc1.fitness >= pc2.fitness then
                    parent2 = pc1
                else
                    parent2 = pc2
                end

                child = crossover(parent1, parent2)
            else
                child = copy_individual(reproduction_population[math.random(1, #reproduction_population)].ind)
            end
            if math.random() < enabled_mutation_rate then
                child = enable_mutation(child)
            end
            if math.random() < weight_mutation_rate then
                child = weight_mutation(child)
            end
            if math.random() < connection_mutation_rate then
                child, change = connection_mutation(child, innovation)
                if change then innovation = innovation + 1 end
            end
            if math.random() < node_mutation_rate then
                child = node_mutation(child, innovation)
                innovation = innovation + 2
            end
            child.pheno = phenotype:new()
            child.pheno:init(child.geno.nodes, child.geno.connections)
            temp_pop[#temp_pop+1] = child
        end
        table.sort(pop.inds, function (a, b) return a.fitness > b.fitness end)
        io.write(string.format("Generation: %d Best Fitness: %f\n", g, pop.inds[1].fitness))
        io.write(string.rep("-", 30))
        io.write("\n")
        species_list = temp_species
        pop.inds = temp_pop
    end
    for k, v in pairs(pop.inds) do
        pop.inds[k].fitness = fitness(pop.inds[k])
    end
    table.sort(pop.inds, function(a,b) return a.fitness > b.fitness end)
    return pop.inds
end
function species_compare(ind1, ind2)
    local N = math.max(#ind1.geno.connections, #ind2.geno.connections)
    local D = 0
    local E = 0
    local W = 0
    local trailing = 0
    local inno1 = {}
    local inno2 = {}
    for i = #ind1.geno.connections, 1, -1 do
        inno1[i] = {ind1.geno.connections[#ind1.geno.connections-i+1].innov, ind1.geno.connections[#ind1.geno.connections-i+1].weight}
        if i == 1 then trailing = inno1[i][1] end
    end
    for i = #ind2.geno.connections, 1, -1 do
        inno2[i] = {ind2.geno.connections[#ind2.geno.connections-i+1].innov, ind2.geno.connections[#ind2.geno.connections-i+1].weight}
        if i == 1 and inno2[i][1] > trailing then trailing = 2 elseif inno2[i][1] == trailing then trailing = 0 else trailing = 1 end
    end
    if trailing == 1 then
        E, D, W = dis_ex(inno1, inno2)
    else 
        E, D, W = dis_ex(inno2, inno1)
    end
    return E/N + D/N + W

end
function dis_ex(ind1_con, ind2_con)
    local excess = true
    local E = 0
    local D = 0
    local W = 0
    local matching = 0
    for i = 1, #ind1_con do
        local match = false
        for j = 1, #ind2_con do
            if ind1_con[i][1] > ind2_con[j][1] and excess == true then
                E = E + 1
                break
            elseif ind1_con[i][1] == ind2_con[j][1] then
                excess = false
                match = true
                matching = matching + 1
                W = W + math.abs(ind1_con[i][2], ind2_con[j][2])
                break
            else
                excess = false
            end
        end
        if not match and not excess then
            D = D + 1
        end
    end
    for i = 1, #ind2_con do
        local match = false
        for j = 1, #ind1_con do
            if ind2_con[i][1] == ind1_con[j][1] then
                match = true
                break
            end
        end
        if not match then 
            D = D + 1
        end
    end
    return E, D, W/matching
end
function enable_mutation(ind)
    index = math.random(1, #ind.geno.connections)
    ind.geno.connections[index].enabled = not ind.geno.connections[index].enabled
    return ind
end
function connection_mutation(ind, innov)
    local changed
    changed = ind.geno:add_connection(ind.geno.nodes[math.random(1, #ind.geno.nodes)].id, ind.geno.nodes[math.random(1, #ind.geno.nodes)].id, innov, function() return math.random()*2-1 end)
    return ind, changed
end
function node_mutation(ind, innov)
    ind.geno:add_node(ind.geno.connections[math.random(1, #ind.geno.connections)], innov, function() return math.random()*2-1 end)
    return ind
end
function weight_mutation(ind)
    index = math.random(1, #ind.geno.connections)
    if math.random() < 0.8 then
        ind.geno.connections[index].weight = ind.geno.connections[index].weight * math.random()*2
    else
        ind.geno.connections[index].weight = math.random()*2-1
    end
    return ind
end
function crossover(parent1, parent2)
    local child = {}
    local other_parent = {}
    local equal_parents = false
    if parent1.fitness > parent2.fitness then
        child = copy_individual(parent1.ind)
        other_parent = parent2.ind
    elseif parent1.fitness < parent2.fitness then
        child = copy_individual(parent2.ind)
        other_parent = parent1.ind
    else
        equal_parents = true
    end
    if not equal_parents then
        for i = 1, #child.geno.connections do
            local is_in_both = false
            local other_w, other_e
            for j = 1, #other_parent.geno.connections do
                if child.geno.connections[i].innov == other_parent.geno.connections[j].innov then
                    is_in_both = true
                    other_w = other_parent.geno.connections[j].weight
                    other_e = other_parent.geno.connections[j].enabled
                    break
                end
            end
            if is_in_both and math.random() < 0.5 then
                child.geno.connections[i].weight = other_w
                child.geno.connections[i].enabled = other_e
            end
        end
    else
        child = copy_individual(parent1.ind)
        for k, v in pairs(child.geno.connections) do
            local not_in_both = true
            for j = 1, #parent2.ind.geno.connections do
                if child.geno.connections[k].innov == parent2.ind.geno.connections[j].innov then
                    not_in_both = false
                    break
                end
            end
            if not_in_both and math.random() < 0.5 then
                --table.remove(child.geno.connections, k)
            end
        end
        for i = 1, #parent2.ind.geno.connections do
            local is_in_both = false
            local other_index
            for j = 1, #parent1.ind.geno.connections do 
                if parent2.ind.geno.connections[i].innov == parent1.ind.geno.connections[j].innov then
                    is_in_both = true
                    other_index = j
                    break
                end
            end
            if is_in_both then
                if math.random() < 0.5 then
                    child.geno.connections[other_index].weight = parent2.ind.geno.connections[i].weight
                    child.geno.connections[other_index].enabled = parent2.ind.geno.connections[i].enabled
                end
            else
                if math.random() < 0.5 then
                    local has_in_node = false
                    local has_out_node = false
                    local id = 0
                    for j = 1, #parent1.ind.geno.nodes do
                        if parent2.ind.geno.connections[i].inn == parent1.ind.geno.nodes[j].id then
                            has_in_node = true
                            id = parent2.ind.geno.connections[i].inn
                        elseif parent2.ind.geno.connections[i].out == parent1.ind.geno.nodes[j].id then
                            has_out_node = true
                            id = parent2.ind.geno.connections[i].out
                        end
                    end
                    if not has_in_node then
                        child.geno.nodes[#child.geno.nodes+1] = node_gene:new()
                        child.geno.nodes[#child.geno.nodes]:init(parent2.ind.geno.connections[i].inn, 3)
                    end
                    if not has_out_node then
                        child.geno.nodes[#child.geno.nodes+1] = node_gene:new()
                        child.geno.nodes[#child.geno.nodes]:init(parent2.ind.geno.connections[i].out, 3)
                    end
                    child.geno:add_connection(parent2.ind.geno.connections[i].inn, parent2.ind.geno.connections[i].out, parent2.ind.geno.connections[i].innov-1, function(a) return a end, parent2.ind.geno.connections[i].weight)
                end
            end
        end
    end
    return child
end
function fitness(ind)
    local total_fitness = 0
    local boards = 3
    local total_steps = 500
    for x = 1, boards do
    local outputs = {}
    local b = generate_board()
    local step = 1
    while has_moves(b) do
        outputs = ind.pheno:inference(flatten(b))
        local action = -1
        local failed = {}
        local has_moved = false
        while not has_moved and #failed ~= 4 do
            local prev_output_node = nil
            if action ~= -1 then failed[#failed+1] = action end
            for i = 1, #outputs do
                if not prev_output_node or outputs[i] > prev_output_node then
                    local has_failed = false
                    for f = 1, #failed do
                        if i == failed[f] then has_failed = true end
                    end
                    if not has_failed then
                        prev_output_node = outputs[i]
                        action = i
                    end
                end
            end
            if not move_tiles(action, b) then
            --    total_fitness = total_fitness - (1*(total_steps-step))
            else
                has_moved = true
            end
        end
        step = step + 1

    end
    --for i = 1, 4 do
    --    for j = 1, 4 do
    --        total_fitness = total_fitness + 2^b[1][i][j] * point_board[i][j]
    --    end
    --end
    max_board(b)
    total_fitness = total_fitness + b.score --* b.max  
    end
    return total_fitness / boards
end
function copy_individual(ind)
    local new_ind = individual:new()
    new_ind:init(0, 0, function(a) return a end, 0)
    for i = 1, #ind.geno.nodes do
        new_ind.geno.nodes[i] = node_gene:new()
--        new_ind.geno.nodes[i]:init(ind.geno.nodes[i].id, ind.geno.nodes[i].ntype)
        new_ind.geno.nodes[i].id = ind.geno.nodes[i].id
        new_ind.geno.nodes[i].ntype = ind.geno.nodes[i].ntype
    end
    for i = 1, #ind.geno.connections do
        new_ind.geno.connections[i] = connect_gene:new()
--        new_ind.geno.connections[i]:init(ind.geno.connections[i].inn, ind.geno.connections[i].out, ind.geno.connections[i].weight, ind.geno.connections[i].enabled, ind.geno.connections[i].innov)
        new_ind.geno.connections[i].inn = ind.geno.connections[i].inn
        new_ind.geno.connections[i].out = ind.geno.connections[i].out
        new_ind.geno.connections[i].weight = ind.geno.connections[i].weight
        new_ind.geno.connections[i].enabled = ind.geno.connections[i].enabled
        new_ind.geno.connections[i].innov = ind.geno.connections[i].innov
    end
    return new_ind
end
function play(ind)
    local b = generate_board()
    print_board(b)
    for k, v in pairs(ind.pheno.in_cons) do
        ind.pheno.in_cons[k].previous_value = 0
        ind.pheno.in_cons[k].current_value = 0
    end
    while has_moves(b) do
        local outputs = ind.pheno:inference(flatten(b))
        local action = -1
        local failed = {}
        while not move_tiles(action, b) and #failed ~= 4 do
            local prev_output_node = nil
            if action ~= -1 then failed[#failed+1] = action end
            for i = 1, #outputs do
                if not prev_output_node or outputs[i] > prev_output_node then
                    local has_failed = false
                    for f = 1, #failed do
                        if i == failed[f] then has_failed = true end
                    end
                    if not has_failed then
                        prev_output_node = outputs[i]
                        action = i
                    end
                end
            end
            --move_tiles(action, b)
        end
    end
    max_board(b)
    print_board(b)
end
function play_random()
    local b = generate_board()
    print_board(b)
    local actions = {1, 2, 3, 4}
    while has_moves(b) do
        move_tiles(actions[math.random(1, #actions)], b)
    end
    max_board(b)
    print_board(b)

end
