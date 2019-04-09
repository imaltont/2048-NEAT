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

node_gene = {current_value = 0,
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
			new = function(self, o)
				o = o or {}
				setmetatable(o, self)
				self.__index = self
				return o
			end
}

--> Class for the phenotype of an individual
phenotype = {}

--> Class for the individual
individual = {geno = {}, pheno = {}, fitness = 0,
			new = function(self, o, nin, nout)
				o = o or {}
				setmetatable(o, self)
				self.__index = self
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
			init = function(self, pop, nin, nout)
				for n in pop do
					self.inds[n] = individual:new({}, nin, nout)
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
