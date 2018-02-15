require_relative "graph.rb"

#NOTE: We may assume correct arg types  	
class Synsets
	#Pattern to mach on our Synset lines
	#Compound assignment (||=) only assigns once
	@@pattern ||= /^id: (\d+) synset: ([,?[\w|\-|\.|\/|\']+]+)+$/

	def initialize
		@synsets = Hash.new{ [] }
	end

	def load(synsets_file)
		testRes = testLoad(synsets_file)
		#empty file, no lines
		if testRes.empty?
			return nil
		elsif testRes[0].is_a? Integer #error, only line nums
			return testRes
		else
			#all valid, add all lines
			testRes.each {|data|
				id = data[0]
				nouns = data[1]
				addSet(id, nouns)
			}
			return nil
		end
    end

	def addSet(synset_id, nouns)
		#check if set is valid, then add
		if validSetToAdd?(synset_id, nouns)
        	@synsets[synset_id] = nouns
        	return true #added synset_id and nouns to synsets
		else
			return false #not valid
        end
    end

    def lookup(synset_id)
        return @synsets[synset_id]
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
    
	#HELPER parses each line using our pattern
	def parse(line) #String -> Array OR Nil
		matchedLine = @@pattern.match(line)
		if matchedLine.is_a? MatchData
			id = matchedLine[1].to_i
			synset = matchedLine[2].split(',')
			return [id,synset]
		end
		return nil #Line is invalid format
	end

	#HELPER checks for set validity
	def validSetToAdd?(id, nouns) #(Integer, Array) -> Boolean
		if id < 0 || nouns.empty? || !(lookup(id).empty?)
			return false #id negative, no nouns, id already exists
		end
		return true #Valid
	end

	#HELPER performs load, minus altering data
	def testLoad(synsets_file) #String -> Array
		fileLines = File.readlines(synsets_file)
		parsedLines = fileLines.map {|line|
			parse(line)
		}
		indexArr = []
		invalidLines = parsedLines.each_with_index.map {|data, index|
			if data == nil
				index + 1
			else
				id = data[0]
				nouns = data[1]
				if !(validSetToAdd?(id, nouns)) || indexArr.include?(id)
					index + 1
				else
					indexArr.push(id)
					nil
				end
			end
		}.compact
		
		if !invalidLines.empty?
			return invalidLines
		end
		return parsedLines
	end
end

#NOTE: We may assume correct arg types
class Hypernyms
	#Pattern to mach on our Hypernym lines
	#Compound assignment (||=) only assigns once
	@@pattern ||= /^from: (\d+) to: ([,?\d+]+)+$/
	
    def initialize
    	@hypernyms = Graph.new
    end

    def load(hypernyms_file)
		testRes = testLoad(hypernyms_file)
		#empty file, no lines
		if testRes.empty?
			return nil
		elsif testRes[0].is_a? Integer #error, only line nums
			return testRes
		else
			#all valid, add all lines
			testRes.each {|data|
				src = data[0]
				dst = data[1]
				addHypernym(src, dst)
			}
			return nil
		end
    end

    def addHypernym(source, destination)
		#check if nym is valid, then add
		if validNymToAdd?(source, destination)
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
		else
			return false #not valid
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
			nodesInBoth = []
    		addedDistances = Hash.new
    		addedDistances.default = -1
    		distancesFromId1.each do |node, distance|
    			nodesIn1.push(node)
    		end
    		distancesFromId2.each do |node, distance|
    			if nodesIn1.include? node
					nodesInBoth.push(node)
    				addedDistances[node] = distance
    			end
    		end
    		distancesFromId1.each do |node, distance|
    			if nodesInBoth.include? node
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

	#HELPER parses each line using our pattern
	def parse(line) #String -> Array OR Nil
		matchedLine = @@pattern.match(line)
		if matchedLine.is_a? MatchData
			src = matchedLine[1].to_i
			dst = matchedLine[2].to_i
			return [src,dst]
		end
		return nil #Line is invalid format
	end

	#HELPER checks for set validity
	def validNymToAdd?(src, dst) #(Integer, Integer) -> Boolean
		if src < 0 || dst < 0 || src == dst
			return false #src or dst negative, src is dst
		end
		return true #Valid
	end

	#HELPER performs load, minus altering data
	def testLoad(hypernyms_file) #String -> Array
		fileLines = File.readlines(hypernyms_file)
		parsedLines = fileLines.map {|line|
			parse(line)
		}
		invalidLines = parsedLines.each_with_index.map {|data, index|
			if data == nil
				index + 1
			else
				src = data[0]
				dst = data[1]
				if !validNymToAdd?(src, dst)
					index + 1
				else
					nil
				end
			end
		}.compact
		if !invalidLines.empty?
			return invalidLines
		end
		return parsedLines
	end
end

class CommandParser
	@@loadCmd ||= /^\s*load\s+(.*)\s*$/
	@@loadArgs ||= /^([\w||\/|\-|\.]+)\s+([\w||\/|\-|\.]+)$/
	@@lookupCmd ||= /^\s*lookup\s+(.*)\s*$/
	@@lookupArg ||= /^(\d+)$/
	@@findCmd ||= /^\s*find\s+(.*)\s*$/
	@@findArg ||= /^([\w|\-|\.|\/|\']+)$/
	@@findManyCmd ||= /^\s*findmany\s+(.*)\s*$/
	@@findManyArg ||= /^([,?[\w|\-|\.|\/|\']+]+)$/
	@@lcaCmd ||= /^\s*lca\s+(.*)\s*$/
	@@lcaArgs ||= /^(\d+)\s+(\d+)$/

    def initialize
        @synsets = Synsets.new
        @hypernyms = Hypernyms.new
    end

    def parse(command)
		#Process a load?
		tryLoad = tryMatch(command, @@loadCmd, @@loadArgs)
    	if tryLoad == true
			return error(:load)
		elsif tryLoad.is_a? Array
    		synFile = tryLoad[1]
    		hypFile = tryLoad[2]
    		return processLoad(synFile, hypFile)
    	end

		#A lookup?
		tryLookup = tryMatch(command, @@lookupCmd, @@lookupArg)
		if tryLookup == true
			return error(:lookup)
		elsif tryLookup.is_a? Array
			id = tryLookup[1].to_i
			return processLookup(id)
		end

		#A find (String)?
		tryFind = tryMatch(command, @@findCmd, @@findArg)
    	if tryFind == true
			return error(:find)
		elsif tryFind.is_a? Array
			noun = tryFind[1]
			return processFind(noun)
		end

		#A findmany (Array)?
		tryFindMany = tryMatch(command, @@findManyCmd, @@findManyArg)
    	if tryFindMany == true
			return error(:find)
		elsif tryFindMany.is_a? Array
			nouns = tryFindMany[1].split(',')
			return processFindMany(nouns)
		end

		#A lca?
		tryLca = tryMatch(command, @@lcaCmd, @@lcaArgs)
    	if tryLca == true
			return error(:find)
		elsif tryLca.is_a? Array
			id1 = tryLca[1].to_i
			id2 = tryLca[2].to_i
			return processLca(id1, id2)
		end
		#Everything else is invalid
		return invalidCommand
    end

	#HELPER Matches command then tries to match args
	def tryMatch(command, cmdPattern, argsPattern)
		cmdMatch = cmdPattern.match(command)
		if cmdMatch.is_a? MatchData
			args = cmdMatch[1]
			argsMatch = argsPattern.match(args)
			if argsMatch.is_a? MatchData
				return argsMatch.to_a
			end
			return true
		end
		return false
	end

	#HELPER returns command and error as result
	def error(commandName)
		res = Hash.new
		res[:recognized_command] = commandName
    	res[:result] = :error
		return res
	end

	#HELPER returns command and result
	def cmdSuccess(commandName, res)
		res = Hash.new
		res[:recognized_command] = commandName
    	res[:result] = res
		return res
	end

	#HELPER returns invalid command
	def invalidCommand
		res = Hash.new		
    	res[:recognized_command] = :invalid
    	return res
	end
	
	#HELPER checks conditions for load, THEN if no errors adds data
	def processLoad(synsetFile, hypernymFile)
		valid = true
		synTestLoadRes = @synsets.testLoad(synsetFile)
		if synTestLoadRes.empty? || !(synTestLoadRes[0].is_a? Integer)
			#success so far
			hypTestLoadRes = @hypernyms.testLoad(hypernymFile)
			if hypTestLoadRes.empty? || !(hypTestLoadRes[0].is_a? Integer)
				#success so far
				#check that hypernym edges all have corresponding synset ids
				synIds = synTestLoadRes.map {|data|
					id = data[0]
					id
				}
				hypTestLoadRes.each {|data|
					src = data[0]
					dst = data[1]
					if !(synIds.include? src) || !(synIds.include? dst)
						#hypernym vertex not found in synset
						valid = false
					end
					if valid == true
						#all conditions met, add the data and return success
						sn = @synsets.load(synsetFile)
						synLoad = (sn == nil)
						#TODO Error in synLoad??
						hp = @hypernyms.load(hypernymFile)
						hypLoad = (hp == nil)
						if (synLoad == false) || (hypLoad == false)
							valid = false
						end
					end
				}
			else
				valid = false
			end
		else
			valid = false
		end
		return cmdSuccess(:load, valid)
	end

	#HELPER performs lookup
	def processLookup(id)
		if id < 0
			return error(:lookup)
		else
			return success(:lookup, @synsets.lookup(id))
		end
	end

	#HELPER performs findSynset on String
	def processFind(noun)
		res = Hash.new
		res[:recognized_command] = :find
		res[:result] = @synsets.findSynsets(noun)
		return res
	end

	#HELPER performs findSynset on Array
	def processFindMany(nouns)
		res = Hash.new
		res[:recognized_command] = :findmany
		res[:result] = @synsets.findSynsets(nouns)
		return res
	end

	#HELPER performs lca
	def processLca(id1, id2)
		res = Hash.new
		res[:recognized_command] = :lca
		res[:result] = @hypernyms.lca(id1, id2)
		return res
	end
end

