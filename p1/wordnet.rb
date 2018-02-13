require_relative "graph.rb"

#NOTE: We may assume correct arg types
#However, it's still a good habit to check    	
class Synsets
	#Pattern to mach on our Synset lines
	#Compound assignment (||=) only assigns once
	@@pattern ||= /^id: (\d+) synset: ([\w]+[,\w+]*)+$/
	
    def initialize
    	@synsets = Hash.new
    	@synsets.default = []
    end

    def load(synsets_file)
    	if !File.exist? synsets_file
    		raise Exception, "Synsets: load: synsets_file does NOT exist"
    	elsif !File.file? synsets_file
    		raise Exception, "Synsets: load: synsets_file NOT a file"
    	else
    		file_lines = File.readlines(synsets_file)
    		res = processLines(file_lines)
    		if res.is_a? Hash
    			#All lines were valid
    			res.keys.each do |id|
    				if !addSet(id, res[id])
    					raise Exception, "Synsets: load: id: #{id} exists already!"
    				end
    			end
    			return nil #Everything was valid and was added
    		else
    			#One or more lines failed, no changes
    			return res
    		end
    	end
    end
    
    def processLines(file_lines)
    	success_lines = Hash.new
    	error_lines = []
    	index = 1
    	fail = false
    	file_lines.each { |line|
    		matched_line = @@pattern.match(line)
    		success = false
    		if matched_line.is_a? MatchData
    			id = matched_line[1].to_i
    			if lookup(id).empty?
    				if !success_lines[id].is_a? Array
    					synset = matched_line[2].split(',')
    					success_lines[id] = synset
    					success = true
    				end
    			end
    		end
    		if !success
    			#A previous line includes this ID, line invalid
    			#OR Synset already contains this ID, line invalid
    			#OR Failed to match on pattern, line invalid
    			error_lines.push(index)
    			fail = true
    		end
    		index = index + 1
    	}
    	if fail
    		return error_lines
    	else
    		return success_lines
    	end
    end

    def addSet(synset_id, nouns)
        if !synset_id.is_a? Integer
        	raise Exception, "Synsets: addSet: synset_id NOT an Integer!"
        elsif !nouns.is_a? Array
        	raise Exception, "Synsets: addSet: nouns NOT an Array!"
        elsif synset_id < 0
        	return false #synset_id is negative
        elsif nouns.empty?
        	return false #nouns is empty
        elsif !lookup(synset_id).empty?
        	return false #synset_id already exists
        else
        	@synsets[synset_id] = nouns
        	return true #added synset_id and nouns to synsets
        end
    end

    def lookup(synset_id)
        @synsets[synset_id]
    end

    def findSynsets(to_find)
    	if to_find.is_a? Array
    		res = Hash.new
    		res.default = []
    		#Go through all the words to find
    		to_find.each { |word|
    			id_arr = []
    			#Go through each Synset to see if word is an element
    			@synsets.keys.each do |synset_id|
    				nouns = @synsets[synset_id]
    				if nouns.include? word
    					id_arr.push(synset_id)
    				end
    			end
    			#Add all the ids which have that noun
    			res[word] = id_arr
    		}
    		#return hash with noun as key -> id as value
    		return res
    	elsif to_find.is_a? String
    		res = []
    		@synsets.select { |synset_id, nouns|
    			if nouns.include? to_find
    				res.push(synset_id)
    			end
    		}
    		#return array of 0 or more synset_ids containing this noun
    		return res
    	else
    		return nil #to_find not array or string, return nil
    	end
    end
    
    
    private :processLines
end

class Hypernyms
	#Pattern to mach on our Hypernym lines
	#Compound assignment (||=) only assigns once
	@@pattern ||= /^from: (\d+) to: ([\d]+[,\d+]*)+$/
	
    def initialize
    	#Use another hash, key as node, value as path/line/ancestor
    	@hypernyms = Graph.new
    end

    def load(hypernyms_file)
    	if !File.exist? hypernyms_file
    		raise Exception, "Hypernyms: load: hypernyms_file does NOT exist"
    	elsif !File.file? hypernyms_file
    		raise Exception, "Hypernyms: load: hypernyms_file NOT a file"
    	else
    		file_lines = File.readlines(hypernyms_file)
    		res = processLines(file_lines)
    		if res.is_a? Hash
    			res.keys.each do |from|
    				to_arr = res[from]
    				to_arr.each do |to|
    					if !addHypernym(from, to)
    						raise Exception, "Hypernyms: load: invalid: #{from} -> #{to}"
    					end
    				end
    			end
    			return nil #everything was valid and added
    		else
    			#At least one line failed, return line numbers
    			return res
    		end
    	end
    end
    
    def processLines(file_lines)
    	successLines = Hash.new{ [] }
    	error_lines = []
    	index = 1
    	fail = false
    	file_lines.each do |line|
    		matched_line = @@pattern.match(line)
    		success = false
    		if matched_line.is_a? MatchData
    			from = matched_line[1].to_i
    			to = matched_line[2].to_i
    			if from >= 0 && to >= 0
    				if !(from == to)
    					successLines[from] = successLines[from].push(to)
    					success = true
    				end
    			end
    		end
    		if !success
    			#A previous line includes this ID, line invalid
    			#OR Synset already contains this ID, line invalid
    			#OR Failed to match on pattern, line invalid
    			error_lines.push(index)
    			fail = true
    		end
    		index = index + 1
    	end
    	if fail
    		return error_lines
    	else
    		return successLines
    	end
    end

    def addHypernym(source, destination)
    	if !source.is_a? Integer
        	raise Exception, "Hypernyms: addHypernym: source NOT an Integer!"
        elsif !destination.is_a? Integer
        	raise Exception, "Hypernyms: addHypernym: destination NOT an Integer!"
        elsif source < 0 || destination < 0
        	return false #source or destination is negative
        elsif source == destination
        	return false #source and destination the same
        else
        	if !@hypernyms.hasVertex? source
        		@hypernyms.addVertex source
        	end
        	if !@hypernyms.hasVertex? destination
        		@hypernyms.addVertex destination
        	end
        	if !@hypernyms.hasEdge?(source, destination)
        		@hypernyms.addEdge(source, destination)
        	end
        	return true #valid edge added (if not duplicate)
        end
    end

    def lca(id1, id2)
    	if !@hypernyms.hasVertex?(id1) || !@hypernyms.hasVertex?(id2)
    		return nil #At least one id wasn't in our graph
    	elsif id1 == id2
    		return [id1]
    	else
    		distancesFromId1 = @hypernyms.bfs(id1)
    		nodesIn1 = []
    		distancesFromId2 = @hypernyms.bfs(id2)
    		addedDistances = Hash.new
    		addedDistances.default = -1
    		distancesFromId1.each do |node, distance|
    			nodesIn1.push(node)
    		end
    		distancesFromId2.each do |node, distance|
    			if nodesIn1.include? node
    				addedDistances[node] = distance
    			end
    		end
    		distancesFromId1.each do |node, distance|
    			if addedDistances[node] >= 0
    				addedDistances[node] += distance
    			end
    		end
    		lca = []
    		lcaDist = -1
    		addedDistances.keys.each do |id|
    			dist = addedDistances[id]
    			if dist < lcaDist || lcaDist < 0
    				lca = [id]
    				lcaDist = dist
    			elsif dist == lcaDist
    				lca.push(id)
    			end
    		end
    		return lca
    	end
    end
    
    private :processLines
end

class CommandParser
	@@loadPattern ||= /^\s*load\s+(\S+)\s+(\S+)\s*$/
    def initialize
        @synsets = Synsets.new
        @hypernyms = Hypernyms.new
    end

    def parse(command)
    	res = Hash.new
    	matchedLoad = @@loadPattern.match(command)
    	if matchedLoad.is_a? MatchData
    		synFile = matchedLoad[1]
    		hypFile = matchedLoad[2]
    		if !(@synsets.load(synFile) == nil) || !(@hypernyms.load(hypFile) == nil)
    			res[:recognized_command] = :load
    			res[:result] = :error
    		end
    		return res
    	end
    	res[:recognized_command] = :invalid
    	res[:result] = :invalid
    	return res
    end
end

