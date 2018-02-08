require_relative "graph.rb"

#NOTE: We may assume correct arg types
#However, it's still a good habit to check    	
class Synsets
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
    		success_lines = Hash.new
    		error_lines = []
    		index = 1
    		file_lines.each { |line|
    			pattern = /^id: (\d+) synset: ((\w+[,]?)+)$/
    			if pattern.match? line
    				res = pattern.match(line)
    				id = res[1].to_i
    				if lookup(id).empty?
    					if !success_lines[id].is_a? Array
    						synset = res[2].split(',')
    						success_lines[id] = synset
    					else
    						#A previous line includes this ID, line invalid
    						error_lines.push(index)
    					end
    				else
    					#Synset already contains this ID, line invalid
    					error_lines.push(index)
    				end
    			else
    				#Failed to match on pattern, line invalid
    				error_lines.push(index)
    			end
    			index = index + 1
    		}
    		#Gone through all lines, check for invalid lines
    	end
    	puts success_lines.size
    	puts success_lines
    	if error_lines.empty?
    		success_lines.keys.each do |id|
    			if !addSet(id, success_lines[id])
    				raise Exception, "Synsets: load: id: #{id} exists already!"
    			end
    		end
    		return nil #Everything checked out and was added
    	else
    		return error_lines #These lines didn't check out, no changes
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
    		#puts "Is an Array!"
    		res = Hash.new
    		res.default = []
    		to_find.each { |word|
    			puts word
    			id_arr = []
    			@synsets.keys.each do |synset_id|
    				#puts "Key #{synset_id}"
    				nouns = @synsets[synset_id]
    				#puts "Val #{@synsets[synset_id]}"
    				if nouns.include? word
    					#puts "Noun found: #{res[word]}"
    					id_arr.push(synset_id)
    				end
    			end
    			res[word] = id_arr
    		}
    		puts res
    		return res
    		#return hash with noun as key -> id as value
    	elsif to_find.is_a? String
    		res = []
    		@synsets.select { |synset_id, nouns|
    			if nouns.include? to_find
    				res.push(synset_id)
    			end
    		}
    		return res
    		#return array of 0 or more synset_ids containing this noun
    	else
    		return nil #to_find not array or string, return nil
    	end
    end
    
    #p_v = "./inputs/public_synsets_valid"
    #p_i = "./inputs/public_synsets_invalid"
    #s = Synsets.new
    #puts "\" #{s.load(p_v)} \""
    #puts "\" #{s.load(p_i)} \""
    #s.addSet(100, ["a","b","c"])
    #puts "Result: #{s.findSynsets(["a", "b"])}"
end

class Hypernyms
    def initialize
    end

    def load(hypernyms_file)
        raise Exception, "Not implemented"
    end

    def addHypernym(source, destination)
        raise Exception, "Not implemented"
    end

    def lca(id1, id2)
        raise Exception, "Not implemented"
    end
end

class CommandParser
    def initialize
        @synsets = Synsets.new
        @hypernyms = Hypernyms.new
    end

    def parse(command)
        raise Exception, "Not implemented"
    end
end
