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
