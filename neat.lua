connect_gene = {
            new = function(self, inn, out, weight, enabled, innov)
                inn = inn or 0
                out = out or 0
                weight = weight or 0
                enabled = enabled or false
                innov = innov or 0
                o = {}
                setmetatable(o, self)
                self.__index = self
                o.inn = inn
                o.out = out
                o.weight = weight
                o.enabled = enabled
                o.innov = innov
                return o
            end 
}

node_gene = {current_value = 0, previous_value = 0,
            new = function(self, id, ntype)
                id = id or 0
                ntype = ntype or 0
                o = {}
                setmetatable(o, self)
                self.__index = self
                o.id = id
                o.ntype = ntype
                return o
            end
}

--> Class for the genotype of an individual
genotype = {nodes = {}, connections = {},
            new = function(self)
                o = {}
                setmetatable(o, self)
                self.__index = self
                return o
            end,
            init = function(self, nin, nout, init_func, ...)
            for i = 1, nin do
               self.nodes[i] = node_gene:new(i, 1)
            end
            for i = 1, nout do
               self.nodes[i+nin] = node_gene:new(i+nin, 2)
            end
            counter = 1
            for i = 1, nin do
               for j = 1, nout do
                  self.connections[counter] = connect_gene:new(i, j+nin, init_func(...), true, counter)
                  counter = counter +1
               end
            end
            end,
            add_connection = function(self, inn, out, innovation, weight_func, ...)
                if self.nodes[out].ntype == 1 then return false end
                for i = 1, #self.connections do
                    print(self.connections[i].inn, self.connections[i].out, inn, out)
                    if self.connections[i].inn == inn and self.connections[i].out == out then return false end
                end
                self.connections[#self.connections+1] = connect_gene:new(inn, out, weight_func(...), true, innovation)
                return true
            end,
            add_node = function(self, connection, innovation, weight_func, ...)
                connection.enabled = false
                self.nodes[#self.nodes+1] = node_gene:new(#self.nodes+1, 3)
                self.connections[#self.connections+1] = connect_gene:new(connection.inn, self.nodes[#self.nodes].id, weight_func(...), true, innovation+1)
                self.connections[#self.connections+1] = connect_gene:new(self.nodes[#self.nodes].id, connection.out, weight_func(...), true, innovation+2)
            end,
            print = function(self)
                io.write("Nodes: \n")
                for i = 1, #self.nodes do
                    io.write(string.format("ID: %d\t Current value: %d\t Previous value: %d\t Type: %d\n", self.nodes[i].id, self.nodes[i].current_value, self.nodes[i].previous_value, self.nodes[i].ntype))
                end
                io.write("Connections: \n")
                for i = 1, #self.connections do
                    io.write(string.format("Inn node: %d\t Out node: %d\t Weight: %d\t Enabled: %s\t Innovation: %d\n", self.connections[i].inn, self.connections[i].out, self.connections[i].weight, self.connections[i].enabled, self.connections[i].innov))
                end
            end
}

--> Class for the phenotype of an individual
phenotype = {forward_connections = {}, recurrent_connections = {}, 
        new = function(self)
            o = {}
            setmetatable(o, self)
            self.__index = self
            return o
        end,
        creates_cycle = function (self, connections, con)
            if con.inn == con.out then return true end

            visited = {}
            visited[con.out] = true
            while(true) do
                num_added = 0
                for k, v in pairs(connections) do
                    print(v.inn, v.out, con.inn, con.out)
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
individual = {geno = {}, pheno = {}, fitness = 0,
            new = function(self, o, nin, nout, init_func, ...)
            o = o or {}
            setmetatable(o, self)
            self.__index = self
            o.geno = genotype:new()
            o.geno:init(nin, nout, init_func, ...)
            o.pheno = phenotype:new()
            return o
            end
}


--> Class for the population in the algorithm. Might be unnecessary and just have a normal table for this with no extra properties. 
population = {inds = {},
            new = function(self, o)
            o = o or {}
            setmetatable(o, self)
            self.__index = self
            return o
            end,
            init = function(self, pop, nin, nout, init_func, ...)
            for n = 1, pop do
                self.inds[n] = individual:new({}, nin, nout, init_func, ...)
            end
            end
}


function main_loop(generations, pop_size, crossover_rate, mutation_rate)
    generations = generations or 100; pop_size = pop_size or 50; crossover_rate = crossover_rate or 0.1; mutation_rate = mutation_rate or 0.1
    --> Generate initial population here:
    local pop = {}
    
    -->The main loop
    for i = 1, generations do
        -->evolutionary loop
    end
    return table.unpack(pop)
end
function mutation(ind)
end
function crossover(parent1, parent2)
end
function fitness(ind)
end
